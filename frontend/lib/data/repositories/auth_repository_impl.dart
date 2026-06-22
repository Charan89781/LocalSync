import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  // Only used on Android/iOS — not needed on web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '852345152269-b466ovincdfem50p9ib9poeb2ckr63mo.apps.googleusercontent.com',
  );

  @override
  Stream<UserEntity?> get authStateChanges {
    StreamController<UserEntity?>? controller;
    StreamSubscription<UserEntity?>? firestoreSubscription;
    StreamSubscription<User?>? authSubscription;

    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen((user) {
          firestoreSubscription?.cancel();
          if (user == null) {
            controller?.add(null);
          } else {
            firestoreSubscription = _db
                .collection('users')
                .doc(user.uid)
                .snapshots()
                .map((doc) {
              if (doc.exists && doc.data() != null) {
                return UserEntity.fromMap(doc.data()!, doc.id);
              }
              return UserEntity(
                id: user.uid,
                email: user.email ?? '',
                name: user.displayName,
                profileImageUrl: user.photoURL,
                isVerified: user.emailVerified,
              );
            }).listen((userEntity) {
              controller?.add(userEntity);
            }, onError: (err) {
              controller?.addError(err);
            });
          }
        }, onError: (err) {
          controller?.addError(err);
        });
      },
      onCancel: () {
        firestoreSubscription?.cancel();
        authSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (credential.user == null) return null;

    final docRef = _db.collection('users').doc(credential.user!.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      final updatedDoc = await docRef.get();
      return UserEntity.fromMap(updatedDoc.data()!, updatedDoc.id);
    }

    final newUser = UserEntity(
      id: credential.user!.uid,
      email: credential.user!.email!,
      name: credential.user!.displayName ?? email.split('@').first,
      isVerified: credential.user!.emailVerified,
    );
    await docRef.set(newUser.toMap()..addAll({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }));
    return newUser;
  }

  @override
  Future<UserEntity?> signUpWithEmail(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (credential.user == null) return null;

    await credential.user?.updateDisplayName(name);

    final newUser =
        UserEntity(id: credential.user!.uid, email: email, name: name);

    await _db
        .collection('users')
        .doc(credential.user!.uid)
        .set(newUser.toMap()..addAll({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        }));

    return newUser;
  }

  @override
  Future<void> updateProfile(UserEntity user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── Web: use Firebase popup (google_sign_in doesn't work on web) ──
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        final userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          final docRef = _db.collection('users').doc(userCredential.user!.uid);
          final doc = await docRef.get();
          if (!doc.exists) {
            final newUser = UserEntity(
              id: userCredential.user!.uid,
              email: userCredential.user!.email ?? '',
              name: userCredential.user!.displayName,
              profileImageUrl: userCredential.user!.photoURL,
            );
            await docRef.set(newUser.toMap()..addAll({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            }));
          } else {
            await docRef.update({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        // ── Android / iOS: use google_sign_in package ──
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          final docRef = _db.collection('users').doc(userCredential.user!.uid);
          final doc = await docRef.get();
          if (!doc.exists) {
            final newUser = UserEntity(
              id: userCredential.user!.uid,
              email: userCredential.user!.email ?? '',
              name: userCredential.user!.displayName,
              profileImageUrl: userCredential.user!.photoURL,
            );
            await docRef.set(newUser.toMap()..addAll({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            }));
          } else {
            await docRef.update({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Safe fallback if document doesn't exist or permissions fail
        debugPrint('Signout status update error: $e');
      }
    }
    try {
      if (!kIsWeb) {
        final isGoogleSignedIn = await _googleSignIn.isSignedIn().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        );
        if (isGoogleSignedIn) {
          await _googleSignIn.signOut().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => null,
          );
        }
      }
    } catch (e) {
      debugPrint('Google SignOut error: $e');
    }
    await _auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async =>
      await _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {},
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Future<void> verifyOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    await _auth.signInWithCredential(credential);
  }
}

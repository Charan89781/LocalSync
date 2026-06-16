import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<UserEntity?> signUpWithEmail(
      String email, String password, String name);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> verifyOTP(String verificationId, String smsCode);
  Future<void> sendOTP(String phoneNumber);
  Future<void> updateProfile(UserEntity user);
}

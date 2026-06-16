// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsync/main.dart';
import 'package:localsync/presentation/providers/auth_provider.dart';
import 'package:localsync/presentation/providers/theme_provider.dart';
import 'package:localsync/domain/repositories/auth_repository.dart';
import 'package:localsync/domain/entities/user_entity.dart';
import 'package:localsync/data/repositories/theme_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(null);

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async => null;

  @override
  Future<UserEntity?> signUpWithEmail(
      String email, String password, String name) async => null;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> verifyOTP(String verificationId, String smsCode) async {}

  @override
  Future<void> sendOTP(String phoneNumber) async {}

  @override
  Future<void> updateProfile(UserEntity user) async {}
}

class MockThemeRepository implements ThemeRepository {
  @override
  Future<bool> isDarkMode() async => false;

  @override
  Future<void> setDarkMode(bool isDark) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          themeRepositoryProvider.overrideWithValue(MockThemeRepository()),
        ],
        child: const LocalSyncApp(),
      ),
    );

    // Verify that the app starts successfully without crashing
    expect(find.byType(MaterialApp), findsOneWidget);

    // Dispose the widget tree to stop the repeating animation ticker
    await tester.pumpWidget(Container());

    // Advance the mock clock to let the splash delay timer complete
    await tester.pump(const Duration(seconds: 5));
  });
}

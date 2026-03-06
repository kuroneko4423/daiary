import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_photographer/features/auth/presentation/providers/auth_provider.dart';
import 'package:ai_photographer/features/auth/domain/entities/user.dart';
import 'package:ai_photographer/features/auth/domain/repositories/auth_repository.dart';

/// A fake AuthRepository for testing that does not depend on Supabase.
class FakeAuthRepository implements AuthRepository {
  bool signInCalled = false;
  bool signUpCalled = false;
  bool signOutCalled = false;
  bool resetPasswordCalled = false;
  bool shouldThrow = false;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    signInCalled = true;
    if (shouldThrow) throw Exception('sign in error');
    return AppUser(id: 'fake-id', email: email);
  }

  @override
  Future<AppUser> signUp({required String email, required String password, String? username}) async {
    signUpCalled = true;
    if (shouldThrow) throw Exception('sign up error');
    return AppUser(id: 'fake-id', email: email, username: username);
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> resetPassword(String email) async {
    resetPasswordCalled = true;
    if (shouldThrow) throw Exception('reset password error');
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (shouldThrow) throw Exception('google sign in error');
    return AppUser(id: 'google-id', email: 'google@example.com');
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (shouldThrow) throw Exception('apple sign in error');
    return AppUser(id: 'apple-id', email: 'apple@example.com');
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.empty();

  @override
  AppUser? get currentUser => null;
}

void main() {
  group('AuthNotifier via ProviderContainer', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AsyncData (not loading, no error)', () {
      final state = container.read(authNotifierProvider);
      expect(state, isA<AsyncData<void>>());
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('notifier is an AuthNotifier', () {
      final notifier = container.read(authNotifierProvider.notifier);
      expect(notifier, isA<AuthNotifier>());
    });

    test('signIn returns true on success', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(fakeRepo.signInCalled, isTrue);
      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test('signIn returns false on error', () async {
      fakeRepo.shouldThrow = true;
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isFalse);
      expect(container.read(authNotifierProvider), isA<AsyncError<void>>());
    });

    test('signUp returns true on success', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'testuser',
      );

      expect(result, isTrue);
      expect(fakeRepo.signUpCalled, isTrue);
      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test('signUp returns false on error', () async {
      fakeRepo.shouldThrow = true;
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signUp(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isFalse);
      expect(container.read(authNotifierProvider), isA<AsyncError<void>>());
    });

    test('signOut resets state to AsyncData', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.signOut();

      expect(fakeRepo.signOutCalled, isTrue);
      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test('resetPassword returns true on success', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.resetPassword('test@example.com');

      expect(result, isTrue);
      expect(fakeRepo.resetPasswordCalled, isTrue);
      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test('resetPassword returns false on error', () async {
      fakeRepo.shouldThrow = true;
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.resetPassword('test@example.com');

      expect(result, isFalse);
      expect(container.read(authNotifierProvider), isA<AsyncError<void>>());
    });
  });

  group('AppUser', () {
    test('can be created with required fields', () {
      const user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.username, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.plan, 'free');
      expect(user.planExpiresAt, isNull);
      expect(user.dailyAiCount, 0);
    });

    test('defaults to free plan', () {
      const user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
      );

      expect(user.plan, 'free');
      expect(user.isPremium, isFalse);
    });

    test('isPremium returns true for premium plan with future expiry', () {
      final user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
        plan: 'premium',
        planExpiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(user.isPremium, isTrue);
    });

    test('isPremium returns false for premium plan with past expiry', () {
      final user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
        plan: 'premium',
        planExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(user.isPremium, isFalse);
    });

    test('isPremium returns false for free plan', () {
      const user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
        plan: 'free',
      );

      expect(user.isPremium, isFalse);
    });

    test('can be created with all fields', () {
      final expiresAt = DateTime(2030, 1, 1);
      final user = AppUser(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        avatarUrl: 'https://example.com/avatar.jpg',
        plan: 'premium',
        planExpiresAt: expiresAt,
        dailyAiCount: 5,
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.plan, 'premium');
      expect(user.planExpiresAt, expiresAt);
      expect(user.dailyAiCount, 5);
    });
  });
}

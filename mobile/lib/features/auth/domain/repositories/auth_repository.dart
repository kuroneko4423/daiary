import '../entities/user.dart';

abstract class AuthRepository {
  Future<AppUser> signUp({required String email, required String password, String? username});
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> deleteAccount();
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
}

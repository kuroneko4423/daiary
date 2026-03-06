import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/exceptions/app_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _dataSource.signUp(email, password, username);
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign up failed: no user returned');
      }
      return _mapSupabaseUser(user, username: username);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signIn(email, password);
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign in failed: no user returned');
      }
      final profile = await _dataSource.getUserProfile(user.id);
      return _mapSupabaseUser(user, profile: profile);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _dataSource.signInWithGoogle();
      // OAuth flow is handled via redirect; auth state changes will be
      // picked up by the authStateChanges stream.
      throw const AuthException('Google sign-in initiated via redirect');
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      await _dataSource.signInWithApple();
      throw const AuthException('Apple sign-in initiated via redirect');
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _dataSource.resetPassword(email);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((authState) async {
      final user = authState.session?.user;
      if (user == null) return null;
      final profile = await _dataSource.getUserProfile(user.id);
      return _mapSupabaseUser(user, profile: profile);
    });
  }

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    if (user == null) return null;
    return _mapSupabaseUser(user);
  }

  AppUser _mapSupabaseUser(
    sb.User user, {
    String? username,
    Map<String, dynamic>? profile,
  }) {
    if (profile != null) {
      return UserModel.fromJson({
        'id': user.id,
        'email': user.email ?? '',
        ...profile,
      });
    }
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: username ?? user.userMetadata?['username'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }
}

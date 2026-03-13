import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource() : _client = SupabaseService.client;

  Future<AuthResponse> signUp(String email, String password, String? username) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );

    if (response.user != null && username != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'username': username,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.daiary://login-callback/',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.daiary://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('profiles').delete().eq('id', userId);
      await _client.auth.signOut();
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').upsert({
      'id': userId,
      ...data,
    });
  }

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

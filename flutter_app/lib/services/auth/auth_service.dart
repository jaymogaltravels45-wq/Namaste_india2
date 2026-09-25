import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages Supabase session lifecycle.
/// After backend verifies MSG91 OTP, call [setSessionFromBackend] with
/// the access_token + refresh_token returned by the backend.
class AuthService {
  static final _sb = Supabase.instance.client;

  // ─── Session ────────────────────────────────────────────────────────────────

  /// Restore a Supabase session from tokens returned by our backend.
  /// supabase_flutter v2 requires BOTH accessToken and refreshToken.
  static Future<void> setSessionFromBackend({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _sb.auth.setSession(accessToken, refreshToken);
  }

  /// Current logged-in user, or null.
  static User? get currentUser => _sb.auth.currentUser;

  static bool get isLoggedIn => _sb.auth.currentUser != null;

  static String? get userId => _sb.auth.currentUser?.id;

  static String? get phone =>
      _sb.auth.currentUser?.phone ??
      _sb.auth.currentUser?.userMetadata?['phone'] as String?;

  static String? get role =>
      _sb.auth.currentUser?.userMetadata?['role'] as String?;

  // ─── Profile ─────────────────────────────────────────────────────────────────

  /// Fetch current user's profile from public.profiles table.
  static Future<Map<String, dynamic>?> getProfile() async {
    final u = _sb.auth.currentUser;
    if (u == null) return null;
    final res = await _sb.from('profiles').select().eq('id', u.id).maybeSingle();
    return res;
  }

  /// Upsert profile data (name, avatar_url, etc.).
  static Future<void> upsertProfile(Map<String, dynamic> data) async {
    final u = _sb.auth.currentUser;
    if (u == null) return;
    await _sb.from('profiles').upsert({'id': u.id, ...data});
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────────

  static Future<void> signOut() => _sb.auth.signOut();
}

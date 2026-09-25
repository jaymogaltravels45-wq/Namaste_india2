// ─── SECURITY NOTE ───────────────────────────────────────────────────────────
// 2026-09-25 — HARDENING (user-ordered, overrides README "DO NOT MODIFY"):
//   • MSG91 widgetId/authToken REMOVED from this file. They were never used by
//     the Flutter app (Msg91Service only calls our own backend) and keeping
//     secrets in client code means anyone can decompile the APK and steal them.
//     MSG91 keys now live ONLY in backend/.env (server-side).
//   • Supabase URL + anon key are injected at build time via --dart-define:
//       flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
//     If they are missing, main.dart shows a setup error screen (no crash).
// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  static const appName     = "Namaste India";
  static const packageName = "com.namasteindia.app";

  // ─── Supabase (build-time injected; empty default = not configured) ────────
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True when Supabase credentials were provided via --dart-define.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ─── Backend API ───────────────────────────────────────────────────────────
  // Render backend (live): https://namaste-india-backend.onrender.com
  static const apiBaseUrl = "https://namaste-india-backend.onrender.com/api";

  // ─── Mock OTP (sirf testing) ───────────────────────────────────────────────
  // Backend me MOCK_OTP=true hai to har bar RANDOM OTP banta hai jo response
  // me mockOtp field me aata hai (koi fixed 123456 bypass nahi hai).
  // App send-otp ke baad use orange snackbar me dikhati hai.
  // WARNING: production me hamesha real SMS wala backend use karo.
}

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
  // TODO: Jab backend deploy karo (Render/Railway) to ye URL update karo.
  // Real phone pe test karne ke liye: https://your-backend.onrender.com/api
  static const apiBaseUrl = "https://your-backend.onrender.com/api";

  // ─── Mock OTP (sirf testing) ───────────────────────────────────────────────
  // Backend mein MOCK_OTP=true karo, toh har phone pe OTP = 123456 kaam karega.
  // WARNING: kabhi production build mein mock OTP backend ke saath use mat karo.
  static const mockOtpCode = "123456";
}

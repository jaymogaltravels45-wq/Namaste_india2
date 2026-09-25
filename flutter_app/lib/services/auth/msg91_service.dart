import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

/// Calls the backend which proxies MSG91 OTP requests.
/// Never call MSG91 directly from Flutter — keeps authkey secure on server.
class Msg91Service {
  static String formatPhone(String p) =>
      p.startsWith('+91') ? p : '+91${p.replaceAll(' ', '')}';

  /// Returns true if OTP was sent successfully.
  static Future<bool> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': formatPhone(phone)}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Verifies OTP and returns the full response map on success, null on failure.
  /// Response contains: { success, session: { access_token, refresh_token }, user, is_new_user }
  static Future<Map<String, dynamic>?> verifyOtp(
    String phone,
    String otp,
    String role,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': formatPhone(phone),
          'otp': otp,
          'role': role,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return body;
      return null;
    } catch (_) {
      return null;
    }
  }
}

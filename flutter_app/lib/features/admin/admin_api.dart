import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';

/// Thin HTTP wrapper for the Namaste India backend.
/// Attaches the Supabase JWT as a Bearer token on every request,
/// which the backend validates via authMiddleware (+ adminOnly).
class AdminApi {
  static Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? {} : jsonDecode(res.body);
    } catch (_) {
      body = {};
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    var msg = 'Request failed (${res.statusCode})';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    }
    throw Exception(msg);
  }

  /// Defensive cast for JSON lists of objects.
  static List<Map<String, dynamic>> asMapList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Defensive cast for JSON objects.
  static Map<String, dynamic> asMap(dynamic v) {
    if (v is! Map) return {};
    return Map<String, dynamic>.from(v);
  }
}

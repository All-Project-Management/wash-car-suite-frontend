import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AuthApi {
  AuthApi({required this.baseUrl});

  final String baseUrl;

  // JHipster defaults
  static const String loginPath = '/api/authenticate';
  static const String accountPath = '/api/account';
  static const String resetInitPath = '/api/account/reset-password/init';
  static const String resetFinishPath = '/api/account/reset-password/finish';

  String _normalizeBaseUrl(String url) {
    final u = url.trim();
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  Uri _uri(String path) => Uri.parse('${_normalizeBaseUrl(baseUrl)}$path');

  Map<String, dynamic> _safeJson(String body) {
    final text = body.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected JSON object');
  }

  Future<String> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final res = await http
          .post(
        _uri(loginPath),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
          'rememberMe': rememberMe,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final json = _safeJson(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception((json['message'] ?? json['error'] ?? 'Login failed').toString());
      }

      final jwt = (json['id_token'] ?? json['accessToken'] ?? json['token'] ?? '').toString();
      if (jwt.isEmpty) throw Exception('Server did not return JWT (id_token).');
      return jwt;
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response.');
    }
  }

  Future<Map<String, dynamic>> getAccount({required String token}) async {
    try {
      final res = await http
          .get(
        _uri(accountPath),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Unauthorized');
      }

      return _safeJson(res.body);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response.');
    }
  }

  /// POST /api/account/reset-password/init
  /// Content-Type: text/plain
  Future<void> resetInit({required String email}) async {
    try {
      final res = await http
          .post(
        _uri(resetInitPath),
        headers: const {
          'Content-Type': 'text/plain',
          'Accept': 'application/json',
        },
        body: email.trim(),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final json = _safeJson(res.body);
        throw Exception((json['message'] ?? json['error'] ?? 'Reset request failed').toString());
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response.');
    }
  }

  /// POST /api/account/reset-password/finish
  /// JSON: {"key":"...","newPassword":"..."}
  Future<void> resetFinish({
    required String key,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
        _uri(resetFinishPath),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'key': key.trim(), 'newPassword': newPassword}),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final json = _safeJson(res.body);
        throw Exception((json['message'] ?? json['error'] ?? 'Reset failed').toString());
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid server response.');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: await _headers());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> put(String url, [Map<String, dynamic>? body]) async {
    try {
      final response = await http.put(Uri.parse(url), headers: await _headers(), body: body != null ? jsonEncode(body) : null);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String url) async {
    try {
      final response = await http.delete(Uri.parse(url), headers: await _headers());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      _storage.delete(key: 'jwt_token');
      throw Exception('Unauthorized');
    }
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Invalid JSON response');
    }
  }
}

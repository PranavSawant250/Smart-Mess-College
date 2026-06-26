import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    return await ApiService.post(ApiConfig.login, {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> signupStudent(
    String name,
    String email,
    String phone,
    String password,
    String rollNumber,
    String prn,
    String branch,
    String passoutYear,
    String hostelName,
  ) async {
    return await ApiService.post(ApiConfig.signupStudent, {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'rollNumber': rollNumber,
      'prn': prn,
      'branch': branch,
      'passoutYear': passoutYear,
      'hostelName': hostelName,
    });
  }

  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String phone,
    String rollNumber,
    String branch,
    String passoutYear,
    String hostelName,
  ) async {
    return await ApiService.put(ApiConfig.updateProfile, {
      'name': name,
      'phone': phone,
      'rollNumber': rollNumber,
      'branch': branch,
      'passoutYear': passoutYear,
      'hostelName': hostelName,
    });
  }

  static Future<Map<String, dynamic>> signupAdmin(String name, String email, String phone, String password, String messName, String messId, int monthlyFee, String address, String description) async {
    return await ApiService.post(ApiConfig.signupAdmin, {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'messName': messName,
      'messId': messId,
      'monthlyFee': monthlyFee,
      'address': address,
      'description': description,
    });
  }

  static Future<Map<String, dynamic>> biometricLogin(String userId) async {
    return await ApiService.post(ApiConfig.biometricLogin, {
      'userId': userId,
    });
  }

  static Future<Map<String, dynamic>> getMe() async {
    return await ApiService.get(ApiConfig.me);
  }

  static Future<void> logout() async {
    // No backend logout endpoint needed for JWT, just clear local storage
    await _storage.deleteAll();
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> saveUserId(String id) async {
    await _storage.write(key: 'user_id', value: id);
  }

  static Future<String?> getSavedUserId() async {
    return await _storage.read(key: 'user_id');
  }
}

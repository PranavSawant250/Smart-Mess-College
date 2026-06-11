import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await AuthService.login(email, password, role);
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['user']);
        await AuthService.saveToken(response['token']);
        await AuthService.saveUserId(_currentUser!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> biometricLogin(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await AuthService.biometricLogin(userId);
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['user']);
        await AuthService.saveToken(response['token']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Biometric login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signupStudent(String name, String email, String phone, String password, String rollNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await AuthService.signupStudent(name, email, phone, password, rollNumber);
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['user']);
        await AuthService.saveToken(response['token']);
        await AuthService.saveUserId(_currentUser!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Signup error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signupAdmin(String name, String email, String phone, String password, String messName, String messId, int monthlyFee, String address, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await AuthService.signupAdmin(name, email, phone, password, messName, messId, monthlyFee, address, description);
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['user']);
        await AuthService.saveToken(response['token']);
        await AuthService.saveUserId(_currentUser!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Signup admin error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadUser() async {
    try {
      final response = await AuthService.getMe();
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['data']['user']);
        notifyListeners();
      }
    } catch (e) {
      print('Load user error: $e');
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }
}

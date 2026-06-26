import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? lastError;

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id;
          
          if (userData['role'] != role) {
            print('Role mismatch');
            await _auth.signOut();
            _isLoading = false;
            notifyListeners();
            return false;
          }

          _currentUser = User.fromJson(userData);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', _currentUser!.id);
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Login error: $e');
      lastError = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> biometricLogin(String userId) async {
    // Biometric login will need a custom implementation since Firebase Auth doesn't have a direct biometric trigger, 
    // it relies on saving the email/password securely on the device. For now we will mock this or skip.
    return false;
  }

  Future<bool> signupStudent(
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
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final userData = {
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'student',
          'rollNumber': rollNumber,
          'prn': prn,
          'branch': branch,
          'passoutYear': passoutYear,
          'hostelName': hostelName,
          'messId': '',
          'biometricEnabled': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(uid).set(userData);

        userData['id'] = uid;
        userData['password'] = password; // Do not store password in plain text in Firestore, this is just for the local model mapping
        _currentUser = User.fromJson(userData);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', uid);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Signup error: $e');
      lastError = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String rollNumber,
    required String branch,
    required String passoutYear,
    required String hostelName,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'name': name,
        'phone': phone,
        'rollNumber': rollNumber,
        'branch': branch,
        'passoutYear': passoutYear,
        'hostelName': hostelName,
      });
      
      await loadUser(); // Reload to get fresh data
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Update profile error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signupAdmin(String name, String email, String phone, String password, String messName, String messId, int monthlyFee, String address, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        
        final messRef = messId.isNotEmpty ? _firestore.collection('messes').doc(messId) : _firestore.collection('messes').doc();
        
        await messRef.set({
          'messName': messName,
          'adminId': uid,
          'monthlyFee': monthlyFee,
          'address': address,
          'description': description,
          'upiId': '',
          'qrCodeImage': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final userData = {
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'admin',
          'messId': messRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(uid).set(userData);

        userData['id'] = uid;
        userData['password'] = password;
        _currentUser = User.fromJson(userData);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', uid);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Signup admin error: $e');
      lastError = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id;
          _currentUser = User.fromJson(userData);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Load user error: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
  }
}

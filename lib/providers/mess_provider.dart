import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MessProvider with ChangeNotifier {
  Mess? _myMess;
  List<Mess> _searchResults = [];
  List<JoinRequest> _myRequests = [];
  List<JoinRequest> _adminRequests = [];
  List<User> _students = [];
  bool _isLoading = false;
  String? lastError;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  Mess? get myMess => _myMess;
  List<Mess> get searchResults => _searchResults;
  List<JoinRequest> get myRequests => _myRequests;
  List<JoinRequest> get adminRequests => _adminRequests;
  List<User> get students => _students;
  bool get isLoading => _isLoading;

  // --------------------------------------------------
  // STUDENT FUNCTIONS (MIGRATED TO FIREBASE)
  // --------------------------------------------------

  Future<void> searchMess(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('messes')
        .where('messName', isGreaterThanOrEqualTo: query)
        .where('messName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
        
      _searchResults = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Mess.fromJson(data);
      }).toList();
    } catch (e) {
      print('Search mess error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendJoinRequest(String messId, String paymentMode, String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final requestRef = _firestore.collection('join_requests').doc();
      await requestRef.set({
        'studentId': user.uid,
        'messId': messId,
        'status': 'pending',
        'paymentMode': paymentMode,
        'transactionId': transactionId,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      await fetchMyRequests();
      return true;
    } catch (e) {
      print('Send join request error: $e');
    }
    return false;
  }

  Future<void> fetchMyRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('join_requests')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('requestedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        
        // Handle Firestore Timestamp to String for the model
        if (data['requestedAt'] is Timestamp) {
          data['requestedAt'] = (data['requestedAt'] as Timestamp).toDate().toIso8601String();
        }

        data['studentName'] = 'You';
        data['studentEmail'] = user.email;
        data['studentPhone'] = '';
        _myRequests = [JoinRequest.fromJson(data)];
      } else {
        _myRequests = [];
      }
    } catch (e) {
      print('Fetch my requests error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyMess() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()!['messId'] != null && userDoc.data()!['messId'].toString().isNotEmpty) {
        final messId = userDoc.data()!['messId'];
        final messDoc = await _firestore.collection('messes').doc(messId).get();
        if (messDoc.exists) {
          final data = messDoc.data()!;
          data['id'] = messDoc.id;
          _myMess = Mess.fromJson(data);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Fetch my mess error: $e');
    }
  }

  Future<Mess?> getMessById(String id) async {
    lastError = null;
    try {
      final doc = await _firestore.collection('messes').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Mess.fromJson(data);
      } else {
        lastError = 'Document does not exist in Firestore collection.';
      }
    } catch (e) {
      print('Get mess by ID error: $e');
      lastError = e.toString();
    }
    return null;
  }

  Future<bool> submitTransaction({
    required String messId,
    required double amount,
    required String paymentMode,
    required String transactionId,
    required String paymentScreenshot,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('transactions').add({
        'studentId': user.uid,
        'messId': messId,
        'amount': amount,
        'paymentMode': paymentMode,
        'paymentStatus': 'pending',
        'paymentDate': FieldValue.serverTimestamp(),
        'paymentScreenshot': paymentScreenshot,
        'transactionId': transactionId,
      });
      return true;
    } catch (e) {
      print('Submit transaction error: $e');
    }
    return false;
  }

  // --------------------------------------------------
  // ADMIN FUNCTIONS (TO BE MIGRATED TOMORROW)
  // --------------------------------------------------

  Future<void> fetchAdminRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        final snapshot = await _firestore.collection('join_requests')
            .where('messId', isEqualTo: messId)
            .where('status', isEqualTo: 'pending')
            .get();

        List<JoinRequest> requests = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          if (data['requestedAt'] is Timestamp) {
            data['requestedAt'] = (data['requestedAt'] as Timestamp).toDate().toIso8601String();
          }

          // Fetch student details
          final studentDoc = await _firestore.collection('users').doc(data['studentId']).get();
          if (studentDoc.exists) {
            final sData = studentDoc.data()!;
            data['studentName'] = sData['name'] ?? '';
            data['studentEmail'] = sData['email'] ?? '';
            data['studentPhone'] = sData['phone'] ?? '';
          }
          requests.add(JoinRequest.fromJson(data));
        }
        _adminRequests = requests;
      }
    } catch (e) {
      print('Fetch admin requests error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveRequest(String id) async {
    try {
      final requestDoc = await _firestore.collection('join_requests').doc(id).get();
      if (!requestDoc.exists) return false;

      final data = requestDoc.data()!;
      final studentId = data['studentId'];
      final messId = data['messId'];

      await _firestore.collection('join_requests').doc(id).update({'status': 'approved'});
      await _firestore.collection('users').doc(studentId).update({'messId': messId});
      
      await fetchAdminRequests();
      await fetchStudents();
      return true;
    } catch (e) {
      print('Approve request error: $e');
    }
    return false;
  }

  Future<bool> rejectRequest(String id) async {
    try {
      await _firestore.collection('join_requests').doc(id).update({'status': 'rejected'});
      await fetchAdminRequests();
      return true;
    } catch (e) {
      print('Reject request error: $e');
    }
    return false;
  }

  Future<void> fetchStudents({String? search, String? branch, String? hostel}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        var query = _firestore.collection('users')
            .where('messId', isEqualTo: messId)
            .where('role', isEqualTo: 'student');

        final snapshot = await query.get();
        List<User> filteredStudents = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          final student = User.fromJson(data);
          
          bool matches = true;
          if (search != null && search.isNotEmpty) {
            matches = student.name.toLowerCase().contains(search.toLowerCase()) || 
                      student.prn.toLowerCase().contains(search.toLowerCase());
          }
          if (matches && branch != null && branch.isNotEmpty && student.branch != branch) matches = false;
          if (matches && hostel != null && hostel.isNotEmpty && student.hostelName != hostel) matches = false;
          
          if (matches) filteredStudents.add(student);
        }
        
        _students = filteredStudents;
      }
    } catch (e) {
      print('Fetch students error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeStudent(String id) async {
    try {
      await _firestore.collection('users').doc(id).update({'messId': ''});
      await fetchStudents();
      return true;
    } catch (e) {
      print('Remove student error: $e');
    }
    return false;
  }

  Future<bool> updateMessDetails({
    required String address,
    required String description,
    required int monthlyFee,
    required String upiId,
    required String qrCodeImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        await _firestore.collection('messes').doc(messId).update({
          'address': address,
          'description': description,
          'monthlyFee': monthlyFee,
          'upiId': upiId,
          'qrCodeImage': qrCodeImage,
        });
        
        await fetchMyMess();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Update mess details error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

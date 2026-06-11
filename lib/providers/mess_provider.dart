import 'package:flutter/material.dart';
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

  Mess? get myMess => _myMess;
  List<Mess> get searchResults => _searchResults;
  List<JoinRequest> get myRequests => _myRequests;
  List<JoinRequest> get adminRequests => _adminRequests;
  List<User> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> searchMess(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('${ApiConfig.messSearch}?name=$query');
      if (response['success'] == true) {
        _searchResults = (response['data'] as List).map((m) => Mess.fromJson(m)).toList();
      }
    } catch (e) {
      print('Search mess error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendJoinRequest(String messId) async {
    try {
      final response = await ApiService.post(ApiConfig.joinRequest, {'messId': messId});
      if (response['success'] == true) {
        await fetchMyRequests();
        return true;
      }
    } catch (e) {
      print('Send join request error: $e');
    }
    return false;
  }

  Future<void> fetchMyRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.myRequest);
      if (response['success'] == true && response['request'] != null) {
        _myRequests = [JoinRequest.fromJson(response['request'])];
      } else {
        _myRequests = [];
      }
    } catch (e) {
      print('Fetch my requests error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdminRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.messRequests);
      if (response['success'] == true) {
        _adminRequests = (response['requests'] as List).map((r) => JoinRequest.fromJson(r['request'])).toList();
      }
    } catch (e) {
      print('Fetch admin requests error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveRequest(String id) async {
    try {
      final response = await ApiService.put(ApiConfig.approveRequest(id));
      if (response['success'] == true) {
        await fetchAdminRequests();
        await fetchStudents();
        return true;
      }
    } catch (e) {
      print('Approve request error: $e');
    }
    return false;
  }

  Future<bool> rejectRequest(String id) async {
    try {
      final response = await ApiService.put(ApiConfig.rejectRequest(id));
      if (response['success'] == true) {
        await fetchAdminRequests();
        return true;
      }
    } catch (e) {
      print('Reject request error: $e');
    }
    return false;
  }

  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.messStudents);
      if (response['success'] == true) {
        _students = (response['students'] as List).map((s) => User.fromJson(s)).toList();
      }
    } catch (e) {
      print('Fetch students error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeStudent(String id) async {
    try {
      final response = await ApiService.delete(ApiConfig.removeStudent(id));
      if (response['success'] == true) {
        await fetchStudents();
        return true;
      }
    } catch (e) {
      print('Remove student error: $e');
    }
    return false;
  }

  Future<void> fetchMyMess() async {
    try {
      final response = await ApiService.get(ApiConfig.myMess);
      if (response['success'] == true) {
        _myMess = Mess.fromJson(response['mess']);
        notifyListeners();
      }
    } catch (e) {
      print('Fetch my mess error: $e');
    }
  }
}

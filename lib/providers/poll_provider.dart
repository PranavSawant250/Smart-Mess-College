import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class PollProvider with ChangeNotifier {
  List<MealPoll> _activePolls = [];
  List<MealPoll> _pollHistory = [];
  List<MealPoll> _adminPolls = [];
  bool _isLoading = false;

  List<MealPoll> get activePolls => _activePolls;
  List<MealPoll> get pollHistory => _pollHistory;
  List<MealPoll> get adminPolls => _adminPolls;
  bool get isLoading => _isLoading;

  Future<void> fetchActivePolls() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.activePolls);
      if (response['success'] == true) {
        _activePolls = (response['polls'] as List).map((p) => MealPoll.fromJson(p)).toList();
      }
    } catch (e) {
      print('Fetch active polls error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPollHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.pollHistory);
      if (response['success'] == true) {
        _pollHistory = (response['polls'] as List).map((p) => MealPoll.fromJson(p)).toList();
      }
    } catch (e) {
      print('Fetch poll history error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdminPolls({String? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String url = ApiConfig.adminPolls;
      if (status != null) url += '?status=$status';
      final response = await ApiService.get(url);
      if (response['success'] == true) {
        _adminPolls = (response['polls'] as List).map((p) => MealPoll.fromJson(p)).toList();
      }
    } catch (e) {
      print('Fetch admin polls error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPoll({
    required String title,
    required String mealTime,
    required List<MealOption> vegOptions,
    required List<MealOption> nonVegOptions,
    required List<MealOption> fastOptions,
    String? closesAt,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.polls, {
        'title': title,
        'mealTime': mealTime,
        'vegOptions': vegOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description}).toList(),
        'nonVegOptions': nonVegOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description}).toList(),
        'fastOptions': fastOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description}).toList(),
        if (closesAt != null) 'closesAt': closesAt,
      });
      if (response['success'] == true) {
        await fetchAdminPolls();
        return true;
      }
    } catch (e) {
      print('Create poll error: $e');
    }
    return false;
  }

  Future<bool> castVote(String pollId, String mealType, String optionId, bool isComing) async {
    try {
      final response = await ApiService.post(ApiConfig.votes, {
        'pollId': pollId,
        'mealType': mealType,
        'optionId': optionId,
        'isComing': isComing,
      });
      if (response['success'] == true) {
        return true;
      }
    } catch (e) {
      print('Cast vote error: $e');
    }
    return false;
  }

  Future<bool> finalizePoll(String pollId) async {
    try {
      final response = await ApiService.put(ApiConfig.finalizePoll(pollId));
      if (response['success'] == true) {
        await fetchAdminPolls();
        return true;
      }
    } catch (e) {
      print('Finalize poll error: $e');
    }
    return false;
  }
}

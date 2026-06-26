import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class PollProvider with ChangeNotifier {
  List<MealPoll> _activePolls = [];
  List<MealPoll> _pollHistory = [];
  List<MealPoll> _adminPolls = [];
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  List<MealPoll> get activePolls => _activePolls;
  List<MealPoll> get pollHistory => _pollHistory;
  List<MealPoll> get adminPolls => _adminPolls;
  bool get isLoading => _isLoading;

  // --------------------------------------------------
  // STUDENT FUNCTIONS (MIGRATED TO FIREBASE)
  // --------------------------------------------------

  Future<void> fetchActivePolls() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        final snapshot = await _firestore.collection('polls')
            .where('messId', isEqualTo: messId)
            .where('isActive', isEqualTo: true)
            .get();

        _activePolls = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to ISO strings for the Model
          if (data['date'] is Timestamp) data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
          if (data['pollStartTime'] is Timestamp) data['pollStartTime'] = (data['pollStartTime'] as Timestamp).toDate().toIso8601String();
          if (data['pollEndTime'] is Timestamp) data['pollEndTime'] = (data['pollEndTime'] as Timestamp).toDate().toIso8601String();
          
          return MealPoll.fromJson(data);
        }).toList();
      }
    } catch (e) {
      print('Fetch active polls error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPollHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        final snapshot = await _firestore.collection('polls')
            .where('messId', isEqualTo: messId)
            .where('isActive', isEqualTo: false)
            .orderBy('date', descending: true)
            .get();

        _pollHistory = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          
          if (data['date'] is Timestamp) data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
          if (data['pollStartTime'] is Timestamp) data['pollStartTime'] = (data['pollStartTime'] as Timestamp).toDate().toIso8601String();
          if (data['pollEndTime'] is Timestamp) data['pollEndTime'] = (data['pollEndTime'] as Timestamp).toDate().toIso8601String();
          
          return MealPoll.fromJson(data);
        }).toList();
      }
    } catch (e) {
      print('Fetch poll history error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> castVote(String pollId, String mealType, List<String> optionIds, bool isComing) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Create the vote document
      await _firestore.collection('votes').doc('${pollId}_${user.uid}').set({
        'pollId': pollId,
        'userId': user.uid,
        'mealType': mealType,
        'optionIds': optionIds,
        'isComing': isComing,
        'votedAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment poll totals using Firestore Transactions
      await _firestore.runTransaction((transaction) async {
        final pollRef = _firestore.collection('polls').doc(pollId);
        final snapshot = await transaction.get(pollRef);
        
        if (!snapshot.exists) throw Exception("Poll does not exist!");
        
        if (!isComing) {
           transaction.update(pollRef, {'totalNotComing': FieldValue.increment(1)});
           return;
        }

        if (mealType == 'veg') transaction.update(pollRef, {'totalVeg': FieldValue.increment(1)});
        if (mealType == 'non-veg') transaction.update(pollRef, {'totalNonVeg': FieldValue.increment(1)});
        if (mealType == 'fast') transaction.update(pollRef, {'totalFast': FieldValue.increment(1)});
      });

      return true;
    } catch (e) {
      print('Cast vote error: $e');
    }
    return false;
  }

  // --------------------------------------------------
  // ADMIN FUNCTIONS (TO BE MIGRATED TOMORROW)
  // --------------------------------------------------

  Future<void> fetchAdminPolls({String? status}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        var query = _firestore.collection('polls').where('messId', isEqualTo: messId);
        
        if (status == 'active') {
          query = query.where('isActive', isEqualTo: true);
        } else if (status == 'history') {
          query = query.where('isActive', isEqualTo: false);
        }
        
        final snapshot = await query.orderBy('date', descending: true).get();

        _adminPolls = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          
          if (data['date'] is Timestamp) data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
          if (data['pollStartTime'] is Timestamp) data['pollStartTime'] = (data['pollStartTime'] as Timestamp).toDate().toIso8601String();
          if (data['pollEndTime'] is Timestamp) data['pollEndTime'] = (data['pollEndTime'] as Timestamp).toDate().toIso8601String();
          
          return MealPoll.fromJson(data);
        }).toList();
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
    DateTime? pollStartTime,
    DateTime? pollEndTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final messId = userDoc.data()?['messId'];

      if (messId != null && messId.toString().isNotEmpty) {
        await _firestore.collection('polls').add({
          'messId': messId,
          'title': title,
          'mealTime': mealTime,
          'date': FieldValue.serverTimestamp(),
          'vegOptions': vegOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description, 'votes': 0}).toList(),
          'nonVegOptions': nonVegOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description, 'votes': 0}).toList(),
          'fastOptions': fastOptions.map((e) => {'id': e.id, 'name': e.name, 'description': e.description, 'votes': 0}).toList(),
          'isActive': true,
          'isFinalized': false,
          'totalVeg': 0,
          'totalNonVeg': 0,
          'totalFast': 0,
          'totalNotComing': 0,
          if (pollStartTime != null) 'pollStartTime': pollStartTime.toIso8601String(),
          if (pollEndTime != null) 'pollEndTime': pollEndTime.toIso8601String(),
        });
        
        await fetchAdminPolls();
        return true;
      }
    } catch (e) {
      print('Create poll error: $e');
    }
    return false;
  }
  
  Future<bool> finalizePoll(String pollId) async {
    try {
      final pollDoc = await _firestore.collection('polls').doc(pollId).get();
      if (!pollDoc.exists) return false;
      final pollData = pollDoc.data()!;

      final vegOptions = pollData['vegOptions'] as List;
      final nonVegOptions = pollData['nonVegOptions'] as List;
      final fastOptions = pollData['fastOptions'] as List;

      String getWinner(List options) {
        if (options.isEmpty) return 'N/A';
        var winner = options[0];
        for (var opt in options) {
          if ((opt['votes'] ?? 0) > (winner['votes'] ?? 0)) winner = opt;
        }
        return winner['name'];
      }

      final vegMenu = getWinner(vegOptions);
      final nonVegMenu = getWinner(nonVegOptions);
      final fastMenu = getWinner(fastOptions);

      await _firestore.collection('kitchen_orders').add({
        'pollId': pollId,
        'messId': pollData['messId'],
        'mealTime': pollData['mealTime'],
        'date': pollData['date'],
        'finalVegMenu': vegMenu,
        'finalNonVegMenu': nonVegMenu,
        'finalFastMenu': fastMenu,
        'vegCount': pollData['totalVeg'],
        'nonVegCount': pollData['totalNonVeg'],
        'fastCount': pollData['totalFast'],
        'sentAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('polls').doc(pollId).update({
        'isActive': false,
        'isFinalized': true,
        'finalizedVeg': vegMenu,
        'finalizedNonVeg': nonVegMenu,
        'finalizedFast': fastMenu,
      });
      await fetchAdminPolls();
      return true;
    } catch (e) {
      print('Finalize poll error: $e');
    }
    return false;
  }
}

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get(ApiConfig.notifications);
      if (response['success'] == true) {
        _notifications = (response['notifications'] as List).map((n) => AppNotification.fromJson(n)).toList();
        _unreadCount = response['unreadCount'] ?? 0;
      }
    } catch (e) {
      print('Fetch notifications error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.put(ApiConfig.readNotif(id));
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = AppNotification(
          id: _notifications[idx].id,
          userId: _notifications[idx].userId,
          type: _notifications[idx].type,
          title: _notifications[idx].title,
          body: _notifications[idx].body,
          isRead: true,
          data: _notifications[idx].data,
          createdAt: _notifications[idx].createdAt,
        );
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.put(ApiConfig.readAllNotifs);
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            type: _notifications[i].type,
            title: _notifications[i].title,
            body: _notifications[i].body,
            isRead: true,
            data: _notifications[i].data,
            createdAt: _notifications[i].createdAt,
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Mark all as read error: $e');
    }
  }
}

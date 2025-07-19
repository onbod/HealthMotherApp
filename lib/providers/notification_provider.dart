import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification.dart' as AppNotification;
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification.Notification> _notifications = [];
  bool _isFirstLaunch = true;
  final String _notificationsKey = 'notifications';
  final String _firstLaunchKey = 'firstLaunch';
  final Uuid _uuid = Uuid();

  List<AppNotification.Notification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
    _checkFirstLaunch();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notificationsJson = prefs.getStringList(
      _notificationsKey,
    );
    if (notificationsJson != null) {
      _notifications = notificationsJson
          .map(
            (jsonString) => AppNotification.Notification.fromMap(
              json.decode(jsonString),
            ),
          )
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsJson = _notifications
        .map((notification) => json.encode(notification.toMap()))
        .toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  Future<void> addNotification(
    AppNotification.Notification notification,
  ) async {
    _notifications.add(notification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final notificationIndex = _notifications.indexWhere((n) => n.id == id);
    if (notificationIndex != -1) {
      _notifications[notificationIndex].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    if (_isFirstLaunch) {
      _sendWelcomeNotification();
      await prefs.setBool(_firstLaunchKey, false);
    }
  }

  void _sendWelcomeNotification() {
    final welcomeNotification = AppNotification.Notification(
      id: _uuid.v4(),
      title: 'Welcome to Healthy Mama!',
      body:
          'Thank you for joining us. We are here to support you on your journey.',
      timestamp: DateTime.now(),
    );
    addNotification(welcomeNotification);
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}

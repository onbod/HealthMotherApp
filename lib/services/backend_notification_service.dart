import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification.dart' as app_notification;
import '../core/config.dart';

class BackendNotificationService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> _getJwt() async {
    return await _secureStorage.read(key: 'jwt');
  }

  Uri _api(String path) => Uri.parse(AppConfig.getApiUrl(path));

  // Get notifications from backend
  Future<List<app_notification.Notification>> getNotifications() async {
    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        return [];
      }

      final response = await http.get(
        _api('/api/notifications'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final map = item as Map<String, dynamic>;
          return app_notification.Notification(
            id: (map['id'] ?? map['notification_id'] ?? '').toString(),
            title: map['title'] ?? 'Notification',
            body: map['message'] ?? map['body'] ?? '',
            timestamp: map['created_at'] != null
                ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
                : map['scheduled_at'] != null
                    ? DateTime.tryParse(map['scheduled_at'].toString()) ?? DateTime.now()
                    : DateTime.now(),
            isRead: map['is_read'] ?? false,
          );
        }).toList();
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be invalid, but don't show error to user
        // Just return empty list silently
        print('Unauthorized access to notifications (token may be invalid)');
        return [];
      } else {
        // Other errors (500, etc.) - log but don't show to user
        print('Error fetching notifications: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread count from backend
  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        throw StateError('Missing JWT token');
      }

      final response = await http.put(
        _api('/api/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'is_read': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw StateError('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark notification as unread
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        throw StateError('Missing JWT token');
      }

      final response = await http.put(
        _api('/api/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'is_read': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw StateError('Failed to mark notification as unread: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as unread: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        throw StateError('Missing JWT token');
      }

      final response = await http.delete(
        _api('/api/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw StateError('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Stream for unread count (polling-based since we don't have WebSockets)
  Stream<int> getUnreadCountStream() async* {
    while (true) {
      try {
        final count = await getUnreadCount();
        yield count;
        // Poll every 30 seconds
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        print('Error in unread count stream: $e');
        yield 0;
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }
}


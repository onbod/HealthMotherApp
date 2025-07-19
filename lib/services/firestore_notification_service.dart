import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart' as app_notification;
import '../providers/user_session_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FirestoreNotificationService {
  static final FirestoreNotificationService _instance =
      FirestoreNotificationService._internal();
  factory FirestoreNotificationService() => _instance;
  FirestoreNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to notifications from Firestore
  Stream<List<app_notification.Notification>> getNotificationsStream(
      BuildContext context) {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_notification.Notification(
          id: doc.id,
          title: data['title'] ?? 'Notification',
          body: data['message'] ?? '',
          timestamp: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : (data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now()),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  // Get notifications as a Future
  Future<List<app_notification.Notification>> getNotifications(
      BuildContext context) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return app_notification.Notification(
          id: doc.id,
          title: data['title'] ?? 'Notification',
          body: data['message'] ?? data['body'] ?? '',
          timestamp: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : (data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now()),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
      print(
          'Fetched  [32m${notifications.length} [0m notifications from Firestore:');
      for (final n in notifications) {
        print('  - ${n.title} (${n.timestamp})');
      }
      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark notification as unread
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': false,
        'readAt': null,
      });
    } catch (e) {
      print('Error marking notification as unread: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(BuildContext context) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      print(
          'DEBUG: Unread notifications in Firestore: ${querySnapshot.docs.length}');
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Stream for unread count
  Stream<int> getUnreadCountStream(BuildContext context) {
    final userSession =
        Provider.of<UserSessionProvider>(context, listen: false);
    final clientNumber = userSession.clientNumber;

    if (clientNumber == null || clientNumber.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: clientNumber)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create a new notification (for testing or admin use)
  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    String type = 'general',
    String priority = 'normal',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': type,
        'priority': priority,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}

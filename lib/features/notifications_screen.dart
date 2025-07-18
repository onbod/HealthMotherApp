import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../providers/user_session_provider.dart';
import '../models/notification.dart' as app_notification;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/firestore_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreNotificationService _firestoreNotificationService =
      FirestoreNotificationService();
  List<app_notification.Notification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  app_notification.Notification? _selectedNotification;
  String _filter = 'all'; // 'all', 'read', 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _markWelcomeNotificationAsRead();
  }

  Future<void> _markWelcomeNotificationAsRead() async {
    try {
      await _notificationService.markWelcomeNotificationAsRead();
      // Force refresh the app bar badge count
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // This will trigger a rebuild of the app bar
          setState(() {});
        }
      });
    } catch (e) {
      print('Error marking welcome notification as read: $e');
    }
  }

  List<app_notification.Notification> get _filteredNotifications {
    switch (_filter) {
      case 'read':
        return _notifications.where((n) => n.isRead).toList();
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      default:
        return _notifications;
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userSession =
          Provider.of<UserSessionProvider>(context, listen: false);
      final clientNumber = userSession.clientNumber;

      print('Current user: ${user?.uid}');
      print('User phone: ${user?.phoneNumber}');
      print('User email: ${user?.email}');
      print('Client number from session: $clientNumber');

      final List<app_notification.Notification> notifications = [];

      // Check if welcome notification should be shown
      final prefs = await SharedPreferences.getInstance();
      final welcomeSent = prefs.getBool('welcome_notification_sent') ?? false;
      final welcomeRead = prefs.getBool('welcome_notification_read') ?? false;

      // Add welcome notification if it was sent but not read
      if (welcomeSent && !welcomeRead) {
        notifications.add(app_notification.Notification(
          id: 'welcome_notification',
          title: 'Welcome to Healthy Mama! 🎉',
          body:
              'Thank you for joining us! We are here to support you on your maternal health journey. You can expect to receive notifications here when we respond to your reports or have important updates for you. Feel free to explore the app and let us know if you need any assistance!',
          timestamp: DateTime.now(),
          isRead: false,
        ));
      }

      // Load notifications from Firestore notifications collection
      if (clientNumber != null && clientNumber.isNotEmpty) {
        try {
          print(
              'Loading notifications from Firestore for client: $clientNumber');

          // Get notifications from the notifications collection
          final firestoreNotifications =
              await _firestoreNotificationService.getNotifications(context);
          notifications.addAll(firestoreNotifications);

          print(
              'Loaded ${firestoreNotifications.length} notifications from Firestore');

          // Also load report responses (existing functionality)
          try {
            final querySnapshot = await FirebaseFirestore.instance
                .collection('report')
                .where('clientNumber', isEqualTo: clientNumber)
                .where('reply', isNotEqualTo: '')
                .get();

            print('Found ${querySnapshot.docs.length} reports with replies');

            for (final doc in querySnapshot.docs) {
              final data = doc.data();

              // Client-side check for deleted notifications
              if (data['deleted'] == true) {
                continue; // Skip this notification
              }

              print('Report data: ${data.toString()}');

              if (data['reply'] != null &&
                  data['reply'].toString().isNotEmpty) {
                notifications.add(app_notification.Notification(
                  id: 'report_${doc.id}',
                  title: 'Response to Your Report',
                  body: data['reply'],
                  timestamp: data['replySentAt'] != null
                      ? DateTime.parse(data['replySentAt'])
                      : DateTime.now(),
                  isRead: data['isRead'] ?? false,
                ));
              }
            }
          } catch (reportError) {
            print('Error loading report responses: $reportError');
          }
        } catch (firestoreError) {
          print('Firestore error (non-critical): $firestoreError');
          // Add a demo notification if Firestore fails
          notifications.add(app_notification.Notification(
            id: 'demo_notification',
            title: 'Demo Notification 📋',
            body:
                'This is a demo notification to show how the notification system works. When you submit reports through the app, you\'ll receive responses here. The notification popup feature allows you to read the full message by tapping on any notification.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: false,
          ));
        }
      } else {
        // Add demo notifications when user is not authenticated
        notifications.addAll([
          app_notification.Notification(
            id: 'demo_notification_1',
            title: 'Demo Notification 📋',
            body:
                'This is a demo notification to show how the notification system works. When you submit reports through the app, you\'ll receive responses here. The notification popup feature allows you to read the full message by tapping on any notification.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: false,
          ),
          app_notification.Notification(
            id: 'demo_notification_2',
            title: 'How to Use Notifications 💡',
            body:
                'Tap on any notification to see the full message in a popup. Unread notifications are marked with a blue dot. Pull down to refresh the list. This system will show responses to your reports and important updates.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: true,
          ),
        ]);
      }

      print('Created ${notifications.length} notifications');

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      // Even if there's an error, show demo notifications
      final demoNotifications = [
        app_notification.Notification(
          id: 'error_demo_1',
          title: 'Welcome to Notifications! 🎉',
          body:
              'This is a demo notification to show how the notification system works. Tap on any notification to see the full message in a beautiful popup interface.',
          timestamp: DateTime.now(),
          isRead: false,
        ),
        app_notification.Notification(
          id: 'error_demo_2',
          title: 'Demo Response 📝',
          body:
              'This simulates a response to a report you might submit. The notification system will show responses from healthcare providers and important updates about your maternal health journey.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: true,
        ),
      ];

      setState(() {
        _notifications = demoNotifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(app_notification.Notification notification) async {
    try {
      // Handle welcome notification
      if (notification.id == 'welcome_notification') {
        await _notificationService.markWelcomeNotificationAsRead();
      }
      // Handle Firestore notifications
      else if (!notification.id.startsWith('demo_') &&
          !notification.id.startsWith('error_demo_') &&
          !notification.id.startsWith('report_')) {
        await _firestoreNotificationService
            .markNotificationAsRead(notification.id);
      }
      // Handle report notifications (existing functionality)
      else if (notification.id.startsWith('report_')) {
        final reportId = notification.id.replaceFirst('report_', '');
        await _notificationService.markNotificationAsRead(reportId);
      }

      // Update local state for all notifications
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return app_notification.Notification(
              id: n.id,
              title: n.title,
              body: n.body,
              timestamp: n.timestamp,
              isRead: true,
            );
          }
          return n;
        }).toList();
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAsUnread(app_notification.Notification notification) async {
    try {
      // Handle Firestore notifications
      if (!notification.id.startsWith('demo_') &&
          !notification.id.startsWith('welcome_') &&
          !notification.id.startsWith('error_demo_') &&
          !notification.id.startsWith('report_')) {
        await _firestoreNotificationService
            .markNotificationAsUnread(notification.id);
      }
      // Handle report notifications (existing functionality)
      else if (notification.id.startsWith('report_')) {
        final reportId = notification.id.replaceFirst('report_', '');
        await _notificationService.markNotificationAsUnread(reportId);
      }

      // Update local state for all notifications
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return app_notification.Notification(
              id: n.id,
              title: n.title,
              body: n.body,
              timestamp: n.timestamp,
              isRead: false,
            );
          }
          return n;
        }).toList();
      });
    } catch (e) {
      print('Error marking notification as unread: $e');
      // Still update local state even if Firestore fails
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return app_notification.Notification(
              id: n.id,
              title: n.title,
              body: n.body,
              timestamp: n.timestamp,
              isRead: false,
            );
          }
          return n;
        }).toList();
      });
    }
  }

  Future<void> _deleteNotification(
      app_notification.Notification notification) async {
    try {
      // Handle Firestore notifications
      if (!notification.id.startsWith('demo_') &&
          !notification.id.startsWith('welcome_') &&
          !notification.id.startsWith('error_demo_') &&
          !notification.id.startsWith('report_')) {
        await _firestoreNotificationService.deleteNotification(notification.id);
      }
      // Handle report notifications (existing functionality)
      else if (notification.id.startsWith('report_')) {
        final reportId = notification.id.replaceFirst('report_', '');
        await _notificationService.deleteNotification(reportId);
      }

      // Remove from local state
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _undoDelete(notification),
          ),
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      // Still remove from local state even if Firestore fails
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    }
  }

  void _undoDelete(app_notification.Notification notification) {
    setState(() {
      _notifications.add(notification);
    });
  }

  void _showNotificationOptions(app_notification.Notification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.mark_email_unread
                    : Icons.mark_email_read,
                color: notification.isRead ? Colors.orange : Colors.green,
              ),
              title: Text(
                notification.isRead ? 'Mark as unread' : 'Mark as read',
              ),
              onTap: () {
                Navigator.pop(context);
                if (notification.isRead) {
                  _markAsUnread(notification);
                } else {
                  _markAsRead(notification);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete notification'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(notification);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(app_notification.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
            'Are you sure you want to delete this notification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(notification);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotificationPopup(app_notification.Notification notification) {
    // Mark as read when opened
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    setState(() {
      _selectedNotification = notification;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationPopup(notification),
    );
  }

  Widget _buildNotificationPopup(app_notification.Notification notification) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? Colors.grey[100]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: notification.isRead
                        ? Colors.grey[600]
                        : Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(notification.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: SharedAppBar(
        visitNumber: 'Notifications',
        isHomeScreen: false,
        onNotificationPressed: () {},
      ),
      body: Column(
        children: [
          // Filter buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('all', 'All', _notifications.length),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('unread', 'Unread',
                      _notifications.where((n) => !n.isRead).length),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('read', 'Read',
                      _notifications.where((n) => n.isRead).length),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading notifications...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadNotifications,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filter == 'all'
                                      ? 'No notifications available'
                                      : 'No ${_filter} notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _filter == 'all'
                                      ? 'Notifications will appear here when you receive\nresponses to your reports or important updates.'
                                      : 'Try changing the filter or refreshing the list.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadNotifications,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    _filteredNotifications[index];
                                return Dismissible(
                                  key: Key(notification.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            const Text('Delete Notification'),
                                        content: const Text(
                                            'Are you sure you want to delete this notification?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) {
                                    _deleteNotification(notification);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showNotificationPopup(
                                            notification),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Notification icon
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: notification.isRead
                                                      ? Colors.grey[100]
                                                      : Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.notifications,
                                                  color: notification.isRead
                                                      ? Colors.grey[600]
                                                      : Colors.blue[600],
                                                  size: 20,
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              // Title and message
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.title,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      notification.body,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[800],
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Unread dot
                                              if (!notification.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color:
                                                        Colors.blue,
                                                    shape: BoxShape
                                                        .circle,
                                                  ),
                                                ),

                                              // Menu button
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: Colors.grey[400],
                                                  size: 20,
                                                ),
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 'read':
                                                      if (notification.isRead) {
                                                        _markAsUnread(
                                                            notification);
                                                      } else {
                                                        _markAsRead(
                                                            notification);
                                                      }
                                                      break;
                                                    case 'delete':
                                                      _showDeleteConfirmation(
                                                          notification);
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'read',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          notification.isRead
                                                              ? Icons
                                                                  .mark_email_unread
                                                              : Icons
                                                                  .mark_email_read,
                                                          color: notification
                                                                  .isRead
                                                              ? Colors.orange
                                                              : Colors.green,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          notification.isRead
                                                              ? 'Mark as unread'
                                                              : 'Mark as read',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        const Text('Delete'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.blue[600] : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

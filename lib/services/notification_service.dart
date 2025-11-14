import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/notification.dart' as app_notification;
import '../models/medication.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../screens/alarm_page.dart';
import '../main.dart'; // Import to access navigatorKey
import 'package:healthymamaapp/services/alarm_service.dart';

@pragma('vm:entry-point')
void _scheduleNotificationsCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = NotificationService();
  await service.init();

  final prefs = await SharedPreferences.getInstance();
  final medicationsJson = prefs.getStringList('manualMedications');

  if (medicationsJson != null) {
    final medications =
        medicationsJson
            .map((json) => Medication.fromMap(jsonDecode(json)))
            .toList();

    for (final medication in medications) {
      for (int i = 0; i < medication.reminderTimes.length; i++) {
        final time = medication.reminderTimes[i];
        final now = tz.TZDateTime.now(tz.local);
        final scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // Check if it's time for the medication (within 1 minute window)
        final timeDifference = now.difference(scheduledTime).inMinutes;
        if (timeDifference >= 0 && timeDifference < 1) {
          print(
            'Medication time reached for ${medication.name} at ${time.hour}:${time.minute}',
          );
          if (medication.alarmEnabled) {
            await AlarmService.start();
          } else {
            final notificationId = medication.id.hashCode + i;
            await service.scheduleDailyNotification(
              id: notificationId,
              title: 'Medication Reminder',
              body: 'It\'s time to take your ${medication.name}.',
              time: TimeOfDay(hour: time.hour, minute: time.minute),
            );
          }
        }
      }
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload == 'alarm') {
            // This can be removed or repurposed if full-screen intent is no longer used
            // For now, we'll have it stop the alarm as a fallback.
            AlarmService.stop();
          } else if (response.payload == 'stop_alarm') {
            // This is now handled by the native notification's PendingIntent.
            // But as a fallback, we can call stop here too.
            AlarmService.stop();
          }
        },
      );

      // Request notification permissions
      await _requestPermissions();
    } catch (e) {
      print('Error initializing notifications: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request notification permission for Android 13+
      if (await Permission.notification.request().isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }

      // Request exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        print('Exact alarm permission granted');
      } else {
        print('Exact alarm permission denied');
      }
    } catch (e) {
      // Silently catch permission errors during initialization
      // These can occur if the activity context is not ready
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
    }
  }

  Future<void> scheduleReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Channel for reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Try exact scheduling first
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          title,
          body,
          tzScheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('Reminder notification scheduled successfully with exact timing');
      } catch (e) {
        print('Exact scheduling failed, trying inexact: $e');
        // Fallback to inexact scheduling
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          title,
          body,
          tzScheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print(
          'Reminder notification scheduled successfully with inexact timing',
        );
      }
    } catch (e) {
      print('Error scheduling reminder notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      const androidDetails = AndroidNotificationDetails(
        'medication_reminders_daily',
        'Daily Medication Reminders',
        channelDescription: 'Daily reminders to take your medication',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification'),
        playSound: true,
      );
      const platformDetails = NotificationDetails(android: androidDetails);

      // Try exact scheduling first
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          platformDetails,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('Daily notification scheduled successfully with exact timing');
      } catch (e) {
        print('Exact scheduling failed, trying inexact: $e');
        // Fallback to inexact scheduling
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          platformDetails,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('Daily notification scheduled successfully with inexact timing');
      }
    } catch (e) {
      print('Error scheduling daily notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleTestNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel for test notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Try exact scheduling first
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          999, // Use a different ID for test notifications
          title,
          body,
          tzScheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('Test notification scheduled successfully with exact timing');
      } catch (e) {
        print('Exact scheduling failed, trying inexact: $e');
        // Fallback to inexact scheduling
        await flutterLocalNotificationsPlugin.zonedSchedule(
          999,
          title,
          body,
          tzScheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('Test notification scheduled successfully with inexact timing');
      }
    } catch (e) {
      print('Error scheduling test notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // New method to fetch notifications from Firestore report collection
  Future<List<app_notification.Notification>> fetchUserNotifications(
    String clientNumber,
  ) async {
    try {
      if (clientNumber.isEmpty) {
        throw Exception('Client number not found');
      }

      // Query reports where the user is the client and has a reply from admin
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('report')
              .where('clientNumber', isEqualTo: clientNumber)
              .where('reply', isNull: false)
              .where('reply', isNotEqualTo: '')
              .orderBy('replySentAt', descending: true)
              .get();

      final List<app_notification.Notification> notifications = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['reply'] != null && data['reply'].toString().isNotEmpty) {
          notifications.add(
            app_notification.Notification(
              id: doc.id,
              title: 'Response to Your Report',
              body: data['reply'],
              timestamp:
                  data['replySentAt'] != null
                      ? DateTime.parse(data['replySentAt'])
                      : DateTime.now(),
              isRead: data['isRead'] ?? false,
            ),
          );
        }
      }

      return notifications;
    } catch (e) {
      print('Error fetching user notifications: $e');
      rethrow;
    }
  }

  // Method to mark welcome notification as read
  Future<void> markWelcomeNotificationAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('welcome_notification_read', true);
    } catch (e) {
      print('Error marking welcome notification as read: $e');
    }
  }

  // Method to mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('report')
          .doc(notificationId)
          .update({
            'isRead': true,
            'lastReadAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Method to mark a notification as unread
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('report')
          .doc(notificationId)
          .update({'isRead': false, 'lastReadAt': null});
    } catch (e) {
      print('Error marking notification as unread: $e');
      rethrow;
    }
  }

  // Method to delete a notification (soft delete)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('report')
          .doc(notificationId)
          .update({
            'deleted': true,
            'deletedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Method to get unread notification count
  Future<int> getUnreadNotificationCount(String clientNumber) async {
    try {
      int count = 0;

      // Only filter by clientNumber and isRead == false
      if (clientNumber.isNotEmpty) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('report')
                .where('clientNumber', isEqualTo: clientNumber)
                .where('isRead', isEqualTo: false)
                .get();

        // Optionally filter out deleted notifications on the client side
        final docs = querySnapshot.docs.where(
          (doc) => doc.data()['deleted'] != true,
        );
        count += docs.length;
      }

      // Check for welcome notification (local notification)
      final prefs = await SharedPreferences.getInstance();
      final welcomeSent = prefs.getBool('welcome_notification_sent') ?? false;
      final welcomeRead = prefs.getBool('welcome_notification_read') ?? false;

      // If welcome notification was sent but not read, count it
      if (welcomeSent && !welcomeRead) {
        count += 1;
      }

      return count;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Method to check for new notifications (for real-time updates)
  Stream<List<app_notification.Notification>> getNotificationsStream(
    String clientNumber,
  ) {
    try {
      if (clientNumber.isEmpty) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('report')
          .where('clientNumber', isEqualTo: clientNumber)
          .where('reply', isNull: false)
          .where('reply', isNotEqualTo: '')
          .orderBy('replySentAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final filteredDocs = snapshot.docs.where(
              (doc) => doc.data()['deleted'] != true,
            );
            return filteredDocs.map((doc) {
              final data = doc.data();
              return app_notification.Notification(
                id: doc.id,
                title: 'Response to Your Report',
                body: data['reply'],
                timestamp:
                    data['replySentAt'] != null
                        ? DateTime.parse(data['replySentAt'])
                        : DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
            }).toList();
          });
    } catch (e) {
      print('Error setting up notifications stream: $e');
      return Stream.value([]);
    }
  }

  Future<void> schedulePeriodicMedicationNotifications() async {
    const alarmId = 1; // Unique ID for the periodic alarm
    await AndroidAlarmManager.cancel(alarmId); // Cancel any existing alarm
    await AndroidAlarmManager.periodic(
      const Duration(
        minutes: 1,
      ), // Check every minute for more responsive alarms
      alarmId,
      _scheduleNotificationsCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    print(
      'Periodic medication notification scheduling enabled (checking every minute).',
    );
  }

  Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required bool alarmEnabled,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    final androidDetails = AndroidNotificationDetails(
      alarmEnabled ? 'medication_alarm' : 'medication_reminders_daily',
      alarmEnabled ? 'Medication Alarm' : 'Daily Medication Reminders',
      channelDescription:
          alarmEnabled
              ? 'Alarms for medication reminders'
              : 'Daily reminders to take your medication',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: alarmEnabled,
    );
    final platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      payload: alarmEnabled ? 'alarm' : null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

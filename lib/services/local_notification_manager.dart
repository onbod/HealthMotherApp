import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

class LocalNotificationManager {
  static final LocalNotificationManager _instance =
      LocalNotificationManager._internal();
  factory LocalNotificationManager() => _instance;
  LocalNotificationManager._internal();

  /// Call this on app start
  Future<void> handleAppLaunch() async {
    await _sendWelcomeNotificationIfFirstTime();
  }

  /// Manual method to trigger welcome notification for testing
  Future<void> triggerWelcomeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_notification_sent', true);
    await prefs.setBool('welcome_notification_read', false);
    print('Welcome notification manually triggered for testing');
  }

  /// 1. Welcome notification (only once)
  Future<void> _sendWelcomeNotificationIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final sent = prefs.getBool('welcome_notification_sent') ?? false;
    if (!sent) {
      final notificationService = NotificationService();
      await notificationService.flutterLocalNotificationsPlugin.show(
        2000,
        'Welcome to Healthy Mama!',
        'Thank you for installing the app. We wish you a healthy pregnancy journey!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'welcome_channel',
            'Welcome Notifications',
            channelDescription:
                'Welcome notification when app is first installed',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
      await prefs.setBool('welcome_notification_sent', true);
      await prefs.setBool('welcome_notification_read', false);
      print('Welcome notification sent and flags set: sent=true, read=false');
    } else {
      print('Welcome notification already sent, skipping');
    }
  }

  /// 2. Next visit countdown notification
  Future<void> scheduleNextVisitNotification(DateTime visitDate) async {
    final notificationService = NotificationService();
    // Schedule for 1 day before the visit at 9:00 AM
    final DateTime notificationTime = DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
      9,
      0,
      0,
    ).subtract(const Duration(days: 1));
    if (notificationTime.isAfter(DateTime.now())) {
      await notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
        2001,
        'Upcoming Visit Reminder',
        'You have a scheduled visit this Week. Don\'t forget to attend!',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'visit_channel',
            'Visit Reminders',
            channelDescription: 'Reminders for upcoming visits',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// 3. Weekly pregnancy progress notification
  Future<void> scheduleWeeklyPregnancyNotifications({
    required int currentWeek,
    int maxWeek = 40,
    TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    final notificationService = NotificationService();
    final now = DateTime.now();
    for (int week = currentWeek + 1; week <= maxWeek; week++) {
      // Schedule for the same weekday/time as today, for each coming week
      final DateTime weekDate = now.add(
        Duration(days: 7 * (week - currentWeek)),
      );
      final DateTime scheduled = DateTime(
        weekDate.year,
        weekDate.month,
        weekDate.day,
        notificationTime.hour,
        notificationTime.minute,
      );
      if (scheduled.isAfter(now)) {
        await notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
          2100 + week,
          'Pregnancy Progress',
          'Congratulations! You\'ve reached week $week of your pregnancy.',
          tz.TZDateTime.from(scheduled, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'weekly_channel',
              'Weekly Pregnancy Progress',
              channelDescription: 'Weekly pregnancy progress notifications',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
    }
  }

  /// Cancel all local notifications managed by this manager
  Future<void> cancelAllLocalNotifications() async {
    final notificationService = NotificationService();
    await notificationService.cancelAllNotifications();
  }
}

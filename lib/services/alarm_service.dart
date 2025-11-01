import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static const _channel = MethodChannel(
    'com.example.healthymamaapp/alarm_service',
  );

  static Future<void> start() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startAlarmService');
      } catch (e) {
        print('Error starting alarm service: $e');
      }
    }
  }

  static Future<void> stop() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stopAlarmService');
      } catch (e) {
        print('Error stopping alarm service: $e');
      }
    }
  }

  static Future<void> scheduleNativeAlarm(
    DateTime dateTime,
    String sound,
  ) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('scheduleNativeAlarm', {
          'timestamp': dateTime.millisecondsSinceEpoch,
          'sound': sound,
        });
        print('Native alarm scheduled for: $dateTime with sound: $sound');
      } catch (e) {
        print('Error scheduling native alarm: $e');
      }
    }
  }

  static Future<void> cancel() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('cancel');
      } catch (e) {
        print('Error canceling alarm: $e');
      }
    }
  }
}

Future<void> requestAlarmPermission() async {
  if (!kIsWeb && Platform.isAndroid) {
    await Permission.scheduleExactAlarm.request();
  }
}

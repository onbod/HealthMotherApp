import 'package:flutter/services.dart';

class AlarmService {
  static const _channel =
      MethodChannel('com.example.healthymamaapp/alarm_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startAlarmService');
      print('Platform channel: startAlarmService called.');
    } on PlatformException catch (e) {
      print("Failed to start alarm service: '${e.message}'.");
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopAlarmService');
      print('Platform channel: stopAlarmService called.');
    } on PlatformException catch (e) {
      print("Failed to stop alarm service: '${e.message}'.");
    }
  }

  static Future<void> scheduleNativeAlarm(
      DateTime dateTime, String sound) async {
    try {
      await _channel.invokeMethod('scheduleNativeAlarm', {
        'timestamp': dateTime.millisecondsSinceEpoch,
        'sound': sound,
      });
    } on PlatformException catch (e) {
      print('Failed to schedule native alarm: \\${e.message}');
    }
  }
}

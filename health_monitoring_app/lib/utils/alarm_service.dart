import 'dart:io';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Alarm.init();
  }

  static Future<void> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    await checkAndRequestPermissions();

    if (dateTime.isBefore(DateTime.now())) return;

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/audio/alarm.mp3', // Loud audio
      volumeSettings: VolumeSettings.fade(
        volume: 1.0, // Max volume
        fadeDuration: const Duration(seconds: 0),
        volumeEnforced: true, // Bypass silent mode
      ),
      vibrate: true,
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Đã uống thuốc / Tắt báo',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> stopAll() async {
    await Alarm.stopAll();
  }

  static Future<bool> isRinging(int id) async {
    return Alarm.isRinging(id);
  }
}

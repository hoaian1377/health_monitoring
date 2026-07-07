import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Khởi tạo ──────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Cấu hình Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  // ── Xin Quyền (Gọi sau khi app đã lên UI) ────────────────────────────────
  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  // ── Chi tiết channel Android ───────────────────────────────────────────────
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'medicine_reminder_channel',   // channel ID
    'Nhắc nhở uống thuốc',         // channel name
    channelDescription: 'Thông báo nhắc uống thuốc đúng giờ',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Đặt alarm (scheduled notification) ───────────────────────────────────
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;

    // Chuyển sang tz.TZDateTime theo timezone local
    final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'medicine_$id',
    );

    debugPrint(
        '✅ Đã đặt nhắc nhở: "$title" lúc ${dateTime.hour.toString().padLeft(2, "0")}:${dateTime.minute.toString().padLeft(2, "0")}');
  }

  // ── Đặt alarms từ danh sách API ───────────────────────────────────────────
  static Future<void> scheduleAlarmsFromApiData(
      List<dynamic> schedules) async {
    final now = DateTime.now();

    for (var schedule in schedules) {
      final med = schedule['medication'] ?? {};
      final name = med['name']?.toString() ?? 'Thuốc';
      final dosage = med['dosage']?.toString() ?? '';
      final instruction = med['instruction']?.toString() ?? '';
      final timeStr = schedule['time']?.toString();
      final scheduleId = schedule['schedule_id']?.toString() ?? '';

      if (timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      var alarmTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // Nếu giờ đã qua hôm nay → đặt cho ngày mai
      if (alarmTime.isBefore(now) ||
          alarmTime.isAtSameMomentAs(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      // ID duy nhất dựa trên schedule_id + time
      final alarmId =
          '${scheduleId}_$timeStr'.hashCode.abs() % 2147483647;

      final body =
          [
            if (dosage.isNotEmpty) dosage,
            if (instruction.isNotEmpty) instruction,
          ].join(' • ');

      await scheduleAlarm(
        id: alarmId,
        dateTime: alarmTime,
        title: '💊 $name — Đến giờ uống thuốc!',
        body: body.isNotEmpty ? body : 'Nhớ uống thuốc đúng giờ nhé!',
      );
    }
  }

  // ── Hủy một alarm ─────────────────────────────────────────────────────────
  static Future<void> stopAlarm(int id) async {
    await _plugin.cancel(id);
  }

  // ── Hủy tất cả alarms ─────────────────────────────────────────────────────
  static Future<void> stopAll() async {
    await _plugin.cancelAll();
  }

  // ── Hiển thị ngay (dùng để test) ──────────────────────────────────────────
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _notificationDetails);
  }
}

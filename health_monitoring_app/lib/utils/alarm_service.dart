import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Function(String?)? onNotificationClick;

  // ── Khởi tạo ──────────────────────────────────────────────────────────────
  static Future<void> init({Function(String?)? onNotificationClick}) async {
    AlarmService.onNotificationClick = onNotificationClick;
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
        if (onNotificationClick != null) {
          onNotificationClick!(details.payload);
        }
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
    'medicine_reminder_channel_v2',   // channel ID (đổi ID để Android reset lại channel với Importance.max)
    'Nhắc nhở uống thuốc',            // channel name
    channelDescription: 'Thông báo nhắc uống thuốc đúng giờ (Quan trọng)',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    ticker: 'Nhắc nhở uống thuốc',
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

  // ── Đặt alarms từ danh sách Appointment API ────────────────────────────────
  static Future<void> scheduleAppointmentsFromApiData(
      List<dynamic> appointments) async {
    final now = DateTime.now();

    for (var appt in appointments) {
      final dateStr = appt['appointment_date']?.toString();
      final timeStr = appt['appointment_time']?.toString();
      final doctorName = appt['doctor_name']?.toString() ?? 'bác sĩ';
      final location = appt['location']?.toString() ?? '';
      final apptId = appt['appointment_id'] ?? appt['appointmentid'] ?? 0;

      if (dateStr == null || timeStr == null) continue;

      try {
        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');
        
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final apptDateTime = DateTime(year, month, day, hour, minute);
        
        // Cài báo thức nhắc trước 2 tiếng
        final alarmTime = apptDateTime.subtract(const Duration(hours: 2));

        if (alarmTime.isAfter(now)) {
          final alarmId = 'appt_$apptId'.hashCode.abs() % 2147483647;
          
          String body = 'Thời gian: $hour:${minute.toString().padLeft(2, '0')}';
          if (location.isNotEmpty) body += ' tại $location';
          
          await scheduleAlarm(
            id: alarmId,
            dateTime: alarmTime,
            title: '🏥 Nhắc nhở tái khám: $doctorName',
            body: body,
          );
        }
      } catch (e) {
        debugPrint("Lỗi parse ngày giờ lịch khám: $e");
      }
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

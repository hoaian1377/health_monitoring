import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../utils/alarm_service.dart';

import 'elderly_appointment_screen.dart';
import 'elderly_chat_screen.dart';
class ElderlyHomeScreen extends StatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  State<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends State<ElderlyHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  List<dynamic> _medicationSchedules = [];
  bool _isLoadingMedications = true;
  Set<int> _takenScheduleIds = {};

  late String _selectedMedFilter;

  String _getCurrentSessionFilter() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Sáng';
    } else if (hour >= 11 && hour < 15) {
      return 'Trưa';
    } else {
      return 'Chiều/Tối';
    }
  }

  String _getMedicationSession(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return 'Khác';
    try {
      final hour = int.parse(timeStr.split(':')[0]);
      if (hour >= 5 && hour < 11) {
        return 'Buổi sáng';
      } else if (hour >= 11 && hour < 15) {
        return 'Buổi trưa';
      } else {
        return 'Buổi chiều/tối';
      }
    } catch (_) {
      return 'Khác';
    }
  }


  // Chỉ số sức khoẻ (giữ lại để tránh lỗi biên dịch)
  String _bpSys = '--';
  String _bpDia = '--';
  String _heartRate = '--';
  String _bloodSugar = '--';
  String _temperature = '--';

  bool _isAppointmentNear = true;
  bool _isDocChecklistExpanded = true;

  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  late AnimationController _pulseController;
  Timer? _clockTimer;
  Timer? _appointmentPollTimer;
  final Set<String> _knownAppointmentIds = {};
  DateTime _now = DateTime.now();

  // Trạng thái ngày được chọn
  DateTime _selectedDate = DateTime.now();

  // Lịch tuần cuộn ngang theo trang (PageView) để cố định 1 tuần trên màn hình
  PageController? _pageController;
  int _currentCalendarPage = 1000;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedMedFilter = _getCurrentSessionFilter();
    _loadMedications();
    _loadNotifications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
        _checkAndShowReminders();
      }
    });

    _pollAppointments();
    _appointmentPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _pollAppointments();
    });

    // Request permissions appropriately (must happen when UI is running)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService.requestPermissions();
    });

    // Khởi tạo PageController với trang mặc định là 1000 đại diện cho tuần này
    _pageController = PageController(initialPage: 1000);
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoadingMedications = true);
    final accountId = ApiService.currentAccountId ?? 0;
    
    // Load medications
    final schedules = await ApiService.getElderlyMedicationSchedule(accountId);
    
    // Schedule medication alarms
    AlarmService.scheduleAlarmsFromApiData(schedules);

    // Load appointments and schedule alarms
    final appointments = await ApiService.getAppointments(accountId);
    AlarmService.scheduleAppointmentsFromApiData(appointments);

    // Load health metrics

    final data = await ApiService.getHealthMetrics(accountId);
    
    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;
        
        if (data.isNotEmpty) {
          bool foundHr = false;
          bool foundBp = false;
          bool foundSugar = false;
          bool foundTemp = false;

          for (var item in data) {
            if (!foundHr && item['heart_rate'] != null) {
              _heartRate = item['heart_rate'].toString();
              foundHr = true;
            }
            if (!foundBp && item['blood_pressure'] != null) {
              final bp = item['blood_pressure'].toString().split('/');
              if (bp.length == 2) {
                _bpSys = bp[0];
                _bpDia = bp[1];
                foundBp = true;
              }
            }
            if (!foundSugar && item['blood_sugar'] != null) {
              _bloodSugar = item['blood_sugar'].toString();
              foundSugar = true;
            }
            if (!foundTemp && item['temperature'] != null) {
              _temperature = item['temperature'].toString();
              foundTemp = true;
            }
          }
        }
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      int unread = 0;
      for (var item in data) {
        final notifDetail = item['details'] != null && item['details'].isNotEmpty ? item['details'][0] : null;
        bool isRead = notifDetail != null ? notifDetail['is_read'] : false;
        if (!isRead) {
          unread++;
        }
      }
      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _appointmentPollTimer?.cancel();
    _pulseController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _pollAppointments() async {
    final accountId = ApiService.currentAccountId;
    if (accountId == null) return;
    
    final data = await ApiService.getAppointments(accountId);
    if (!mounted) return;
    
    bool hasNew = false;
    String newDoctor = '';
    String newTime = '';
    String newLocation = '';
    
    for (var item in data) {
      final id = item['appointmentid'].toString();
      if (!_knownAppointmentIds.contains(id)) {
        if (_knownAppointmentIds.isNotEmpty) {
           hasNew = true;
           newDoctor = item['doctor_name'] ?? 'Bác sĩ';
           newTime = item['appointment_time']?.toString().substring(0, 5) ?? '08:00';
           newLocation = item['location'] ?? 'Bệnh viện';
        }
        _knownAppointmentIds.add(id);
      }
    }
    
    if (hasNew) {
      await AlarmService.showImmediateNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '🗓️ Lịch khám mới: $newDoctor',
        body: 'Thời gian: $newTime tại $newLocation',
        payload: 'appointment_immediate',
      );
    }
  }

  // Set lưu ID các lịch đã báo để không báo lại nhiều lần trong cùng 1 phút
  final Set<int> _notifiedScheduleIds = {};
  
  // Set lưu ID các lịch đã gửi cảnh báo quên thuốc cho caregiver
  final Set<int> _missedNotifiedScheduleIds = {};

  // Hàm kiểm tra tới giờ uống thuốc
  void _checkAndShowReminders() {
    if (_medicationSchedules.isEmpty) return;
    
    final now = DateTime.now();
    final todayKey = _getDateKey(now);

    for (var schedule in _medicationSchedules) {
      final timeStr = schedule['time']?.toString() ?? '';
      if (timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final scheduleId = schedule['schedule_id'] as int;

      // Nếu đúng giờ phút hiện tại và chưa báo động lần nào
      if (now.hour == hour && now.minute == minute && !_notifiedScheduleIds.contains(scheduleId)) {
        // Chỉ nhắc nếu chưa đánh dấu đã uống
        if (!_isMedicationTaken(scheduleId, now)) {
          _notifiedScheduleIds.add(scheduleId);
          _showMedicineReminderDialog(schedule);
        }
      }

      // Logic cảnh báo "Quên uống thuốc" cho Caregiver sau 5 phút
      final missedTime = DateTime(now.year, now.month, now.day, hour, minute).add(const Duration(minutes: 5));
      if (now.isAfter(missedTime) && now.day == missedTime.day && !_missedNotifiedScheduleIds.contains(scheduleId)) {
        if (!_isMedicationTaken(scheduleId, now)) {
          _missedNotifiedScheduleIds.add(scheduleId);
          final accountId = ApiService.currentAccountId;
          if (accountId != null) {
            final medName = schedule['medication']?['name']?.toString() ?? 'Thuốc';
            ApiService.notifyMissedMedication(accountId, medName);
          }
        }
      }
    }
  }

  // Form (Dialog) nhắc nhở uống thuốc đẹp và reo chuông
  void _showMedicineReminderDialog(Map<String, dynamic> schedule) async {
    final med = schedule['medication'] ?? {};
    final medName = med['name']?.toString() ?? 'Thuốc';
    final dosage = _translateDosage(med['dosage']?.toString() ?? '');
    final instruction = med['instruction']?.toString() ?? '';
    final timeStr = schedule['time']?.toString() ?? '';
    final scheduleId = schedule['schedule_id'] as int;

    // Khởi tạo và phát âm thanh báo thức (Lặp lại)
    final player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/alarm.mp3'));

    // Bật Rung
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000], repeat: 1); // Lặp rung liên tục
    }

    // Hàm dọn dẹp khi tắt popup
    void stopAlarmAndClose() {
      player.stop();
      Vibration.cancel();
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc phải tương tác
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Rung/Chuông có hiệu ứng
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: Colors.redAccent, size: 56),
                ),
                const SizedBox(height: 20),
                
                // Tiêu đề
                const Text(
                  'TỚI GIỜ UỐNG THUỐC!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã đến cữ $timeStr. Bác uống thuốc ngay nhé!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // Khối thông tin thuốc (Thiết kế Card)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_rounded, color: Colors.blue, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              medName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white, thickness: 2, height: 24),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.black54, size: 20),
                          const SizedBox(width: 8),
                          Text('Liều lượng: $dosage', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (instruction.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lưu ý: $instruction',
                                style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Các nút hành động
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: stopAlarmAndClose,
                        child: const Text('ĐỂ SAU', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Màu xanh ngọc lục bảo đẹp
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          stopAlarmAndClose();
                          _toggleMedicationTaken(scheduleId, DateTime.now(), medName);
                        },
                        child: const Text('ĐÃ UỐNG XONG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper cho định dạng khoá ngày
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Chuyển thứ sang tiếng Việt viết tắt
  String _getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  // Định dạng ngày hiển thị ở tiêu đề, đã bổ sung thêm Năm theo yêu cầu (Ví dụ: 04 Th7, 2026)
  String _formatHeaderDate(DateTime date) {
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr Th${date.month}, ${date.year}';
  }

  // Dịch và chuẩn hoá liều lượng sang tiếng Việt
  String _translateDosage(String dosage) {
    if (dosage.isEmpty) return '';
    return dosage
        .replaceAll('milligram(s)', 'mg')
        .replaceAll('milligram', 'mg')
        .replaceAll('tablet(s)', 'viên')
        .replaceAll('tablet', 'viên')
        .replaceAll('pill(s)', 'viên')
        .replaceAll('pill', 'viên')
        .replaceAll('dose(s)', 'liều')
        .replaceAll('dose', 'liều');
  }

  // Xây dựng dòng mô tả phụ hiển thị giống trên hình (Ví dụ: sau ăn · 1 lần)
  String _buildMedicationSubtitle(Map<String, dynamic> med) {
    final instruction = med['instruction'] ?? '';
    final dosage = _translateDosage(med['dosage'] ?? '');
    final frequency = med['frequency'] ?? '';
    
    final List<String> parts = [];
    if (instruction.isNotEmpty) {
      parts.add(instruction);
    }
    
    if (dosage.isNotEmpty) {
      parts.add(dosage);
    } else if (frequency.isNotEmpty) {
      parts.add(frequency);
    } else {
      parts.add('1 liều');
    }
    
    return parts.join(' · ');
  }

  // Phân loại tự động biểu tượng theo tên thuốc
  IconData _getMedicationIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('siro') || lower.contains('nước') || lower.contains('dầu') || lower.contains('giọt') || lower.contains('dung dịch')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('sữa') || lower.contains('bột') || lower.contains('gói') || lower.contains('pha')) {
      return Icons.science_outlined;
    }
    if (lower.contains('tiêm') || lower.contains('insulin') || lower.contains('chích')) {
      return Icons.vaccines_rounded;
    }
    return Icons.medication_rounded; // Mặc định là hộp thuốc/viên thuốc
  }

  // Phân loại tự động tông màu sắc theo tên thuốc
  Color _getMedicationColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('siro') || lower.contains('nước') || lower.contains('dầu') || lower.contains('giọt') || lower.contains('dung dịch')) {
      return const Color(0xFF0EA5E9); // Màu xanh da trời sáng
    }
    if (lower.contains('sữa') || lower.contains('bột') || lower.contains('gói') || lower.contains('pha')) {
      return const Color(0xFFD97706); // Màu hổ phách/cam đậm
    }
    if (lower.contains('tiêm') || lower.contains('insulin') || lower.contains('chích')) {
      return const Color(0xFFEC4899); // Màu hồng/magenta
    }
    return const Color(0xFF2563EB); // Màu xanh dương đậm
  }

  // Lấy 7 ngày của trang PageView cụ thể dựa trên khoảng lệch tuần
  List<DateTime> _getDaysForPage(int pageOffset) {
    final today = DateTime.now();
    final centerDate = today.add(Duration(days: pageOffset * 7));
    return List.generate(7, (index) => centerDate.subtract(Duration(days: 3 - index)));
  }

  bool _isMedicationTaken(int scheduleId, DateTime date) {
    final s = _medicationSchedules.firstWhere((item) => item['schedule_id'] == scheduleId, orElse: () => null);
    if (s == null) return false;
    final med = s['medication'] ?? {};
    final description = med['description']?.toString() ?? '';
    if (description.contains('· dose_history:')) {
      final parts = description.split('· dose_history:');
      final jsonStr = parts[1].trim();
      try {
        final list = jsonDecode(jsonStr) as List;
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final timeStr = s['time']?.toString() ?? '';
        return list.any((item) =>
          item['date'].toString().startsWith(dateStr) &&
          item['time'] == timeStr &&
          item['taken'] == true
        );
      } catch (e) {
        print("Error parsing dose history: $e");
      }
    }
    return false;
  }

  void _toggleMedicationTaken(int scheduleId, DateTime date, String medName) async {
    final s = _medicationSchedules.firstWhere((item) => item['schedule_id'] == scheduleId, orElse: () => null);
    if (s == null) return;
    final med = s['medication'] ?? {};
    final String description = med['description']?.toString() ?? '';
    
    // Extract existing dose history
    List<dynamic> historyList = [];
    String baseDesc = description;
    if (description.contains('· dose_history:')) {
      final parts = description.split('· dose_history:');
      baseDesc = parts[0].trim();
      try {
        historyList = jsonDecode(parts[1].trim()) as List;
      } catch (_) {}
    } else if (description.isEmpty) {
      baseDesc = 'Nhóm: Khác · Tổng số viên thuốc: 30';
    }
    
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = s['time']?.toString() ?? '';
    
    // Find if already recorded
    final idx = historyList.indexWhere((item) =>
      item['date'].toString().startsWith(dateStr) &&
      item['time'] == timeStr
    );
    
    bool isTaken = true;
    if (idx >= 0) {
      final currentlyTaken = historyList[idx]['taken'] ?? false;
      isTaken = !currentlyTaken;
      historyList[idx]['taken'] = isTaken;
      historyList[idx]['takenAt'] = isTaken ? DateTime.now().toIso8601String() : null;
    } else {
      historyList.add({
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'time': timeStr,
        'taken': true,
        'takenAt': DateTime.now().toIso8601String(),
      });
    }
    
    // Construct new description
    final newDescription = '$baseDesc · dose_history: ${jsonEncode(historyList)}';
    
    // Show SnackBar immediately for good UX
    if (!isTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã hủy ghi nhận uống thuốc $medName'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã ghi nhận uống thuốc $medName!'),
              ),
            ],
          ),
        ),
      );
    }

    // Save to backend
    final ok = await ApiService.updateMedication(
      scheduleId: scheduleId,
      name: med['name'] ?? '',
      dosage: med['dosage'] ?? '',
      instruction: med['instruction'] ?? '',
      time: s['time'] ?? '',
      frequency: s['frequency'] ?? '',
      description: newDescription,
      startDate: s['start_date'] ?? '',
      endDate: s['end_date'] ?? '',
    );
    
    if (ok) {
      _loadMedications();
    }
  }

  // Gom nhóm thuốc theo thời gian
  Map<String, List<dynamic>> _groupSchedulesByTime() {
    final Map<String, List<dynamic>> grouped = {};
    for (var schedule in _medicationSchedules) {
      final String time = schedule['time'] ?? '00:00';
      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }
      grouped[time]!.add(schedule);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    final Map<String, List<dynamic>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    return sortedGrouped;
  }

  // ── Kích hoạt gọi khẩn cấp (Giữ nguyên để tương thích ngược nếu cần gọi) ───
  void _triggerEmergencyCall() {
    int countdown = 5;
    bool isCancelled = false;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!context.mounted || isCancelled) {
                t.cancel();
                return;
              }
              if (countdown > 1) {
                setStateModal(() {
                  countdown--;
                });
              } else {
                t.cancel();
                Navigator.pop(ctx);
                _executeEmergencyCall();
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: const Color(0xFFFFF1F2),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'GỌI KHẨN CẤP',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Hệ thống đang chuẩn bị gọi điện cho người thân của bác...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF991B1B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: countdown / 5.0,
                          color: const Color(0xFFDC2626),
                          backgroundColor: const Color(0xFFFECACA),
                          strokeWidth: 8,
                        ),
                      ),
                      Text(
                        '$countdown',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vị trí GPS của bác đã được gửi tự động.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F1D1D),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      isCancelled = true;
                      timer?.cancel();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF64748B),
                          content: Text('Đã hủy cuộc gọi khẩn cấp.'),
                        ),
                      );
                    },
                    child: const Text(
                      'HỦY CUỘC GỌI NGAY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _executeEmergencyCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFDC2626),
        content: Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đang thực hiện cuộc gọi khẩn cấp cho con gái...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isSelectedToday = _getDateKey(_selectedDate) == _getDateKey(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB), // Nền xanh biển nhạt
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ElderlyChatScreen()),
          );
        },
        icon: const Icon(Icons.support_agent_rounded, size: 24),
        label: const Text(
          'Trợ lý ảo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Container(
        color: const Color(0xFFF0F4FB),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Khu vực Header và Lịch tuần có nền màu xanh gradient giống phần cá nhân
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)], // Dải màu xanh giống phần cá nhân
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x220284C7),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildCalendarRow(),
                    _buildGoToTodayButton(isSelectedToday),
                    SizedBox(height: isSelectedToday && _currentCalendarPage == 1000 ? 8 : 16),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Khu vực hiển thị danh sách lịch uống thuốc
              _buildMedicationList(),
              const SizedBox(height: 100), // Để khoảng trống cho BottomNavigationBar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _formatHeaderDate(_selectedDate),
              style: const TextStyle(
                fontSize: 24, // Điều chỉnh size hài hòa tránh tràn viền
                fontWeight: FontWeight.bold,
                color: Colors.white, // Chữ trắng nổi bật trên nền xanh
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Test Form Nhắc Nhở
              IconButton(
                icon: const Icon(Icons.notifications_active, size: 26),
                color: Colors.white,
                onPressed: () {
                  if (_medicationSchedules.isNotEmpty) {
                    _showMedicineReminderDialog(_medicationSchedules.first);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bác chưa có lịch uống thuốc nào để test!')),
                    );
                  }
                },
              ),

              // Nút Hộp thư (Inbox) đi kèm chấm thông báo đỏ
              IconButton(
                onPressed: () {
                  MainNavigator.of(context)?.setTab(2); // Đi đến tab Thông báo
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 26),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly Calendar Slider (Lịch tuần PageView, chữ trắng trên nền xanh) ───
  Widget _buildCalendarRow() {
    return SizedBox(
      height: 90,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentCalendarPage = page;
          });
        },
        itemBuilder: (context, index) {
          final pageOffset = index - 1000;
          final days = _getDaysForPage(pageOffset);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final isSelected = _getDateKey(day) == _getDateKey(_selectedDate);
                final isToday = _getDateKey(day) == _getDateKey(DateTime.now());
                final weekdayStr = _getVietnameseWeekday(day);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  child: Container(
                    width: 44, // Cố định chiều rộng phần tử để căn chỉnh đều
                    color: Colors.transparent, // Tăng vùng chạm
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayStr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? Colors.white
                                : Colors.white70, // Chữ mờ hơn khi chưa chọn
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? Colors.white // Nền tròn màu trắng khi được chọn
                                : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: Colors.white, // Viền trắng cho ngày hôm nay khi chưa chọn
                                    width: 2,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF0284C7) // Màu xanh chủ đạo khi chọn
                                  : Colors.white, // Chữ màu trắng
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  // ── Nút "Quay lại hôm nay" (Dạng nút kính mờ - Glassmorphism trên nền xanh) ───
  Widget _buildGoToTodayButton(bool isSelectedToday) {
    final isPageToday = _currentCalendarPage == 1000;
    final isTodaySelectedAndOnCorrectPage = isSelectedToday && isPageToday;

    if (isTodaySelectedAndOnCorrectPage) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
              _pageController?.animateToPage(
                1000,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2), // Nền mờ kính
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
              ),
            ),
            child: const Text(
              'Quay lại hôm nay',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Danh sách lịch thuốc thiết kế theo hình ảnh yêu cầu (Gọn gàng, không có timeline dài) ───
  Widget _buildMedicationList() {
    if (_isLoadingMedications) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_medicationSchedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.medication_liquid_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Bác không có lịch uống thuốc nào.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Phân chia danh sách thuốc theo 3 buổi: Sáng, Trưa/Chiều, Tối
    final Map<String, List<dynamic>> sessionSchedules = {
      'Buổi sáng': [],
      'Buổi trưa': [],
      'Buổi chiều/tối': [],
      'Khác': [],
    };

    for (var schedule in _medicationSchedules) {
      // Logic lọc theo ngày bắt đầu và kết thúc
      final startDateStr = schedule['start_date'];
      final endDateStr = schedule['end_date'];
      DateTime? startDate;
      DateTime? endDate;
      try {
        if (startDateStr != null) startDate = DateTime.parse(startDateStr);
        if (endDateStr != null) endDate = DateTime.parse(endDateStr);
      } catch (_) {}

      final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        if (selectedDateOnly.isBefore(start)) continue; // Bỏ qua nếu chọn ngày trước ngày bắt đầu
      }
      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        if (selectedDateOnly.isAfter(end)) continue; // Bỏ qua nếu chọn ngày sau ngày kết thúc
      }

      final String time = schedule['time'] ?? '00:00';
      final session = _getMedicationSession(time);
      if (sessionSchedules.containsKey(session)) {
        sessionSchedules[session]!.add(schedule);
      } else {
        sessionSchedules['Khác']!.add(schedule);
      }
    }

    final filteredGroups = sessionSchedules.entries.where((e) {
      if (e.value.isEmpty) return false;
      if (_selectedMedFilter == 'Tất cả') return true;
      if (_selectedMedFilter == 'Sáng') return e.key == 'Buổi sáng';
      if (_selectedMedFilter == 'Trưa') return e.key == 'Buổi trưa';
      if (_selectedMedFilter == 'Chiều/Tối') return e.key == 'Buổi chiều/tối';
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs Lọc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab('Tất cả', _medicationSchedules.length),
                _buildFilterTab('Sáng', sessionSchedules['Buổi sáng']!.length),
                _buildFilterTab('Trưa', sessionSchedules['Buổi trưa']!.length),
                _buildFilterTab('Chiều/Tối', sessionSchedules['Buổi chiều/tối']!.length),
              ],
            ),
          ),
        ),
        
        if (filteredGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Center(
              child: Text(
                'Bác không có lịch uống thuốc nào trong khoảng thời gian này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ...filteredGroups.map((groupEntry) {
            final activeSession = groupEntry.key;
            final schedules = groupEntry.value;

            // Xác định icon và màu sắc cho buổi hoạt động
            IconData sessionIcon;
            Color sessionColor;
            if (activeSession == 'Buổi sáng') {
              sessionIcon = Icons.wb_sunny_rounded;
              sessionColor = const Color(0xFFD97706); // Màu hổ phách/cam đậm
            } else if (activeSession == 'Buổi trưa') {
              sessionIcon = Icons.wb_cloudy_rounded;
              sessionColor = const Color(0xFF0EA5E9); // Màu xanh da trời
            } else {
              sessionIcon = Icons.nights_stay_rounded;
              sessionColor = const Color(0xFF4F46E5); // Màu chàm/tối
            }

            // Nhóm các thuốc trong buổi theo giờ uống cụ thể
            final Map<String, List<dynamic>> groupedByTime = {};
            for (var schedule in schedules) {
              final String time = schedule['time'] ?? '00:00';
              if (!groupedByTime.containsKey(time)) {
                groupedByTime[time] = [];
              }
              groupedByTime[time]!.add(schedule);
            }
            final sortedTimes = groupedByTime.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header của buổi hiện tại (Hiển thị tên buổi và SỐ LƯỢNG LIST THUỐC)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sessionColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sessionColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sessionColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(sessionIcon, color: sessionColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activeSession,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: sessionColor,
                            ),
                          ),
                        ),
                        // HIỆN SỐ LƯỢNG LIST THUỐC
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sessionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${schedules.length} thuốc',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: sessionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Danh sách thuốc
                if (schedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: Center(
                      child: Text(
                        'Bác không có lịch uống thuốc nào trong $activeSession.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  ...sortedTimes.map((time) {
            final List<dynamic> schedulesAtTime = groupedByTime[time]!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: List.generate(schedulesAtTime.length, (idx) {
                        final schedule = schedulesAtTime[idx];
                        final med = schedule['medication'] ?? {};
                        final int id = schedule['schedule_id'];
                        final String name = med['name'] ?? 'Không rõ tên';
                        final String dosage = med['dosage'] ?? 'Không rõ';
                        final String instruction = med['instruction'] ?? 'Không rõ';
                        final String frequency = schedule['frequency'] ?? 'Chưa rõ';
                        final String startDate = _formatDate(schedule['start_date']);
                        final String endDate = _formatDate(schedule['end_date']);
                        final String? description = med['description'];
                        
                        String? remainingValue;
                        String cleanDescription = description ?? '';
                        if (cleanDescription.contains('· dose_history:')) {
                          cleanDescription = cleanDescription.split('· dose_history:')[0].trim();
                        }
                        if (cleanDescription.contains('Còn lại:') || cleanDescription.contains('Tổng số viên thuốc:')) {
                          final regExp = RegExp(r'^(.*?)\s*·?\s*(?:Còn lại|Tổng số viên thuốc):\s*([^·]+)(.*)$');
                          final match = regExp.firstMatch(cleanDescription);
                          if (match != null) {
                            cleanDescription = '${match.group(1) ?? ''}${match.group(3) ?? ''}'.trim();
                            cleanDescription = cleanDescription
                                .replaceAll(RegExp(r'^·\s*|\s*·$'), '')
                                .trim();
                            remainingValue = match.group(2)?.trim();
                          }
                        }
                        
                        final isTaken = _isMedicationTaken(id, _selectedDate);
                        final medIcon = _getMedicationIcon(name);
                        final medColor = _getMedicationColor(name);
                        
                        return InkWell(
                          onTap: () {
                            _showConfirmationDialog(id, name, time, isTaken);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isTaken 
                                            ? const Color(0xFFE8F5E9) 
                                            : medColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        medIcon,
                                        color: isTaken 
                                            ? const Color(0xFF10B981) 
                                            : medColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isTaken 
                                                  ? Colors.grey.shade400 
                                                  : const Color(0xFF1E293B),
                                              decoration: isTaken 
                                                  ? TextDecoration.lineThrough 
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.inventory_2_rounded,
                                                size: 16,
                                                color: isTaken ? Colors.grey.shade400 : medColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Tổng số viên thuốc: ${remainingValue ?? "Chưa cập nhật"}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isTaken ? Colors.grey.shade400 : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              _buildMiniBadge(context, Icons.vaccines_rounded, dosage, medColor, isTaken),
                                              _buildMiniBadge(context, Icons.repeat_rounded, frequency, medColor, isTaken),
                                              _buildMiniBadge(context, Icons.restaurant_rounded, instruction, medColor, isTaken),
                                              if (startDate.isNotEmpty)
                                                _buildMiniBadge(
                                                  context,
                                                  Icons.date_range_rounded, 
                                                  '${startDate.substring(0, 5)} - ${endDate.substring(0, 5)}', 
                                                  medColor, 
                                                  isTaken
                                                ),
                                            ],
                                          ),
                                          if (cleanDescription.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.notes_rounded, 
                                                  size: 13, 
                                                  color: isTaken ? Colors.grey.shade400 : Colors.grey.shade500
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    cleanDescription,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontStyle: FontStyle.italic,
                                                      color: isTaken 
                                                          ? Colors.grey.shade400 
                                                          : const Color(0xFF64748B),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isTaken 
                                          ? Icons.check_circle_rounded 
                                          : Icons.circle_outlined,
                                      color: isTaken 
                                          ? const Color(0xFF10B981) 
                                          : const Color(0xFFCBD5E1),
                                      size: 26,
                                    ),
                                  ],
                                ),
                              ),
                              if (idx < schedulesAtTime.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 76,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final isSelected = _selectedMedFilter == label;
    final color = isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF64748B);
    final bgColor = isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
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

  // Widget xây dựng Badge nhỏ gọn cho thông tin thuốc trên thẻ
  Widget _buildMiniBadge(BuildContext context, IconData icon, String text, Color color, bool isTaken) {
    final Color badgeBg = isTaken ? const Color(0xFFF1F5F9) : color.withOpacity(0.08);
    final Color badgeText = isTaken ? Colors.grey.shade400 : color;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 110),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTaken ? Colors.grey.shade200 : color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: badgeText),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: badgeText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mở BottomSheet Xác nhận Đã uống / Chưa uống thuốc đẹp mắt
  void _showConfirmationDialog(int scheduleId, String name, String time, bool isTaken) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding > 0 ? bottomPadding + 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isTaken 
                      ? const Color(0xFFFEE2E2) 
                      : const Color(0xFFD1FAE5), 
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.remove_circle_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isTaken ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isTaken ? 'Hủy Ghi Nhận Uống Thuốc' : 'Xác Nhận Uống Thuốc',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.4),
                  children: [
                    TextSpan(text: isTaken ? 'Bác muốn hủy ghi nhận đã uống thuốc ' : 'Bác đã uống thuốc '),
                    TextSpan(
                      text: name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    TextSpan(text: ' lúc '),
                    TextSpan(
                      text: time,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const TextSpan(text: ' chưa?'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Chưa, quay lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isTaken ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleMedicationTaken(scheduleId, _selectedDate, name);
                      },
                      child: Text(
                        isTaken ? 'Đúng, hủy ghi nhận' : 'Đã uống',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _noteBox(IconData icon, String label, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      // ignore
    }
    return dateStr;
  }
}

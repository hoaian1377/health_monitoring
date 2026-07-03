import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';
import '../../utils/global_state.dart';
import 'elderly_appointment_screen.dart';

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

  // Chỉ số sức khoẻ (giữ lại để tránh lỗi biên dịch)
  String _bpSys = '--';
  String _bpDia = '--';
  String _heartRate = '--';
  String _bloodSugar = '--';

  bool _isAppointmentNear = true;
  bool _isDocChecklistExpanded = true;

  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  late AnimationController _pulseController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Trạng thái ngày được chọn
  DateTime _selectedDate = DateTime.now();

  // Lịch tuần cuộn ngang theo trang (PageView) để cố định 1 tuần trên màn hình
  PageController? _pageController;
  int _currentCalendarPage = 1000;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    // Khởi tạo PageController với trang mặc định là 1000 đại diện cho tuần này
    _pageController = PageController(initialPage: 1000);
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoadingMedications = true);
    final accountId = ApiService.currentAccountId ?? 0;
    
    // Load medications
    final schedules = await ApiService.getElderlyMedicationSchedule(accountId);
    
    // Load health metrics
    final data = await ApiService.getHealthMetrics(accountId);
    
    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;
        
        if (data.isNotEmpty) {
          final latest = data[0];
          if (latest['heart_rate'] != null) {
            _heartRate = latest['heart_rate'].toString();
          }
          if (latest['blood_pressure'] != null) {
            final bp = latest['blood_pressure'].toString().split('/');
            if (bp.length == 2) {
              _bpSys = bp[0];
              _bpDia = bp[1];
            }
          }
          if (latest['blood_sugar'] != null) {
            _bloodSugar = latest['blood_sugar'].toString();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    _pageController?.dispose();
    super.dispose();
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
    return globalState.isScheduleTaken(scheduleId, date);
  }

  void _toggleMedicationTaken(int scheduleId, DateTime date, String medName) {
    setState(() {
      globalState.toggleScheduleTaken(scheduleId, date);
    });

    final isTaken = globalState.isScheduleTaken(scheduleId, date);

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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Khu vực hiển thị danh sách lịch uống thuốc
              _buildMedicationList(),
              const SizedBox(height: 100), // Để khoảng trống cho BottomNavigationBar
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (Tiêu đề ngày có Năm + nút chức năng, chữ trắng tương phản tốt) ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatHeaderDate(_selectedDate),
            style: const TextStyle(
              fontSize: 30, // Điều chỉnh size hài hòa
              fontWeight: FontWeight.bold,
              color: Colors.white, // Chữ trắng nổi bật trên nền xanh
            ),
          ),
          Row(
            children: [
              // Nút Lịch khám bệnh
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined, size: 28),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ElderlyAppointmentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Nút Hộp thư (Inbox) đi kèm chấm thông báo đỏ
              IconButton(
                onPressed: () {
                  MainNavigator.of(context)?.setTab(2); // Đi đến tab Thông báo
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 28),
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

    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isTodaySelectedAndOnCorrectPage ? 0.0 : 1.0,
        child: isTodaySelectedAndOnCorrectPage
            ? const SizedBox.shrink()
            : Container(
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

    final grouped = _groupSchedulesByTime();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final String time = grouped.keys.elementAt(index);
        final List<dynamic> schedules = grouped[time]!;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề mốc giờ uống thuốc (Ví dụ: 08:00) nằm ngoài thẻ giống hình vẽ
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
              // Thẻ trắng chứa các thuốc của khung giờ đó
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
                  children: List.generate(schedules.length, (idx) {
                    final schedule = schedules[idx];
                    final med = schedule['medication'] ?? {};
                    final int id = schedule['schedule_id'];
                    final String name = med['name'] ?? 'Không rõ tên';
                    final String subtitle = _buildMedicationSubtitle(med);
                    final isTaken = _isMedicationTaken(id, _selectedDate);
                    
                    final medIcon = _getMedicationIcon(name);
                    final medColor = _getMedicationColor(name);
                    
                    return InkWell(
                      onTap: () {
                        _toggleMedicationTaken(id, _selectedDate, name);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Biểu tượng hình tròn bên trái
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
                                // Tên thuốc và thông tin cách dùng/liều lượng
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isTaken 
                                              ? Colors.grey.shade400 
                                              : const Color(0xFF1E293B),
                                          decoration: isTaken 
                                              ? TextDecoration.lineThrough 
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: isTaken 
                                              ? Colors.grey.shade400 
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Biểu tượng tích chọn hoặc vòng tròn rỗng góc phải để đồng bộ
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
                          // Đường phân cách giữa các dòng thuốc trong cùng một thẻ
                          if (idx < schedules.length - 1)
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
      },
    );
  }
}

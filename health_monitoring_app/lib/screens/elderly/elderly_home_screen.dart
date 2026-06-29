import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';
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

  bool _isAppointmentNear =
      true; // Hiển thị mặc định vì có lịch khám sau 3 ngày
  bool _isDocChecklistExpanded = true; // Mặc định mở checklist giấy tờ

  // Checkbox giấy tờ chuẩn bị đi khám
  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  // Animation controller cho nút SOS đập nhẹ (pulse effect)
  late AnimationController _pulseController;

  // Timer cập nhật theo giờ — tự động mở khóa từng liều thuốc khi đến giờ
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Cập nhật giờ mỗi phút — tự động hiện liều thuốc khi đến giờ
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoadingMedications = true);
    final schedules = await ApiService.getElderlyMedicationSchedule(
      ApiService.currentAccountId ?? 0,
    );
    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Lấy lời chào theo thời gian trong ngày ───────────────────────────────
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng bác,';
    } else if (hour >= 11 && hour < 14) {
      return 'Chúc bác nghỉ trưa vui vẻ,';
    } else if (hour >= 14 && hour < 18) {
      return 'Chào buổi chiều bác,';
    } else {
      return 'Chúc bác buổi tối an lành,';
    }
  }

  // ── Lấy ngày tiếng Việt ──────────────────────────────────────────────────
  String _getVietnameseDate() {
    final now = DateTime.now();
    final weekdays = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    final weekday = weekdays[now.weekday % 7];
    return '$weekday, ngày ${now.day} tháng ${now.month}';
  }

  // ── Kích hoạt gọi khẩn cấp (có đếm ngược 5s để hủy nếu bấm nhầm) ───────────
  void _triggerEmergencyCall() {
    int countdown = 5;
    bool isCancelled = false;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc chọn Hủy để đóng
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
    int preparedCount =
        (_isCCCDPrepared ? 1 : 0) +
        (_isBHYTPrepared ? 1 : 0) +
        (_isSoKhamPrepared ? 1 : 0) +
        (_isDonThuocPrepared ? 1 : 0) +
        (_isXetNghiemPrepared ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF0F4FB,
      ), // Màu nền xanh biển nhạt, dễ chịu
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 16),
                  _buildMedCard(),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(preparedCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (Lời chào thời gian thực + SOS nổi bật) ─────────────────────────
  Widget _buildHeader() {
    final name = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF38BDF8),
          ], // Tông màu xanh biển nhạt, dịu mắt
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x220284C7),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: const TextStyle(
                        fontSize: 16.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bác $name',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getVietnameseDate(),
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Nút SOS Nhấp nháy nhẹ nhàng thu hút chú ý
            ],
          ),
          const SizedBox(height: 20),
          // Banner nhắc nhở sức khỏe (Soft Glassmorphism)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Text('💧', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bác nhớ uống đủ 2 lít nước ngày hôm nay để khỏe mạnh nhé!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Bar (Hiển thị các chỉ số gần nhất cho người già yên tâm) ───
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Huyết áp',
            '120/80',
            'mmHg',
            const Color(0xFF0284C7),
            Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'Đường huyết',
            '5.8',
            'mmol/L',
            const Color(0xFF059669),
            Icons.water_drop_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'Nhịp tim',
            '72',
            'l/phút',
            const Color(0xFFE11D48),
            Icons.monitor_heart_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF1E293B)),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '\n$unit',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTimeOfDayInfo(String timeStr, bool isTaken) {
    if (isTaken) {
      return {
        'period': 'Đã hoàn thành',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF059669),
        'bgColor': const Color(0xFFECFDF5),
        'gradient': const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      };
    }
    try {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        final hour = int.parse(parts[0]);
        if (hour >= 5 && hour < 11) {
          return {
            'period': 'Buổi sáng',
            'icon': Icons.light_mode_rounded,
            'color': const Color(0xFFEA580C),
            'bgColor': const Color(0xFFFFF7ED),
            'gradient': const [Color(0xFFFFFAF2), Color(0xFFFFF1E0)],
          };
        } else if (hour >= 11 && hour < 17) {
          return {
            'period': 'Buổi trưa',
            'icon': Icons.wb_sunny_rounded,
            'color': const Color(0xFF0284C7),
            'bgColor': const Color(0xFFF0F9FF),
            'gradient': const [Color(0xFFF6FBFF), Color(0xFFE0F2FE)],
          };
        } else {
          return {
            'period': 'Buổi tối',
            'icon': Icons.dark_mode_rounded,
            'color': const Color(0xFF4F46E5),
            'bgColor': const Color(0xFFEEF2FF),
            'gradient': const [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
          };
        }
      }
    } catch (_) {}
    return {
      'period': 'Lịch uống',
      'icon': Icons.access_time_rounded,
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFF4FAF9),
      'gradient': const [Color(0xFFFFFFFF), Color(0xFFF4FAF9)],
    };
  }

  // Kiểm tra xem thời gian lịch uống thuốc đã đến chưa (so với _now, tự cập nhật mỗi phút)
  bool _isScheduleTimeDue(String timeStr) {
    // Trả về true để mô phỏng tất cả các lịch uống thuốc đều đã đến giờ, giúp hiển thị giao diện xem thử.
    return true;
  }

  // ── Thẻ nhắc uống thuốc (Horizontal Carousel trực quan & dễ hiểu) ───────────────────
  Widget _buildMedCard() {
    final total = _medicationSchedules.length;

    // Chỉ lấy những liều đã đến giờ
    final dueSchedules = _medicationSchedules
        .where((s) => _isScheduleTimeDue(s['time'] ?? ''))
        .toList();

    final int due = dueSchedules.length;
    final int taken = dueSchedules
        .where((s) => _takenScheduleIds.contains(s['schedule_id']))
        .length;
    final double progress = due > 0 ? (taken / due) : 0;
    final bool allDone = due > 0 && taken >= due;
    final bool hasUpcoming =
        dueSchedules.length < total; // Có liều sắp tới chưa đến giờ

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: allDone ? const Color(0xFFA7F3D0) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Tiến trình số
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: allDone
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allDone
                      ? Icons.check_circle_rounded
                      : Icons.medication_rounded,
                  color: allDone
                      ? const Color(0xFF059669)
                      : const Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Uống thuốc hôm nay',
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (due > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: allDone
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$taken/$due liều',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: allDone
                          ? const Color(0xFF059669)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Thanh tiến trình
          if (due > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? const Color(0xFF059669) : const Color(0xFF0EA5E9),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Lịch trình thời gian uống thuốc trong ngày
          const Text(
            'Lịch trình uống thuốc ngày:',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingMedications)
            const Center(child: CircularProgressIndicator())
          else if (_medicationSchedules.isEmpty)
            // Không có lịch uống thuốc nào hôm nay
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Color(0xFF94A3B8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Hôm nay bác không có lịch uống thuốc.",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (dueSchedules.isEmpty)
            // Có lịch nhưng chưa đến giờ nào cả
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF0284C7),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Chưa đến giờ uống thuốc.",
                    style: TextStyle(
                      color: Color(0xFF0369A1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Liều đầu tiên lúc ${_medicationSchedules.first['time'] ?? '--:--'}',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: dueSchedules.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final schedule = dueSchedules[index];
                  final med = schedule['medication'] ?? {};
                  final id = schedule['schedule_id'];
                  final isTaken = _takenScheduleIds.contains(id);
                  final time = schedule['time'] ?? '--:--';

                  final info = _getTimeOfDayInfo(time, isTaken);
                  final Color themeColor = info['color'];
                  final List<Color> gradient = info['gradient'];
                  final IconData periodIcon = info['icon'];
                  final String periodText = info['period'];

                  return Container(
                    width: 230,
                    margin: const EdgeInsets.only(
                      bottom: 6,
                      top: 2,
                    ), // space for shadow
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTaken
                            ? const Color(0xFFA7F3D0)
                            : themeColor.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header: Buổi + Thời gian
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(periodIcon, size: 14, color: themeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    periodText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),

                        // Thân: Tên thuốc + Liều lượng
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'] ?? 'Không rõ tên',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    med['dosage'] ?? '1 liều',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Nút bấm xác nhận hoặc Trạng thái đã uống
                        if (isTaken)
                          Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF059669),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Đã uống',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                setState(() {
                                  _takenScheduleIds.add(id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF059669),
                                    duration: const Duration(seconds: 2),
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Đã ghi nhận uống ${med['name']}!',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Xác nhận đã uống',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Gợi ý liều sắp tới nếu vẫn còn liều chưa đến giờ
          if (!_isLoadingMedications && hasUpcoming) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFF0284C7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Còn ${total - dueSchedules.length} liều nữa sẽ đến hôm nay',
                      style: const TextStyle(
                        color: Color(0xFF0369A1),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => MainNavigator.of(context)?.setTab(1),
              child: const Text(
                'Xem toàn bộ lịch uống thuốc',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Lịch khám (Gồm Checklist giấy tờ mang đi khám tích hợp bên dưới) ───
  Widget _buildAppointmentCard(int preparedCount) {
    final bool isAllPrepared = preparedCount == 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề lịch khám
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lịch khám sắp tới',
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Còn 3 ngày',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Chi tiết lịch khám
          const Text(
            'Bệnh viện Chợ Rẫy',
            style: TextStyle(
              fontSize: 19.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'BS. Nguyễn Thị Lan  ·  Khoa Tim mạch',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Thời gian nổi bật
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 10),
                Text(
                  '08:30  ·  Thứ Sáu, 12/06/2026',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nút xem chi tiết chính lịch khám
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0EA5E9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ElderlyAppointmentScreen(),
                  ),
                );
              },
              child: const Text(
                'Xem chi tiết lịch khám bệnh',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const Divider(height: 32, thickness: 1),
          // ── PHẦN CHUẨN BỊ GIẤY TỜ TÍCH HỢP (Collapsible) ──
          if (_isAppointmentNear) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _isDocChecklistExpanded = !_isDocChecklistExpanded;
                });
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bác cần chuẩn bị giấy tờ gì?',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Icon(
                    _isDocChecklistExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_isDocChecklistExpanded) ...[
              const SizedBox(height: 12),
              const Text(
                'Hãy tích chọn vào ô bên dưới khi bác bỏ giấy tờ vào cặp mang đi khám nhé:',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckItem(
                'Căn cước công dân (CCCD)',
                _isCCCDPrepared,
                (v) => setState(() {
                  _isCCCDPrepared = v ?? false;
                }),
              ),
              _buildCheckItem(
                'Thẻ Bảo hiểm Y tế (BHYT)',
                _isBHYTPrepared,
                (v) => setState(() {
                  _isBHYTPrepared = v ?? false;
                }),
              ),
              _buildCheckItem(
                'Sổ khám bệnh cũ',
                _isSoKhamPrepared,
                (v) => setState(() {
                  _isSoKhamPrepared = v ?? false;
                }),
              ),
              _buildCheckItem(
                'Đơn thuốc đang sử dụng',
                _isDonThuocPrepared,
                (v) => setState(() {
                  _isDonThuocPrepared = v ?? false;
                }),
              ),
              _buildCheckItem(
                'Kết quả xét nghiệm, X-Quang mới',
                _isXetNghiemPrepared,
                (v) => setState(() {
                  _isXetNghiemPrepared = v ?? false;
                }),
              ),
              if (isAllPrepared) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bác đã chuẩn bị đầy đủ giấy tờ khám! Thật tuyệt vời.',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // Checkbox tùy chỉnh to, rõ ràng, nhấp nhạy tốt
  Widget _buildCheckItem(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value
                      ? const Color(0xFF10B981)
                      : const Color(0xFFCBD5E1),
                  width: 2.2,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w600,
                  color: value ? Colors.grey : const Color(0xFF1E293B),
                  decoration: value ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

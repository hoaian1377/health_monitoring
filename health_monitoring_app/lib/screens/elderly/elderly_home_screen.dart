import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';
import '../appointment_screen.dart';

class ElderlyHomeScreen extends StatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  State<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends State<ElderlyHomeScreen> with SingleTickerProviderStateMixin {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  List<dynamic> _medicationSchedules = [];
  bool _isLoadingMedications = true;
  Set<int> _takenScheduleIds = {};
  
  bool _isAppointmentNear = true; // Hiển thị mặc định vì có lịch khám sau 3 ngày
  bool _isDocChecklistExpanded = true; // Mặc định mở checklist giấy tờ

  // Checkbox giấy tờ chuẩn bị đi khám
  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  // Animation controller cho nút SOS đập nhẹ (pulse effect)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoadingMedications = true);
    final schedules = await ApiService.getElderlyMedicationSchedule(ApiService.currentAccountId ?? 0);
    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;
      });
    }
  }

  @override
  void dispose() {
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
      'Thứ Bảy'
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: const Color(0xFFFFF1F2),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 32),
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
                    style: TextStyle(fontSize: 16, color: Color(0xFF991B1B), height: 1.4),
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
                    style: TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), fontStyle: FontStyle.italic),
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
                      side: const BorderSide(color: Color(0xFFDC2626), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    int preparedCount = (_isCCCDPrepared ? 1 : 0) +
        (_isBHYTPrepared ? 1 : 0) +
        (_isSoKhamPrepared ? 1 : 0) +
        (_isDonThuocPrepared ? 1 : 0) +
        (_isXetNghiemPrepared ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA), // Màu nền nhẹ nhàng, dễ chịu
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
          colors: [Color(0xFF0F605A), Color(0xFF1B8E85)], // Tông màu Teal y khoa sang trọng, dịu mắt
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x220F605A),
            blurRadius: 18,
            offset: Offset(0, 10),
          )
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
                      'Bác $name 👋',
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
              GestureDetector(
                onTap: _triggerEmergencyCall,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(
                                  alpha: 0.3 * _pulseController.value,
                                ),
                                blurRadius: 12 * _pulseController.value,
                                spreadRadius: 4 * _pulseController.value,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'CẤP CỨU SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
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
                Text(
                  '💧',
                  style: TextStyle(fontSize: 20),
                ),
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

  Widget _buildStatItem(String label, String value, String unit, Color color, IconData icon) {
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
          )
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
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF1E293B)),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '\n$unit',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ nhắc uống thuốc (Timeline trực quan & dễ hiểu) ───────────────────
  Widget _buildMedCard() {
    final total = _medicationSchedules.length;
    final int taken = _takenScheduleIds.length;
    final double progress = total > 0 ? (taken / total) : 0;
    final bool allDone = total > 0 && taken >= total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: allDone ? const Color(0xFFA7F3D0) : Colors.grey.shade100, width: 1.5),
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
                  color: allDone ? const Color(0xFFD1FAE5) : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allDone ? Icons.check_circle_rounded : Icons.medication_rounded,
                  color: allDone ? const Color(0xFF059669) : const Color(0xFF0284C7),
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
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allDone ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$taken/$total liều',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: allDone ? const Color(0xFF059669) : const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Thanh tiến trình
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? const Color(0xFF059669) : const Color(0xFF14B8A6),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Lịch trình thời gian uống thuốc trong ngày
          const Text(
            'Lịch trình uống thuốc ngày:',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingMedications)
            const Center(child: CircularProgressIndicator())
          else if (_medicationSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("Hôm nay bác không có lịch uống thuốc.", style: TextStyle(color: Colors.grey, fontSize: 16))),
            )
          else
            ..._medicationSchedules.map((schedule) {
              final med = schedule['medication'] ?? {};
              final id = schedule['schedule_id'];
              final isTaken = _takenScheduleIds.contains(id);
              return Column(
                children: [
                  _buildTimelineRow(
                    schedule['time'] ?? '--:--',
                    '${med['name']} · ${med['dosage']}',
                    isTaken ? 'Đã uống' : 'Chưa uống',
                    isTaken ? const Color(0xFF059669) : const Color(0xFFD97706),
                    isTaken ? Icons.check_circle_rounded : Icons.pending_rounded,
                  ),
                  const SizedBox(height: 8),
                  if (!isTaken)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          setState(() {
                            _takenScheduleIds.add(id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF059669),
                              duration: Duration(seconds: 2),
                              content: Text('✓ Đã ghi nhận uống thuốc!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Xác nhận đã uống', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => MainNavigator.of(context)?.setTab(1),
              child: const Text(
                'Xem toàn bộ việc cần làm hôm nay',
                style: TextStyle(
                  color: Color(0xFF0F605A),
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

  Widget _buildTimelineRow(
    String time,
    String detail,
    String statusText,
    Color statusColor,
    IconData icon, {
    bool isNext = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Thời gian
          SizedBox(
            width: 88,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                color: isNext ? const Color(0xFF1E293B) : Colors.grey,
              ),
            ),
          ),
          // Biểu tượng trạng thái
          Icon(
            icon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 14),
          // Chi tiết & trạng thái chữ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    color: isNext ? const Color(0xFF1E293B) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
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
          )
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            style: TextStyle(fontSize: 19.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'BS. Nguyễn Thị Lan  ·  Khoa Tim mạch',
            style: TextStyle(fontSize: 16, color: Color(0xFF475569), fontWeight: FontWeight.w500),
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
                Icon(Icons.access_time_filled_rounded, size: 20, color: Color(0xFFD97706)),
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
                side: const BorderSide(color: Color(0xFF14B8A6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentScreen()),
                );
              },
              child: const Text(
                'Xem chi tiết lịch khám bệnh',
                style: TextStyle(color: Color(0xFF0F605A), fontWeight: FontWeight.bold, fontSize: 15),
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
                  const Icon(Icons.assignment_rounded, color: Color(0xFF14B8A6), size: 22),
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
                    _isDocChecklistExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_isDocChecklistExpanded) ...[
              const SizedBox(height: 12),
              const Text(
                'Hãy tích chọn vào ô bên dưới khi bác bỏ giấy tờ vào cặp mang đi khám nhé:',
                style: TextStyle(fontSize: 13.5, color: Colors.grey, height: 1.3),
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
                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
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
  Widget _buildCheckItem(String label, bool value, ValueChanged<bool?> onChanged) {
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
                  color: value ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
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


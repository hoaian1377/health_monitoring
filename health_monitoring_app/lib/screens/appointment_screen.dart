import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class AppointmentItem {
  final String id;
  String hospital;
  String doctor;
  String specialty;
  DateTime date;
  String time;
  bool isCompleted;
  bool isCancelled;
  String notes;
  String result;
  String cancelReason;

  AppointmentItem({
    required this.id,
    required this.hospital,
    required this.doctor,
    required this.specialty,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.isCancelled = false,
    this.notes = '',
    this.result = '',
    this.cancelReason = '',
  });
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AppointmentItem> _appointments = [
    AppointmentItem(
      id: '1',
      hospital: 'Bệnh viện Chợ Rẫy',
      doctor: 'BS. Nguyễn Thị Lan',
      specialty: 'Tim mạch',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '08:30',
      notes: 'Tái khám huyết áp định kỳ 3 tháng',
    ),
    AppointmentItem(
      id: '2',
      hospital: 'Phòng khám đa khoa Thành Đô',
      doctor: 'BS. Trần Văn Minh',
      specialty: 'Nội tiết',
      date: DateTime.now().add(const Duration(days: 15)),
      time: '14:00',
      notes: 'Kiểm tra đường huyết định kỳ',
    ),
    AppointmentItem(
      id: '3',
      hospital: 'Bệnh viện Chợ Rẫy',
      doctor: 'BS. Nguyễn Thị Lan',
      specialty: 'Tim mạch',
      date: DateTime(2026, 3, 1),
      time: '08:30',
      isCompleted: true,
      notes: 'Tái khám huyết áp',
      result:
          'Huyết áp ổn định 125/80. Tiếp tục Amlodipine 5mg. Tái khám sau 3 tháng.',
    ),
    AppointmentItem(
      id: '4',
      hospital: 'Phòng khám đa khoa Thành Đô',
      doctor: 'BS. Trần Văn Minh',
      specialty: 'Nội tiết',
      date: DateTime(2025, 11, 15),
      time: '14:00',
      isCompleted: true,
      notes: 'Kiểm tra đường huyết',
      result:
          'Đường huyết 5.8 mmol/L - bình thường. Tiếp tục Metformin 500mg. Tái khám sau 6 tháng.',
    ),
  ];

  final _hospitalCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _pickedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _pickedTime = const TimeOfDay(hour: 8, minute: 30);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hospitalCtrl.dispose();
    _doctorCtrl.dispose();
    _specialtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<AppointmentItem> get _upcoming => _appointments
      .where((a) => !a.isCompleted && !a.isCancelled)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<AppointmentItem> get _completed => _appointments
      .where((a) => a.isCompleted && !a.isCancelled)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<AppointmentItem> get _cancelled => _appointments
      .where((a) => a.isCancelled)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showAddSheet() {
    _hospitalCtrl.clear();
    _doctorCtrl.clear();
    _specialtyCtrl.clear();
    _notesCtrl.clear();
    _pickedDate = DateTime.now().add(const Duration(days: 7));
    _pickedTime = const TimeOfDay(hour: 8, minute: 30);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24 + MediaQuery.of(ctx).padding.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thêm Lịch Khám Mới',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                _field('Tên bệnh viện / phòng khám *', _hospitalCtrl,
                    Icons.local_hospital_rounded, 'VD: Bệnh viện Chợ Rẫy'),
                const SizedBox(height: 14),
                _field('Bác sĩ phụ trách', _doctorCtrl,
                    Icons.person_rounded, 'VD: BS. Nguyễn Văn A'),
                const SizedBox(height: 14),
                _field('Chuyên khoa', _specialtyCtrl,
                    Icons.medical_services_rounded,
                    'VD: Tim mạch, Nội tiết...'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _dateBox(ctx, setModal)),
                    const SizedBox(width: 12),
                    Expanded(child: _timeBox(ctx, setModal)),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Ghi chú / Lý do khám', _notesCtrl,
                    Icons.note_alt_rounded, 'VD: Tái khám định kỳ...',
                    lines: 2),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_hospitalCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Vui lòng nhập tên bệnh viện')));
                        return;
                      }
                      setState(() {
                        _appointments.add(AppointmentItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          hospital: _hospitalCtrl.text.trim(),
                          doctor: _doctorCtrl.text.trim().isEmpty
                              ? 'Chưa xác định'
                              : _doctorCtrl.text.trim(),
                          specialty: _specialtyCtrl.text.trim().isEmpty
                              ? 'Đa khoa'
                              : _specialtyCtrl.text.trim(),
                          date: _pickedDate,
                          time:
                              '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}',
                          notes: _notesCtrl.text.trim(),
                        ));
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('✓ Đã thêm lịch khám thành công!'),
                        ),
                      );
                    },
                    child: const Text('Lưu lịch khám',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      String hint,
      {int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
            filled: true,
            fillColor: const Color(0xFFF0F9FF),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateBox(BuildContext ctx, StateSetter setModal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ngày khám',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: _pickedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setModal(() => _pickedDate = d);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_fmtDate(_pickedDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeBox(BuildContext ctx, StateSetter setModal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Giờ khám',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final t =
                await showTimePicker(context: ctx, initialTime: _pickedTime);
            if (t != null) setModal(() => _pickedTime = t);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 8),
                Text(
                  '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(AppointmentItem item) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy lịch khám', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bác có chắc muốn hủy lịch khám tại ${item.hospital}?'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Lý do hủy (không bắt buộc)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                item.isCancelled = true;
                item.cancelReason = ctrl.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFEF4444),
                  content: Text('Đã hủy lịch khám'),
                ),
              );
            },
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultSheet(AppointmentItem item) {
    final ctrl = TextEditingController(text: item.result);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24 + MediaQuery.of(ctx).padding.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ghi kết quả khám',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item.hospital,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Nhập chẩn đoán, kết quả xét nghiệm, đơn thuốc mới...',
                hintStyle:
                    const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    item.result = ctrl.text.trim();
                    item.isCompleted = true;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF10B981),
                      content: Text('✓ Đã lưu kết quả khám!'),
                    ),
                  );
                },
                child: const Text('Lưu kết quả',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _upcomingTab(),
            _completedTab(),
            _cancelledTab(),
          ],
        ),
      ),
      floatingActionButton: ApiService.currentRole == 'elderly' ? null : FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm lịch khám',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x400EA5E9), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lịch Khám Bệnh',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Quản lý lịch tái khám của bác',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Sắp tới (${_upcoming.length})'),
              Tab(text: 'Đã khám (${_completed.length})'),
              Tab(text: 'Đã hủy (${_cancelled.length})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingTab() {
    if (_upcoming.isEmpty) {
      return _emptyState('Chưa có lịch khám',
          'Nhấn nút + bên dưới để thêm lịch khám mới',
          Icons.calendar_today_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _upcoming.length,
      itemBuilder: (_, i) => _upcomingCard(_upcoming[i]),
    );
  }

  Widget _completedTab() {
    if (_completed.isEmpty) {
      return _emptyState('Chưa có lịch sử khám',
          'Lịch đã khám sẽ hiển thị ở đây', Icons.history_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _completed.length,
      itemBuilder: (_, i) => _completedCard(_completed[i]),
    );
  }

  Widget _cancelledTab() {
    if (_cancelled.isEmpty) {
      return _emptyState('Chưa có lịch khám bị hủy',
          'Các lịch khám đã hủy sẽ hiển thị ở đây', Icons.cancel_presentation_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _cancelled.length,
      itemBuilder: (_, i) => _cancelledCard(_cancelled[i]),
    );
  }

  Widget _emptyState(String title, String sub, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _upcomingCard(AppointmentItem item) {
    final days = item.date.difference(DateTime.now()).inDays;
    final Color urgentColor;
    final Color urgentBg;
    final String urgentLabel;

    if (days <= 0) {
      urgentColor = const Color(0xFFEF4444);
      urgentBg = const Color(0xFFFEE2E2);
      urgentLabel = 'Hôm nay';
    } else if (days <= 3) {
      urgentColor = const Color(0xFFF59E0B);
      urgentBg = const Color(0xFFFEF3C7);
      urgentLabel = 'Còn $days ngày';
    } else {
      urgentColor = const Color(0xFF0EA5E9);
      urgentBg = const Color(0xFFEFF6FF);
      urgentLabel = 'Còn $days ngày';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: urgentBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.local_hospital_rounded,
                      color: urgentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.hospital,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('${item.doctor} · ${item.specialty}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.notes,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgentBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(urgentLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: urgentColor)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(_fmtDate(item.date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569))),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(item.time,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569))),
                const Spacer(),
                if (ApiService.currentRole != 'elderly') ...[
                  GestureDetector(
                    onTap: () => _showCancelDialog(item),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showResultSheet(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Ghi kết quả',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelledCard(AppointmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.hospital,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      Text('${item.doctor} · ${_fmtDate(item.date)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Đã hủy',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444))),
                ),
              ],
            ),
            if (item.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lý do hủy:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(item.cancelReason,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _completedCard(AppointmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.hospital,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      Text('${item.doctor} · ${_fmtDate(item.date)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Đã khám',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A))),
                ),
              ],
            ),
            if (item.result.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết quả khám:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0EA5E9))),
                    const SizedBox(height: 4),
                    Text(item.result,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                            height: 1.4)),
                  ],
                ),
              ),
            ],
            if (ApiService.currentRole != 'elderly') ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showResultSheet(item),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0EA5E9)),
                    SizedBox(width: 6),
                    Text('Chỉnh sửa kết quả',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

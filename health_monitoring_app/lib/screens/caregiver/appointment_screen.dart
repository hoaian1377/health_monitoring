import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

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
  final bool isEmbedded;
  const AppointmentScreen({super.key, this.isEmbedded = false});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<AppointmentItem> _appointments = [];
  bool _isLoading = true;

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
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final accountId = ApiService.currentRole == 'caregiver'
        ? ApiService.currentElderlyId
        : ApiService.currentAccountId;
    if (accountId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final data = await ApiService.getAppointments(accountId);
    List<AppointmentItem> loaded = [];
    for (var item in data) {
      loaded.add(AppointmentItem(
        id: item['appointmentid'].toString(),
        hospital: item['location'] ?? 'Chưa xác định',
        doctor: item['doctor_name'] ?? 'Chưa xác định',
        specialty: 'Khám bệnh',
        date: DateTime.tryParse(item['appointment_date'] ?? '') ?? DateTime.now(),
        time: item['appointment_time']?.toString().substring(0, 5) ?? '00:00',
        notes: item['note'] ?? '',
      ));
    }
    setState(() {
      _appointments = loaded;
      _isLoading = false;
    });
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
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
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
                Text(
                  'Thêm Lịch Khám Mới',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
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
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSaving ? null : () async {
                      if (_hospitalCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Vui lòng nhập tên bệnh viện')));
                        return;
                      }
                      
                      setModal(() => isSaving = true);
                      
                      final doctorName = _doctorCtrl.text.trim().isEmpty ? 'Chưa xác định' : _doctorCtrl.text.trim();
                      final location = _hospitalCtrl.text.trim();
                      final dateStr = '${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2, '0')}-${_pickedDate.day.toString().padLeft(2, '0')}';
                      final timeStr = '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}';
                      final notes = _notesCtrl.text.trim();

                      final success = await ApiService.createAppointment(
                        elderlyId: ApiService.currentElderlyId ?? 0,
                        doctorName: doctorName,
                        location: location,
                        appointmentDate: dateStr,
                        appointmentTime: timeStr,
                        note: notes,
                      );
                      
                      setModal(() => isSaving = false);

                      if (success) {
                        Navigator.pop(ctx);
                        _loadAppointments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('✓ Đã thêm lịch khám thành công!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Thêm lịch khám thất bại. Vui lòng thử lại!'),
                          ),
                        );
                      }
                    },
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Lưu lịch khám',
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

  void _showEditSheet(AppointmentItem item) {
    _hospitalCtrl.text = item.hospital;
    _doctorCtrl.text = item.doctor == 'Chưa xác định' ? '' : item.doctor;
    _specialtyCtrl.text = item.specialty;
    _notesCtrl.text = item.notes;
    _pickedDate = item.date;
    try {
      final parts = item.time.split(':');
      _pickedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      _pickedTime = const TimeOfDay(hour: 8, minute: 30);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
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
                Text(
                  'Sửa Lịch Khám',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
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
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_hospitalCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Vui lòng nhập tên bệnh viện')));
                        return;
                      }
                      
                      final doctorName = _doctorCtrl.text.trim().isEmpty ? 'Chưa xác định' : _doctorCtrl.text.trim();
                      final location = _hospitalCtrl.text.trim();
                      final dateStr = '${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2, '0')}-${_pickedDate.day.toString().padLeft(2, '0')}';
                      final timeStr = '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}';
                      final notes = _notesCtrl.text.trim();

                      final success = await ApiService.updateAppointment(
                        int.parse(item.id),
                        {
                          'doctor_name': doctorName,
                          'location': location,
                          'appointment_date': dateStr,
                          'appointment_time': timeStr,
                          'note': notes,
                        }
                      );

                      if (success) {
                        Navigator.pop(ctx);
                        _loadAppointments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('✓ Đã cập nhật lịch khám thành công!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Cập nhật thất bại. Vui lòng thử lại!'),
                          ),
                        );
                      }
                    },
                    child: const Text('Cập nhật lịch khám',
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
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFF0F9FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: lines,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: Icon(icon, color: themeColor, size: 20),
            filled: true,
            fillColor: themeBg,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: themeColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateBox(BuildContext ctx, StateSetter setModal) {
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFF0F9FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ngày khám',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B))),
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
                EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: themeBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: themeColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_fmtDate(_pickedDate),
                      style: TextStyle(
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
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFF0F9FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giờ khám',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final t =
                await showTimePicker(context: ctx, initialTime: _pickedTime);
            if (t != null) setModal(() => _pickedTime = t);
          },
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: themeBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 16, color: themeColor),
                const SizedBox(width: 8),
                Text(
                  '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
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
            Text('Bạn có chắc muốn hủy lịch khám tại ${item.hospital}?'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: TextStyle(fontSize: 14),
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
            child: Text('Đóng', style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              int appId = int.parse(item.id);
              final success = await ApiService.deleteAppointment(appId);
              if (success) {
                setState(() {
                  item.isCancelled = true;
                  item.cancelReason = ctrl.text.trim();
                });
                Navigator.pop(ctx);
                _loadAppointments();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFEF4444),
                    content: Text('Đã hủy lịch khám'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Xóa lịch khám thất bại. Vui lòng thử lại!'),
                  ),
                );
              }
            },
            child: Text('Xác nhận hủy', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResultSheet(AppointmentItem item) {
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFF0F9FF);

    final ctrl = TextEditingController(text: item.result);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
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
            Text('Ghi kết quả khám',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item.hospital,
                style: TextStyle(
                    fontSize: 13, color: const Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập chẩn đoán, kết quả xét nghiệm, đơn thuốc mới...',
                hintStyle:
                    TextStyle(color: const Color(0xFFCBD5E1), fontSize: 13),
                filled: true,
                fillColor: themeBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: themeColor, width: 1.5),
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
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  bool success = await ApiService.updateAppointment(
                    int.parse(item.id),
                    {'diagnosis': ctrl.text.trim()},
                  );
                  if (success) {
                    setState(() {
                      item.result = ctrl.text.trim();
                      item.isCompleted = true;
                    });
                    if (mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('✓ Đã lưu kết quả khám!'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Lưu thất bại, vui lòng thử lại!'),
                        ),
                      );
                    }
                  }
                },
                child: Text('Lưu kết quả',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
      floatingActionButton: FloatingActionButton.extended(
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
    const headerGradient = [Color(0xFF0284C7), Color(0xFF38BDF8)];

    return Container(
      decoration: widget.isEmbedded 
        ? null
        : BoxDecoration(
            gradient: LinearGradient(
              colors: headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                  color: const Color(0x400EA5E9), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
      padding: EdgeInsets.fromLTRB(4, widget.isEmbedded ? 16 : 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEmbedded)
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Expanded(
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
          if (!widget.isEmbedded) const SizedBox(height: 12),
          Container(
            margin: EdgeInsets.only(left: widget.isEmbedded ? 16 : 0),
            decoration: widget.isEmbedded
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  )
                : null,
            padding: widget.isEmbedded ? const EdgeInsets.symmetric(vertical: 4, horizontal: 4) : EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              indicator: widget.isEmbedded
                  ? BoxDecoration(
                      color: const Color(0xFF0EA5E9),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              indicatorColor: widget.isEmbedded ? Colors.transparent : Colors.white,
              indicatorWeight: widget.isEmbedded ? 0 : 3,
              labelColor: widget.isEmbedded ? Colors.white : Colors.white,
              unselectedLabelColor: widget.isEmbedded ? const Color(0xFF64748B) : Colors.white60,
              labelStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Sắp tới (${_upcoming.length})'),
                Tab(text: 'Đã khám (${_completed.length})'),
                Tab(text: 'Đã hủy (${_cancelled.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingTab() {
    if (_upcoming.isEmpty) {
      return _emptyState('Chưa có lịch khám',
          'Lịch khám bệnh sắp tới của bác sẽ hiển thị ở đây.',
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
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFEFF6FF);

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
                color: themeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: themeColor),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: const Color(0xFF64748B))),
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
      urgentColor = const Color(0xFFDC2626);
      urgentBg = const Color(0xFFFEF2F2);
      urgentLabel = 'Hôm nay';
    } else if (days <= 3) {
      urgentColor = const Color(0xFFD97706);
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
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
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('${item.doctor} · ${item.specialty}',
                          style: TextStyle(
                              fontSize: 13, color: const Color(0xFF64748B))),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.notes,
                            style: TextStyle(
                                fontSize: 12, color: const Color(0xFF94A3B8)),
                            maxLines: 2,
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
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(_fmtDate(item.date),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569))),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(item.time,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569))),
                  ],
                ),
                if (true)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _showCancelDialog(item),
                        child: Container(
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditSheet(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Sửa',
                              style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  ),
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      Text('${item.doctor} · ${_fmtDate(item.date)}',
                          style: TextStyle(
                              fontSize: 12, color: const Color(0xFF64748B))),
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
                    Text('Lý do hủy:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(item.cancelReason,
                        style: TextStyle(
                            fontSize: 13, color: const Color(0xFF475569))),
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
    final themeColor = const Color(0xFF0EA5E9);
    final themeBg = const Color(0xFFF0F9FF);
    final themeBorder = const Color(0xFFBAE6FD);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      Text('${item.doctor} · ${_fmtDate(item.date)}',
                          style: TextStyle(
                              fontSize: 12, color: const Color(0xFF64748B))),
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
                  color: themeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kết quả khám:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeColor)),
                    const SizedBox(height: 4),
                    Text(item.result,
                        style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                            height: 1.4)),
                  ],
                ),
              ),
            ],
            if (true) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showResultSheet(item),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: themeColor),
                    const SizedBox(width: 6),
                    Text('Chỉnh sửa kết quả',
                        style: TextStyle(
                            fontSize: 13,
                            color: themeColor,
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

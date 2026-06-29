import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

// Re-export AppointmentItem so elderly_home_screen can still use it if needed
class AppointmentItem {
  final String id;
  String hospital, doctor, specialty, time, notes, result, cancelReason;
  DateTime date;
  bool isCompleted, isCancelled;
  AppointmentItem({
    required this.id, required this.hospital, required this.doctor,
    required this.specialty, required this.date, required this.time,
    this.isCompleted = false, this.isCancelled = false,
    this.notes = '', this.result = '', this.cancelReason = '',
  });
}

class ElderlyAppointmentScreen extends StatefulWidget {
  final bool isEmbedded;
  const ElderlyAppointmentScreen({super.key, this.isEmbedded = false});
  @override
  State<ElderlyAppointmentScreen> createState() => _State();
}

class _State extends State<ElderlyAppointmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<AppointmentItem> _appts = [];
  bool _loading = true;

  static const _teal = Color(0xFF0284C7);
  static const _tealLight = Color(0xFFE0F2FE);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    if (ApiService.currentAccountId == null) { setState(() => _loading = false); return; }
    final data = await ApiService.getAppointments(ApiService.currentAccountId!);
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
    setState(() { _appts = loaded; _loading = false; });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<AppointmentItem> get _upcoming => _appts.where((a) => !a.isCompleted && !a.isCancelled).toList()..sort((a, b) => a.date.compareTo(b.date));
  List<AppointmentItem> get _completed => _appts.where((a) => a.isCompleted && !a.isCancelled).toList()..sort((a, b) => b.date.compareTo(a.date));
  List<AppointmentItem> get _cancelled => _appts.where((a) => a.isCancelled).toList()..sort((a, b) => b.date.compareTo(a.date));
  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showCancelDialog(AppointmentItem item) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Hủy lịch hẹn khám?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bác có chắc chắn muốn hủy lịch hẹn khám tại ${item.hospital} không ạ?'),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Nhập lý do bác muốn hủy',
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 2,
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Quay lại', style: TextStyle(color: Color(0xFF64748B)))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () {
            setState(() { item.isCancelled = true; item.cancelReason = ctrl.text.trim(); });
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFEF4444), content: Text('Đã hủy lịch khám')));
          },
          child: const Text('Xác nhận hủy lịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _showResultSheet(AppointmentItem item) {
    final ctrl = TextEditingController(text: item.result);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24 + MediaQuery.of(ctx).padding.bottom, top: 24, left: 24, right: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Ghi kết quả khám của bác', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(item.hospital, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl, maxLines: 5,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Nhập đơn thuốc hoặc dặn dò của bác sĩ...',
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            filled: true, fillColor: const Color(0xFFF3F7FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          onPressed: () {
            setState(() { item.result = ctrl.text.trim(); item.isCompleted = true; });
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('✓ Đã lưu kết quả khám!')));
          },
          child: const Text('Lưu kết quả khám của bác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        )),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [SliverToBoxAdapter(child: _header())],
        body: TabBarView(controller: _tab, children: [_upcomingTab(), _completedTab(), _cancelledTab()]),
      ),
      // Elderly: no FAB (cannot add appointments themselves)
    );
  }

  Widget _header() {
    return Container(
      decoration: widget.isEmbedded ? null : const BoxDecoration(
        gradient: LinearGradient(colors: [_teal, Color(0xFF38BDF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x220284C7), blurRadius: 20, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(4, widget.isEmbedded ? 16 : 52, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!widget.isEmbedded)
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lịch khám của bác', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Xem lịch khám và kết quả tái khám định kỳ', style: TextStyle(fontSize: 15, color: Colors.white70)),
            ])),
          ]),
        if (!widget.isEmbedded) const SizedBox(height: 12),
        Container(
          margin: EdgeInsets.only(left: widget.isEmbedded ? 16 : 0),
          decoration: widget.isEmbedded
              ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))])
              : null,
          padding: widget.isEmbedded ? const EdgeInsets.symmetric(vertical: 4, horizontal: 4) : EdgeInsets.zero,
          child: TabBar(
            controller: _tab,
            indicator: widget.isEmbedded ? BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(8)) : null,
            indicatorColor: widget.isEmbedded ? Colors.transparent : Colors.white,
            indicatorWeight: widget.isEmbedded ? 0 : 3,
            labelColor: Colors.white,
            unselectedLabelColor: widget.isEmbedded ? const Color(0xFF64748B) : Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [Tab(text: 'Sắp tới (${_upcoming.length})'), Tab(text: 'Đã khám (${_completed.length})'), Tab(text: 'Đã hủy (${_cancelled.length})')],
          ),
        ),
      ]),
    );
  }

  Widget _upcomingTab() {
    if (_upcoming.isEmpty) return _empty('Chưa có lịch khám', 'Lịch khám bệnh sắp tới của bác sẽ hiển thị ở đây.', Icons.calendar_today_rounded);
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: _upcoming.length, itemBuilder: (_, i) => _upCard(_upcoming[i]));
  }

  Widget _completedTab() {
    if (_completed.isEmpty) return _empty('Chưa có lịch sử khám', 'Lịch đã khám sẽ hiển thị ở đây', Icons.history_rounded);
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: _completed.length, itemBuilder: (_, i) => _doneCard(_completed[i]));
  }

  Widget _cancelledTab() {
    if (_cancelled.isEmpty) return _empty('Chưa có lịch khám bị hủy', 'Các lịch khám đã hủy sẽ hiển thị ở đây', Icons.cancel_presentation_rounded);
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: _cancelled.length, itemBuilder: (_, i) => _cancelCard(_cancelled[i]));
  }

  Widget _empty(String title, String sub, IconData icon) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: _tealLight, borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 40, color: _teal)),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
  ])));

  Widget _upCard(AppointmentItem item) {
    final days = item.date.difference(DateTime.now()).inDays;
    final Color urgentColor;
    final Color urgentBg;
    final String urgentLabel;
    if (days <= 0) { urgentColor = const Color(0xFFDC2626); urgentBg = const Color(0xFFFEF2F2); urgentLabel = 'Hôm nay'; }
    else if (days <= 3) { urgentColor = const Color(0xFFD97706); urgentBg = const Color(0xFFFEF3C7); urgentLabel = 'Còn $days ngày'; }
    else { urgentColor = _teal; urgentBg = _tealLight; urgentLabel = 'Còn $days ngày'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: urgentBg, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.local_hospital_rounded, color: urgentColor, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.hospital, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text('${item.doctor} · ${item.specialty}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: urgentColor),
              const SizedBox(width: 4),
              Text(_fmt(item.date), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: urgentColor)),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 14, color: urgentColor),
              const SizedBox(width: 4),
              Text(item.time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: urgentColor)),
            ]),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: urgentBg, borderRadius: BorderRadius.circular(20)),
              child: Text(urgentLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: urgentColor))),
        ])),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Row(children: [
          Expanded(child: TextButton.icon(
            onPressed: () => _showCancelDialog(item),
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFEF4444)),
            label: const Text('Hủy lịch', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14)),
          )),
          Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
          Expanded(child: TextButton.icon(
            onPressed: () => _showResultSheet(item),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: _teal),
            label: const Text('Đã khám xong', style: TextStyle(color: _teal, fontWeight: FontWeight.w600, fontSize: 14)),
          )),
        ]),
      ]),
    );
  }

  Widget _doneCard(AppointmentItem item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.hospital, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(_fmt(item.date), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        if (item.result.isNotEmpty) ...[const SizedBox(height: 4), Text(item.result, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis)],
      ])),
      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
    ])),
  );

  Widget _cancelCard(AppointmentItem item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.hospital, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(_fmt(item.date), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        if (item.cancelReason.isNotEmpty) ...[const SizedBox(height: 4), Text('Lý do: ${item.cancelReason}', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis)],
      ])),
    ])),
  );
}

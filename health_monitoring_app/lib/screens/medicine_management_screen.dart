import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/api_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class MedicineItem {
  String id;
  String name;
  String category; // 'tim_mach' | 'tieu_duong' | 'huyet_ap' | 'vitamin' | 'khac'
  String dosage; // '1 viên', '10ml', ...
  String unit; // 'viên', 'ml', 'gói', 'ống'
  String frequency; // 'Mỗi ngày' | '2 lần/ngày' | '3 lần/ngày' | ...
  List<String> times; // ['07:00', '19:00']
  String instruction; // 'Sau ăn', 'Trước ăn', 'Khi cần'
  DateTime startDate;
  DateTime endDate;
  int stockRemaining; // số viên còn lại
  int stockTotal; // tổng số viên
  String prescribedBy; // 'BS. Nguyễn Thị Lan'
  String color; // hex color for UI
  bool isActive;
  List<MedicineDoseRecord> doseHistory;
  String? notes;
  String? sideEffects;
  String? storageNote;

  MedicineItem({
    required this.id,
    required this.name,
    required this.category,
    required this.dosage,
    required this.unit,
    required this.frequency,
    required this.times,
    required this.instruction,
    required this.startDate,
    required this.endDate,
    required this.stockRemaining,
    required this.stockTotal,
    required this.prescribedBy,
    required this.color,
    this.isActive = true,
    List<MedicineDoseRecord>? doseHistory,
    this.notes,
    this.sideEffects,
    this.storageNote,
  }) : doseHistory = doseHistory ?? [];

  double get stockPercent => stockTotal > 0 ? stockRemaining / stockTotal : 0;
  bool get isLowStock => stockRemaining <= (stockTotal * 0.2).ceil();
  bool get isExpiringSoon {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }
}

class MedicineDoseRecord {
  final DateTime date;
  final String time;
  bool taken;
  DateTime? takenAt;

  MedicineDoseRecord({
    required this.date,
    required this.time,
    this.taken = false,
    this.takenAt,
  });
}

class TodayDoseSlot {
  final String time;
  final MedicineItem medicine;
  bool confirmed;

  TodayDoseSlot({
    required this.time,
    required this.medicine,
    this.confirmed = false,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({super.key});

  @override
  State<MedicineManagementScreen> createState() =>
      _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = 'all';
  String _mainView = 'today'; // 'today' | 'list' | 'stats'

  // ── Sample Data ─────────────────────────────────────────────────────────────
  final List<MedicineItem> _medicines = [
    MedicineItem(
      id: '1',
      name: 'Amlodipine 5mg',
      category: 'huyet_ap',
      dosage: '1 viên',
      unit: 'viên',
      frequency: '1 lần/ngày',
      times: ['07:00'],
      instruction: 'Sau ăn sáng',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 7, 31),
      stockRemaining: 45,
      stockTotal: 60,
      prescribedBy: 'BS. Nguyễn Thị Lan',
      color: '#DC2626',
      notes: 'Thuốc huyết áp - không được bỏ liều',
      sideEffects: 'Có thể gây phù chân, chóng mặt nhẹ',
      storageNote: 'Bảo quản nơi khô ráo, tránh ánh sáng trực tiếp',
      doseHistory: List.generate(
        14,
        (i) => MedicineDoseRecord(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          time: '07:00',
          taken: i < 13 ? (i % 7 != 6) : false,
        ),
      ),
    ),
    MedicineItem(
      id: '2',
      name: 'Metformin 500mg',
      category: 'tieu_duong',
      dosage: '1 viên',
      unit: 'viên',
      frequency: '2 lần/ngày',
      times: ['07:30', '19:30'],
      instruction: 'Trong bữa ăn',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 7, 31),
      stockRemaining: 18,
      stockTotal: 60,
      prescribedBy: 'BS. Trần Văn Hùng',
      color: '#0284C7',
      notes: 'Kiểm soát đường huyết - uống đúng giờ',
      sideEffects: 'Buồn nôn nếu uống lúc bụng đói',
      storageNote: 'Nhiệt độ phòng, dưới 30°C',
      doseHistory: List.generate(
        14,
        (i) => MedicineDoseRecord(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          time: '07:30',
          taken: i < 13 ? (i % 5 != 3) : false,
        ),
      ),
    ),
    MedicineItem(
      id: '3',
      name: 'Atorvastatin 20mg',
      category: 'tim_mach',
      dosage: '1 viên',
      unit: 'viên',
      frequency: '1 lần/ngày',
      times: ['21:00'],
      instruction: 'Trước khi đi ngủ',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 7, 15),
      stockRemaining: 8,
      stockTotal: 30,
      prescribedBy: 'BS. Nguyễn Thị Lan',
      color: '#7C3AED',
      notes: 'Thuốc mỡ máu - uống vào buổi tối',
      sideEffects: 'Có thể gây đau cơ nhẹ',
      storageNote: 'Bảo quản dưới 25°C',
      doseHistory: List.generate(
        14,
        (i) => MedicineDoseRecord(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          time: '21:00',
          taken: i < 13 ? true : false,
        ),
      ),
    ),
    MedicineItem(
      id: '4',
      name: 'Vitamin D3 1000IU',
      category: 'vitamin',
      dosage: '1 viên',
      unit: 'viên',
      frequency: '1 lần/ngày',
      times: ['12:00'],
      instruction: 'Sau bữa trưa',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 9, 30),
      stockRemaining: 55,
      stockTotal: 90,
      prescribedBy: 'Tự mua',
      color: '#EA580C',
      notes: 'Bổ sung vitamin D',
      storageNote: 'Tránh ánh sáng mặt trời',
      doseHistory: List.generate(
        14,
        (i) => MedicineDoseRecord(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          time: '12:00',
          taken: i < 13 ? (i % 4 != 2) : false,
        ),
      ),
    ),
    MedicineItem(
      id: '5',
      name: 'Aspirin 81mg',
      category: 'tim_mach',
      dosage: '1 viên',
      unit: 'viên',
      frequency: '1 lần/ngày',
      times: ['08:00'],
      instruction: 'Sau ăn sáng',
      startDate: DateTime(2026, 6, 15),
      endDate: DateTime(2026, 12, 31),
      stockRemaining: 4,
      stockTotal: 30,
      prescribedBy: 'BS. Nguyễn Thị Lan',
      color: '#E11D48',
      notes: 'Chống đông máu - không bỏ liều',
      sideEffects: 'Tránh dùng khi đói',
      storageNote: 'Nơi khô ráo, thoáng mát',
      doseHistory: List.generate(
        14,
        (i) => MedicineDoseRecord(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          time: '08:00',
          taken: i < 13 ? true : false,
        ),
      ),
    ),
  ];

  List<TodayDoseSlot> _todaySlots = [];

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _prescribedByCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _sideEffectsCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  String _formCategory = 'huyet_ap';
  String _formUnit = 'viên';
  String _formInstruction = 'Sau ăn';
  String _formColor = '#0EA5E9';
  List<TimeOfDay> _formTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _formStartDate = DateTime.now();
  DateTime _formEndDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _buildTodaySlots();
  }

  void _buildTodaySlots() {
    final slots = <TodayDoseSlot>[];
    final today = DateTime.now();
    for (final med in _medicines) {
      if (!med.isActive) continue;
      if (med.startDate.isAfter(today) || med.endDate.isBefore(today)) continue;
      for (final t in med.times) {
        final record = med.doseHistory.firstWhere(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day &&
              r.time == t,
          orElse: () => MedicineDoseRecord(date: today, time: t),
        );
        slots.add(TodayDoseSlot(
          time: t,
          medicine: med,
          confirmed: record.taken,
        ));
      }
    }
    slots.sort((a, b) => a.time.compareTo(b.time));
    _todaySlots = slots;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    _prescribedByCtrl.dispose();
    _stockCtrl.dispose();
    _sideEffectsCtrl.dispose();
    _storageCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _categoryLabel(String cat) {
    const map = {
      'all': 'Tất cả',
      'huyet_ap': 'Huyết áp',
      'tieu_duong': 'Tiểu đường',
      'tim_mach': 'Tim mạch',
      'vitamin': 'Vitamin',
      'khac': 'Khác',
    };
    return map[cat] ?? cat;
  }

  IconData _categoryIcon(String cat) {
    const map = {
      'huyet_ap': Icons.monitor_heart_rounded,
      'tieu_duong': Icons.water_drop_rounded,
      'tim_mach': Icons.favorite_rounded,
      'vitamin': Icons.eco_rounded,
      'khac': Icons.medication_rounded,
    };
    return map[cat] ?? Icons.medication_rounded;
  }

  Color _categoryColor(String cat) {
    const map = {
      'huyet_ap': Color(0xFFDC2626),
      'tieu_duong': Color(0xFF0284C7),
      'tim_mach': Color(0xFFE11D48),
      'vitamin': Color(0xFF16A34A),
      'khac': Color(0xFF7C3AED),
    };
    return map[cat] ?? const Color(0xFF0EA5E9);
  }

  double _overallAdherence() {
    int total = 0, taken = 0;
    for (final med in _medicines) {
      for (final r in med.doseHistory) {
        if (r.date.isBefore(DateTime.now())) {
          total++;
          if (r.taken) taken++;
        }
      }
    }
    return total == 0 ? 0 : taken / total;
  }

  // ── UI Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [_buildAppBar()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(),
                  _buildMedicineListTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineSheet,
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm thuốc',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final adherence = _overallAdherence();
    final alerts = _medicines.where((m) => m.isLowStock || m.isExpiringSoon).length;

    return SliverAppBar(
      expandedHeight: 160.0,
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 10,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Quản Lý Thuốc',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 0.3),
                          ),
                        ),
                        if (alerts > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706), size: 14),
                                const SizedBox(width: 4),
                                Text('$alerts cảnh báo',
                                    style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _statPill(Icons.check_circle_rounded, Colors.greenAccent,
                            '${(adherence * 100).toStringAsFixed(0)}%', 'Tuân thủ'),
                        const SizedBox(width: 10),
                        _statPill(Icons.medication_rounded, Colors.lightBlueAccent,
                            '${_medicines.where((m) => m.isActive).length}', 'Đang dùng'),
                        const SizedBox(width: 10),
                        _statPill(Icons.warning_rounded, Colors.orangeAccent,
                            '${_medicines.where((m) => m.isLowStock).length}', 'Sắp hết'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0EA5E9),
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: const Color(0xFF0EA5E9),
        indicatorWeight: 2.5,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.today_rounded, size: 18), text: 'Hôm nay'),
          Tab(icon: Icon(Icons.medication_rounded, size: 18), text: 'Danh sách'),
          Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Thống kê'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 – HÔM NAY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayTab() {
    final now = DateTime.now();
    final confirmedCount = _todaySlots.where((s) => s.confirmed).length;
    final total = _todaySlots.length;
    final progress = total > 0 ? confirmedCount / total : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Progress card
        _buildProgressCard(confirmedCount, total, progress),
        const SizedBox(height: 16),

        // Alerts
        ..._buildAlertCards(),

        // Timeline
        _sectionLabel('LỊCH UỐNG THUỐC HÔM NAY', Icons.schedule_rounded),
        const SizedBox(height: 10),
        if (_todaySlots.isEmpty)
          _buildEmptyState('Không có lịch uống thuốc hôm nay',
              Icons.check_circle_outline_rounded)
        else
          ..._todaySlots.asMap().entries.map((e) {
            final idx = e.key;
            final slot = e.value;
            return _buildTimelineSlot(slot, idx, _todaySlots.length);
          }),
      ],
    );
  }

  Widget _buildProgressCard(int done, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4A6E), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                'Thứ ${DateTime.now().weekday == 7 ? "Chủ nhật" : "${DateTime.now().weekday + 1}"}, '
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$done/$total',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('lần uống đã xác nhận',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: progress == 1
                  ? const Color(0xFF34D399)
                  : const Color(0xFF38BDF8),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1
                ? '✓ Xuất sắc! Bạn đã uống đủ thuốc hôm nay!'
                : '${((1 - progress) * total).ceil()} lần uống còn lại trong hôm nay',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlertCards() {
    final widgets = <Widget>[];
    final lowStock = _medicines.where((m) => m.isLowStock && m.isActive).toList();
    final expiring = _medicines.where((m) => m.isExpiringSoon && m.isActive).toList();

    if (lowStock.isNotEmpty) {
      widgets.add(_alertCard(
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
        title: 'Sắp hết thuốc',
        body:
            '${lowStock.map((m) => m.name).join(', ')} sắp hết. Cần mua bổ sung sớm.',
      ));
      widgets.add(const SizedBox(height: 10));
    }

    if (expiring.isNotEmpty) {
      widgets.add(_alertCard(
        icon: Icons.event_busy_rounded,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFFF1F2),
        border: const Color(0xFFFECACA),
        title: 'Đơn thuốc sắp hết hạn',
        body:
            '${expiring.map((m) => m.name).join(', ')} hết hạn trong 7 ngày tới.',
      ));
      widgets.add(const SizedBox(height: 10));
    }

    return widgets;
  }

  Widget _alertCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(
                        fontSize: 12, color: color.withOpacity(0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlot(TodayDoseSlot slot, int idx, int total) {
    final isLast = idx == total - 1;
    final now = TimeOfDay.now();
    final slotHour = int.tryParse(slot.time.split(':')[0]) ?? 0;
    final slotMin = int.tryParse(slot.time.split(':')[1]) ?? 0;
    final isPast = slotHour < now.hour ||
        (slotHour == now.hour && slotMin <= now.minute);
    final medColor = _hexColor(slot.medicine.color);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: slot.confirmed
                        ? const Color(0xFFDCFCE7)
                        : isPast
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        slot.time.split(':')[0],
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: slot.confirmed
                                ? const Color(0xFF16A34A)
                                : isPast
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF0EA5E9)),
                      ),
                      Text(
                        slot.time.split(':')[1],
                        style: TextStyle(
                            fontSize: 10,
                            color: slot.confirmed
                                ? const Color(0xFF16A34A)
                                : isPast
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF0EA5E9)),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: slot.confirmed
                        ? const Color(0xFFBBF7D0)
                        : isPast && !slot.confirmed
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: medColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slot.medicine.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B)),
                          ),
                        ),
                        if (slot.confirmed)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF16A34A), size: 20)
                        else if (isPast)
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFD97706), size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${slot.medicine.dosage} · ${slot.medicine.instruction}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    if (!slot.confirmed) ...[
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  slot.confirmed = true;
                                  // Also add to history
                                  final today = DateTime.now();
                                  final existing = slot.medicine.doseHistory
                                      .where((r) =>
                                          r.date.year == today.year &&
                                          r.date.month == today.month &&
                                          r.date.day == today.day &&
                                          r.time == slot.time)
                                      .toList();
                                  if (existing.isEmpty) {
                                    slot.medicine.doseHistory.add(MedicineDoseRecord(
                                      date: today,
                                      time: slot.time,
                                      taken: true,
                                      takenAt: today,
                                    ));
                                  } else {
                                    existing.first.taken = true;
                                    existing.first.takenAt = today;
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF16A34A),
                                    content: Text(
                                        '✓ Đã xác nhận uống ${slot.medicine.name}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text('Xác nhận đã uống',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showMedicineDetail(slot.medicine),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  size: 16, color: Color(0xFF0EA5E9)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Đã uống ✓',
                            style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 – DANH SÁCH THUỐC
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMedicineListTab() {
    final filtered = _medicines.where((m) {
      final matchCat =
          _filterCategory == 'all' || m.category == _filterCategory;
      final matchSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Search
        _buildSearchBar(),
        const SizedBox(height: 12),
        // Filter chips
        _buildCategoryFilter(),
        const SizedBox(height: 14),
        // Section label
        _sectionLabel('DANH SÁCH THUỐC (${filtered.length})',
            Icons.medication_rounded),
        const SizedBox(height: 10),
        // Cards
        if (filtered.isEmpty)
          _buildEmptyState('Không tìm thấy thuốc', Icons.search_off_rounded)
        else
          ...filtered.map((m) => _buildMedicineCard(m)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tên thuốc...',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon:
            const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9), size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0EA5E9), size: 22),
              tooltip: 'Quét mã vạch thuốc',
              onPressed: _showBarcodeScanner,
            ),
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded, color: Color(0xFF7C3AED), size: 22),
              tooltip: 'Quét đơn thuốc (OCR)',
              onPressed: _showScanPrescriptionDialog,
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = ['all', 'huyet_ap', 'tieu_duong', 'tim_mach', 'vitamin', 'khac'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final isSelected = _filterCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _filterCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _categoryLabel(cat),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF475569)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(MedicineItem med) {
    final color = _hexColor(med.color);
    final daysLeft = med.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
        border: Border.all(
            color: med.isLowStock
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showMedicineDetail(med),
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_categoryIcon(med.category),
                          color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text(
                            '${_categoryLabel(med.category)} · ${med.frequency}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (med.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Sắp hết',
                                style: TextStyle(
                                    color: Color(0xFFD97706),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        if (daysLeft >= 0 && daysLeft <= 7)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Còn $daysLeft ngày',
                                style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Time chips
                Wrap(
                  spacing: 6,
                  children: [
                    _chip(Icons.access_time_rounded, med.times.join(', '),
                        const Color(0xFF0EA5E9)),
                    _chip(Icons.medical_services_outlined, med.dosage,
                        const Color(0xFF7C3AED)),
                    _chip(Icons.restaurant_rounded, med.instruction,
                        const Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 12),
                // Stock bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Kho thuốc',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8))),
                              Text('${med.stockRemaining}/${med.stockTotal} ${med.unit}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: med.isLowStock
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF475569))),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: med.stockPercent,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: med.isLowStock
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF0EA5E9),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showEditMedicineSheet(med),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 13, color: Color(0xFF0EA5E9)),
                            SizedBox(width: 4),
                            Text('Sửa',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0EA5E9))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 – THỐNG KÊ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsTab() {
    final adherence = _overallAdherence();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Overall adherence
        _buildAdherenceCard(adherence),
        const SizedBox(height: 16),

        // Per-medicine adherence
        _sectionLabel('TUÂN THỦ TỪNG THUỐC', Icons.medication_rounded),
        const SizedBox(height: 10),
        ..._medicines.map((m) => _buildMedicineAdherenceBar(m)),

        const SizedBox(height: 16),

        // 7-day calendar heatmap
        _sectionLabel('BIỂU ĐỒ 7 NGÀY QUA', Icons.calendar_view_week_rounded),
        const SizedBox(height: 10),
        _buildWeekHeatmap(),

        const SizedBox(height: 16),

        // Summary stats
        _sectionLabel('TÓM TẮT', Icons.summarize_rounded),
        const SizedBox(height: 10),
        _buildSummaryStats(),
      ],
    );
  }

  Widget _buildAdherenceCard(double adherence) {
    final pct = (adherence * 100).round();
    Color ring = pct >= 80
        ? const Color(0xFF16A34A)
        : pct >= 60
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    String msg = pct >= 80
        ? 'Rất tốt! Tiếp tục duy trì.'
        : pct >= 60
            ? 'Khá tốt, hãy cố gắng hơn.'
            : 'Cần cải thiện việc uống thuốc.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _RingPainter(
                      adherence, ring, const Color(0xFFE2E8F0)),
                ),
                Text('$pct%',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: ring)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng tuân thủ uống thuốc',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 5),
                Text(msg,
                    style: TextStyle(fontSize: 13, color: ring)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _miniStat('Đúng giờ', '${(adherence * 0.85 * 100).round()}%',
                        const Color(0xFF16A34A)),
                    const SizedBox(width: 14),
                    _miniStat('Bỏ liều',
                        '${((1 - adherence) * 100).round()}%',
                        const Color(0xFFDC2626)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildMedicineAdherenceBar(MedicineItem med) {
    final total = med.doseHistory.where((r) => r.date.isBefore(DateTime.now())).length;
    final taken = med.doseHistory.where((r) => r.taken).length;
    final pct = total == 0 ? 0.0 : taken / total;
    final color = _hexColor(med.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_categoryIcon(med.category), color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(med.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E293B))),
              ),
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: pct >= 0.8
                          ? const Color(0xFF16A34A)
                          : pct >= 0.6
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFE2E8F0),
              color: pct >= 0.8
                  ? const Color(0xFF16A34A)
                  : pct >= 0.6
                      ? const Color(0xFFD97706)
                      : const Color(0xFFDC2626),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$taken/$total lần đúng giờ',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
              Text('${total - taken} lần bỏ',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeatmap() {
    final days = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.asMap().entries.map((e) {
              final day = e.value;
              int total = 0, taken = 0;
              for (final med in _medicines) {
                for (final r in med.doseHistory) {
                  if (r.date.year == day.year &&
                      r.date.month == day.month &&
                      r.date.day == day.day) {
                    total++;
                    if (r.taken) taken++;
                  }
                }
              }
              final pct = total == 0 ? -1.0 : taken / total;
              final isToday = day.day == DateTime.now().day &&
                  day.month == DateTime.now().month;

              Color cellColor;
              if (pct < 0) {
                cellColor = const Color(0xFFF1F5F9);
              } else if (pct >= 0.9) {
                cellColor = const Color(0xFF16A34A);
              } else if (pct >= 0.7) {
                cellColor = const Color(0xFF86EFAC);
              } else if (pct >= 0.5) {
                cellColor = const Color(0xFFFDE68A);
              } else {
                cellColor = const Color(0xFFFCA5A5);
              }

              final wdIdx = day.weekday - 1;
              return Column(
                children: [
                  Text(
                    wdIdx < dayLabels.length ? dayLabels[wdIdx] : '',
                    style: TextStyle(
                        fontSize: 11,
                        color: isToday
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFF94A3B8),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFF0EA5E9), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pct >= 0.7
                                ? Colors.white
                                : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pct < 0
                        ? '-'
                        : pct == 1.0
                            ? '✓'
                            : '${(pct * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFF16A34A), '≥90%'),
              const SizedBox(width: 10),
              _legendItem(const Color(0xFF86EFAC), '70-90%'),
              const SizedBox(width: 10),
              _legendItem(const Color(0xFFFDE68A), '50-70%'),
              const SizedBox(width: 10),
              _legendItem(const Color(0xFFFCA5A5), '<50%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final active = _medicines.where((m) => m.isActive).length;
    final lowStock = _medicines.where((m) => m.isLowStock).length;
    final expiring = _medicines.where((m) => m.isExpiringSoon).length;
    final adherence = _overallAdherence();

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryStatCard('Đang dùng', '$active thuốc',
            Icons.medication_rounded, const Color(0xFF0EA5E9)),
        _summaryStatCard('Tuân thủ', '${(adherence * 100).round()}%',
            Icons.check_circle_rounded, const Color(0xFF16A34A)),
        _summaryStatCard('Sắp hết kho', '$lowStock thuốc',
            Icons.inventory_2_rounded, const Color(0xFFD97706)),
        _summaryStatCard('Sắp hết hạn', '$expiring thuốc',
            Icons.event_busy_rounded, const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _summaryStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Medicine Detail Sheet ────────────────────────────────────────────────────
  void _showMedicineDetail(MedicineItem med) {
    final color = _hexColor(med.color);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(med.category),
                        color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1E293B))),
                        Text(_categoryLabel(med.category),
                            style: TextStyle(
                                fontSize: 12, color: color)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Info grid
              _detailRow(Icons.medical_services_rounded, 'Liều lượng', med.dosage, color),
              _detailRow(Icons.repeat_rounded, 'Tần suất', med.frequency, color),
              _detailRow(Icons.access_time_rounded, 'Giờ uống', med.times.join(', '), color),
              _detailRow(Icons.restaurant_rounded, 'Cách uống', med.instruction, color),
              _detailRow(Icons.person_rounded, 'Bác sĩ kê', med.prescribedBy, color),
              _detailRow(
                  Icons.calendar_today_rounded,
                  'Thời gian',
                  '${med.startDate.day}/${med.startDate.month} – ${med.endDate.day}/${med.endDate.month}/${med.endDate.year}',
                  color),
              const Divider(height: 24),
              // Stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kho thuốc còn lại',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF475569))),
                  Text(
                    '${med.stockRemaining}/${med.stockTotal} ${med.unit}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: med.isLowStock
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: med.stockPercent,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: med.isLowStock
                      ? const Color(0xFFD97706)
                      : const Color(0xFF0EA5E9),
                  minHeight: 10,
                ),
              ),
              if (med.notes != null) ...[
                const SizedBox(height: 16),
                _noteBox(Icons.sticky_note_2_rounded, 'Ghi chú',
                    med.notes!, const Color(0xFF0EA5E9)),
              ],
              if (med.sideEffects != null) ...[
                const SizedBox(height: 10),
                _noteBox(Icons.warning_amber_rounded, 'Tác dụng phụ',
                    med.sideEffects!, const Color(0xFFD97706)),
              ],
              if (med.storageNote != null) ...[
                const SizedBox(height: 10),
                _noteBox(Icons.thermostat_rounded, 'Bảo quản',
                    med.storageNote!, const Color(0xFF7C3AED)),
              ],
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditMedicineSheet(med);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Chỉnh sửa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0EA5E9),
                        side: const BorderSide(color: Color(0xFF0EA5E9)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => med.isActive = !med.isActive);
                      },
                      icon: Icon(
                          med.isActive
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded,
                          size: 16),
                      label: Text(med.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: med.isActive
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                  fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
                        fontSize: 12,
                        color: color)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Sheet ─────────────────────────────────────────────────────────
  void _showAddMedicineSheet() {
    _nameCtrl.clear();
    _dosageCtrl.clear();
    _notesCtrl.clear();
    _prescribedByCtrl.clear();
    _stockCtrl.text = '30';
    _sideEffectsCtrl.clear();
    _storageCtrl.clear();
    _formCategory = 'huyet_ap';
    _formUnit = 'viên';
    _formInstruction = 'Sau ăn';
    _formColor = '#0EA5E9';
    _formTimes = [const TimeOfDay(hour: 8, minute: 0)];
    _formStartDate = DateTime.now();
    _formEndDate = DateTime.now().add(const Duration(days: 30));
    _showMedicineFormSheet(isEdit: false);
  }

  void _showEditMedicineSheet(MedicineItem med) {
    _nameCtrl.text = med.name;
    _dosageCtrl.text = med.dosage;
    _notesCtrl.text = med.notes ?? '';
    _prescribedByCtrl.text = med.prescribedBy;
    _stockCtrl.text = med.stockRemaining.toString();
    _sideEffectsCtrl.text = med.sideEffects ?? '';
    _storageCtrl.text = med.storageNote ?? '';
    _formCategory = med.category;
    _formUnit = med.unit;
    _formInstruction = med.instruction;
    _formColor = med.color;
    _formTimes = med.times.map((t) {
      final parts = t.split(':');
      return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0);
    }).toList();
    _formStartDate = med.startDate;
    _formEndDate = med.endDate;
    _showMedicineFormSheet(isEdit: true, editTarget: med);
  }

  void _showMedicineFormSheet({bool isEdit = false, MedicineItem? editTarget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  24 +
                  MediaQuery.of(ctx).padding.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
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
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.add_circle_rounded,
                            color: const Color(0xFF0EA5E9),
                            size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Chỉnh sửa thuốc' : 'Thêm thuốc mới',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  _formLabel('Tên thuốc *'),
                  _formField(_nameCtrl, 'VD: Amlodipine 5mg',
                      Icons.medication_rounded),
                  const SizedBox(height: 14),

                  // Category
                  _formLabel('Nhóm thuốc'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'huyet_ap',
                      'tieu_duong',
                      'tim_mach',
                      'vitamin',
                      'khac'
                    ].map((cat) {
                      final sel = _formCategory == cat;
                      final c = _categoryColor(cat);
                      return GestureDetector(
                        onTap: () => setS(() => _formCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? c.withOpacity(0.1) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel ? c : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_categoryIcon(cat),
                                  size: 14,
                                  color: sel ? c : const Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Text(_categoryLabel(cat),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? c
                                          : const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Dosage + Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Liều lượng'),
                            _formField(
                                _dosageCtrl, 'VD: 1 viên', Icons.medical_services_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Đơn vị'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _formUnit,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                              ),
                              items: ['viên', 'ml', 'gói', 'ống', 'ống tiêm']
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (v) => setS(() => _formUnit = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Instruction
                  _formLabel('Cách dùng'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Trước ăn', 'Sau ăn', 'Trong bữa ăn', 'Khi cần', 'Trước ngủ']
                        .map((ins) => GestureDetector(
                              onTap: () =>
                                  setS(() => _formInstruction = ins),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _formInstruction == ins
                                      ? const Color(0xFF0EA5E9)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _formInstruction == ins
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFFE2E8F0)),
                                ),
                                child: Text(ins,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _formInstruction == ins
                                            ? Colors.white
                                            : const Color(0xFF475569))),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // Times
                  Row(
                    children: [
                      _formLabel('Giờ uống'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                              context: ctx,
                              initialTime:
                                  const TimeOfDay(hour: 8, minute: 0));
                          if (t != null) setS(() => _formTimes.add(t));
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_rounded,
                                size: 16, color: Color(0xFF0EA5E9)),
                            SizedBox(width: 4),
                            Text('Thêm giờ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0EA5E9),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _formTimes.asMap().entries.map((e) {
                      final i = e.key;
                      final t = e.value;
                      return GestureDetector(
                        onLongPress: () {
                          if (_formTimes.length > 1) {
                            setS(() => _formTimes.removeAt(i));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: Color(0xFF0EA5E9)),
                              const SizedBox(width: 5),
                              Text(
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0369A1)),
                              ),
                              if (_formTimes.length > 1) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.close_rounded,
                                    size: 12, color: Color(0xFF64748B)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Ngày bắt đầu'),
                            const SizedBox(height: 8),
                            _datePicker(ctx, setS, _formStartDate, true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Ngày kết thúc'),
                            const SizedBox(height: 8),
                            _datePicker(ctx, setS, _formEndDate, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stock
                  _formLabel('Số ${_formUnit} còn lại'),
                  _formField(_stockCtrl, 'VD: 30', Icons.inventory_2_rounded,
                      isNumber: true),
                  const SizedBox(height: 14),

                  // Prescribed by
                  _formLabel('Bác sĩ kê đơn'),
                  _formField(_prescribedByCtrl, 'VD: BS. Nguyễn Văn A',
                      Icons.person_rounded),
                  const SizedBox(height: 14),

                  // Notes
                  _formLabel('Ghi chú (tùy chọn)'),
                  _formField(_notesCtrl,
                      'Thêm ghi chú quan trọng...', Icons.notes_rounded),
                  const SizedBox(height: 14),

                  // Side effects
                  _formLabel('Tác dụng phụ (tùy chọn)'),
                  _formField(_sideEffectsCtrl, 'VD: Buồn nôn, chóng mặt...',
                      Icons.warning_amber_rounded),
                  const SizedBox(height: 14),

                  // Storage
                  _formLabel('Hướng dẫn bảo quản (tùy chọn)'),
                  _formField(_storageCtrl,
                      'VD: Bảo quản dưới 25°C, tránh ẩm',
                      Icons.thermostat_rounded),
                  const SizedBox(height: 24),

                  // Save button
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
                        if (_nameCtrl.text.trim().isEmpty) return;
                        final timesStr = _formTimes
                            .map((t) =>
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                            .toList();
                        final stock =
                            int.tryParse(_stockCtrl.text.trim()) ?? 30;

                        if (isEdit && editTarget != null) {
                          setState(() {
                            editTarget.name = _nameCtrl.text.trim();
                            editTarget.category = _formCategory;
                            editTarget.dosage = _dosageCtrl.text.trim().isEmpty
                                ? '1 viên'
                                : _dosageCtrl.text.trim();
                            editTarget.unit = _formUnit;
                            editTarget.instruction = _formInstruction;
                            editTarget.times = timesStr;
                            editTarget.startDate = _formStartDate;
                            editTarget.endDate = _formEndDate;
                            editTarget.stockRemaining = stock;
                            editTarget.prescribedBy =
                                _prescribedByCtrl.text.trim().isEmpty
                                    ? 'Không rõ'
                                    : _prescribedByCtrl.text.trim();
                            editTarget.notes =
                                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
                            editTarget.sideEffects =
                                _sideEffectsCtrl.text.trim().isEmpty
                                    ? null
                                    : _sideEffectsCtrl.text.trim();
                            editTarget.storageNote =
                                _storageCtrl.text.trim().isEmpty
                                    ? null
                                    : _storageCtrl.text.trim();
                            editTarget.color = _formColor;
                            _buildTodaySlots();
                          });
                        } else {
                          final catColors = {
                            'huyet_ap': '#DC2626',
                            'tieu_duong': '#0284C7',
                            'tim_mach': '#E11D48',
                            'vitamin': '#16A34A',
                            'khac': '#7C3AED',
                          };
                          setState(() {
                            _medicines.add(MedicineItem(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: _nameCtrl.text.trim(),
                              category: _formCategory,
                              dosage:
                                  _dosageCtrl.text.trim().isEmpty ? '1 viên' : _dosageCtrl.text.trim(),
                              unit: _formUnit,
                              frequency: timesStr.length == 1
                                  ? '1 lần/ngày'
                                  : '${timesStr.length} lần/ngày',
                              times: timesStr,
                              instruction: _formInstruction,
                              startDate: _formStartDate,
                              endDate: _formEndDate,
                              stockRemaining: stock,
                              stockTotal: stock,
                              prescribedBy:
                                  _prescribedByCtrl.text.trim().isEmpty
                                      ? 'Không rõ'
                                      : _prescribedByCtrl.text.trim(),
                              color: catColors[_formCategory] ?? '#0EA5E9',
                              notes: _notesCtrl.text.trim().isEmpty
                                  ? null
                                  : _notesCtrl.text.trim(),
                              sideEffects:
                                  _sideEffectsCtrl.text.trim().isEmpty
                                      ? null
                                      : _sideEffectsCtrl.text.trim(),
                              storageNote:
                                  _storageCtrl.text.trim().isEmpty
                                      ? null
                                      : _storageCtrl.text.trim(),
                            ));
                            _buildTodaySlots();
                          });
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text(isEdit
                              ? '✓ Đã cập nhật ${_nameCtrl.text} thành công!'
                              : '✓ Đã thêm ${_nameCtrl.text} vào danh sách thuốc!'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      child: Text(
                        isEdit ? 'Lưu thay đổi' : 'Thêm vào danh sách',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),

                  if (isEdit && editTarget != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _medicines.remove(editTarget);
                            _buildTodaySlots();
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFDC2626),
                              content: Text('Đã xoá thuốc khỏi danh sách.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('Xoá thuốc này'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569))),
    );
  }

  Widget _formField(TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
      ),
    );
  }

  Widget _datePicker(BuildContext ctx, StateSetter setS, DateTime current,
      bool isStart) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: ctx,
          initialDate: current,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) {
          setS(() {
            if (isStart) {
              _formStartDate = d;
            } else {
              _formEndDate = d;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: Color(0xFF0EA5E9)),
            const SizedBox(width: 8),
            Text(
              '${current.day.toString().padLeft(2, '0')}/${current.month.toString().padLeft(2, '0')}/${current.year}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF475569)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }

  void _showScanPrescriptionDialog() async {
    final bool isWeb = kIsWeb;
    final ImageSource? imageSource = isWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const Text('Chọn nguồn ảnh đơn thuốc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7)),
                    title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sử dụng camera để chụp đơn thuốc'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                    title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Chọn ảnh đã có trong máy'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );

    if (imageSource == null) return;

    if (isWeb && imageSource == ImageSource.camera) {
      _showScanError('Không thể chụp ảnh trực tiếp trên Web. Vui lòng chọn ảnh từ thư viện.');
      return;
    }

    final ImagePicker picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(source: imageSource, imageQuality: 80);
    } catch (e) {
      _showScanError('Không thể mở nguồn ảnh. Vui lòng kiểm tra quyền truy cập máy ảnh và thư viện.');
      return;
    }

    if (image == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF0284C7), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Đang quét đơn thuốc...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Vui lòng giữ máy ổn định và chờ trong giây lát', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const LinearProgressIndicator(color: Color(0xFF0EA5E9)),
          ],
        ),
      ),
    );

    try {
      final res = await ApiService.scanPrescription(image);
      if (!mounted) return;
      Navigator.pop(context);

      if (res['error'] != null) {
        _showScanError(res['error'] as String);
        return;
      }

      final medications = (res['medications'] ?? res['results']) as List?;
      final appointment = res['appointment'] as Map<String, dynamic>?;

      if ((medications != null && medications.isNotEmpty) || appointment != null) {
        _showScannedResultsDialog(medications ?? [], appointment: appointment);
      } else {
        _showScanError('Không tìm thấy thông tin trong ảnh. Vui lòng thử lại với ảnh rõ hơn.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showScanError('Có lỗi xảy ra khi quét: $e');
    }
  }

  void _showScanError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quét không thành công', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
            onPressed: () {
              Navigator.pop(ctx);
              _showScanPrescriptionDialog();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showScannedResultsDialog(List results, {Map<String, dynamic>? appointment}) {
    final Map<String, List<dynamic>> groupedResults = {};
    for (var item in results) {
      final t = item['time'] ?? '08:00';
      if (!groupedResults.containsKey(t)) groupedResults[t] = [];
      groupedResults[t]!.add(item);
    }
    
    final sortedTimes = groupedResults.keys.toList()..sort();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateModal) {

            Widget buildMedicationCard(dynamic item) => Card(
              elevation: 0,
              color: const Color(0xFFEFF6FF),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFBFDBFE), shape: BoxShape.circle),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFF1D4ED8), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F))),
                          const SizedBox(height: 3),
                          Text('${item['dosage'] ?? ''} · ${item['instruction'] ?? ''}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            Widget buildAppointmentCard() {
              if (appointment == null) return const SizedBox.shrink();
              return Card(
                elevation: 0,
                color: const Color(0xFFFFF7ED),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFED7AA), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFFEA580C), size: 20),
                        const SizedBox(width: 8),
                        const Text('Lịch tái khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFEA580C))),
                      ]),
                      const Divider(height: 16, color: Color(0xFFFED7AA)),
                      _infoRow(Icons.local_hospital_rounded, 'Phòng khám', appointment['clinic'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.person_rounded, 'Bác sĩ', appointment['doctor_name'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.location_on_rounded, 'Địa chỉ', appointment['address'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.phone_rounded, 'SĐT', appointment['phone'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.event_rounded, 'Ngày', '${appointment['appointment_date'] ?? ''} lúc ${appointment['appointment_time'] ?? ''}'),
                      if ((appointment['note'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _infoRow(Icons.info_outline_rounded, 'Lưu ý', appointment['note'] ?? ''),
                      ],
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: Row(children: [
                const Icon(Icons.document_scanner_rounded, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Kết quả nhận diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0EA5E9)))),
              ]),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: isSaving
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                            SizedBox(height: 16),
                            Text('Đang lưu thuốc...', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          if (results.isNotEmpty)
                            ...sortedTimes.map((t) {
                              String sessionName = t.startsWith('05') || t.startsWith('06') || t.startsWith('07') || t.startsWith('08') || t.startsWith('09') || t.startsWith('10') || t.startsWith('11')
                                  ? 'Buổi sáng'
                                  : (t.startsWith('12') || t.startsWith('13') || t.startsWith('14') || t.startsWith('15') || t.startsWith('16') || t.startsWith('17')
                                      ? 'Buổi trưa/chiều'
                                      : 'Buổi tối');
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 16, color: Color(0xFF059669)),
                                        const SizedBox(width: 6),
                                        Text('$sessionName ($t)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF059669))),
                                      ],
                                    ),
                                  ),
                                  ...groupedResults[t]!.map((item) => buildMedicationCard(item)),
                                ],
                              );
                            }),
                          if (appointment != null) ...[
                            const SizedBox(height: 12),
                            buildAppointmentCard(),
                          ],
                        ],
                      ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                if (!isSaving)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      setStateModal(() => isSaving = true);
                      
                      await Future.delayed(const Duration(milliseconds: 600));

                      setState(() {
                        for (var item in results) {
                          final name = item['name'] ?? 'Không tên';
                          final time = item['time'] ?? '08:00';
                          final dosage = item['dosage'] ?? '1 viên';
                          final instruction = item['instruction'] ?? 'Sau ăn';
                          
                          String cat = 'khac';
                          final nameL = name.toLowerCase();
                          if (nameL.contains('amlodipine') || nameL.contains('áp') || nameL.contains('huyết áp')) {
                            cat = 'huyet_ap';
                          } else if (nameL.contains('metformin') || nameL.contains('đường')) {
                            cat = 'tieu_duong';
                          } else if (nameL.contains('atorvastatin') || nameL.contains('aspirin') || nameL.contains('tim')) {
                            cat = 'tim_mach';
                          } else if (nameL.contains('vitamin') || nameL.contains('d3')) {
                            cat = 'vitamin';
                          }

                          final catColors = {
                            'huyet_ap': '#DC2626',
                            'tieu_duong': '#0284C7',
                            'tim_mach': '#E11D48',
                            'vitamin': '#16A34A',
                            'khac': '#7C3AED',
                          };

                          _medicines.add(MedicineItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(100).toString(),
                            name: name,
                            category: cat,
                            dosage: dosage,
                            unit: item['unit'] ?? 'viên',
                            frequency: item['frequency'] ?? '1 lần/ngày',
                            times: [time],
                            instruction: instruction,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(Duration(days: item['duration_days'] ?? 30)),
                            stockRemaining: item['stock'] ?? 30,
                            stockTotal: item['stock'] ?? 30,
                            prescribedBy: item['doctor'] ?? 'Quét OCR đơn thuốc',
                            color: catColors[cat] ?? '#0EA5E9',
                            notes: item['notes'],
                            sideEffects: item['side_effects'],
                          ));
                        }
                        _buildTodaySlots();
                      });

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text('✓ Đã thêm thành công ${results.length} loại thuốc từ đơn quét!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Lưu vào danh sách', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFEA580C).withOpacity(0.7)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12))),
        ),
      ],
    );
  }

  void _showBarcodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Quét mã vạch / QR thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String code = barcodes.first.rawValue ?? '';
                      if (code.isNotEmpty) {
                        Navigator.pop(ctx);
                        _handleBarcodeResult(code);
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Hướng camera về phía mã vạch hoặc mã QR trên hộp thuốc.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBarcodeResult(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Đã quét thành công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: Text('Mã tìm thấy: $code\n\nHệ thống sẽ điền thông tin dựa trên mã này.', style: const TextStyle(fontSize: 14)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
            onPressed: () {
              Navigator.pop(ctx);
              _showAddMedicineSheet();
              _nameCtrl.text = "Thuốc (Mã: $code)";
              _formCategory = 'khac';
              _notesCtrl.text = "Thêm từ mã vạch: $code";
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color bg;

  _RingPainter(this.value, this.color, this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 6;
    final stroke = 8.0;

    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    final sweep = value.clamp(0.0, 1.0) * 2 * pi;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        sweep,
        false,
        fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

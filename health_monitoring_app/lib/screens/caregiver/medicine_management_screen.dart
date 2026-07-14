import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/medication_dialog_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/api_service.dart';
import '../../utils/alarm_service.dart';
import '../../utils/elderly_provider.dart';
import 'widgets/elderly_switcher_bar.dart';

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

  bool _isMultiSelectMode = false;
  Set<String> _selectedMedIds = {};

  // ── Sample Data ─────────────────────────────────────────────────────────────
  final List<MedicineItem> _medicines = [];

  List<TodayDoseSlot> _todaySlots = [];

  // ── Elderly Provider (centralized) ──
  final ElderlyProvider _elderlyProvider = ElderlyProvider.instance;

  // Proxy getters
  int? get _selectedElderlyId => _elderlyProvider.selectedElderlyId;

  bool _isLoadingMedications = false;

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
    _elderlyProvider.addListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.addListener(_onDataChanged);
    if (_selectedElderlyId != null) {
      _loadMedicationSchedules(_selectedElderlyId!);
    }
  }

  void _onElderlyChanged() {
    if (mounted && _selectedElderlyId != null) {
      _loadMedicationSchedules(_selectedElderlyId!);
    }
  }

  void _onDataChanged() {
    if (mounted && _selectedElderlyId != null) {
      _loadMedicationSchedules(_selectedElderlyId!);
    }
  }





  Future<void> _handleRefresh() async {
    await _elderlyProvider.loadElderlyList();
    if (_selectedElderlyId != null) {
      await _loadMedicationSchedules(_selectedElderlyId!);
    }
  }

  Future<void> _loadMedicationSchedules(int elderlyId) async {
    setState(() => _isLoadingMedications = true);
    final schedules = await ApiService.getElderlyMedicationSchedule(elderlyId);
    if (!mounted) return;

    AlarmService.scheduleAlarmsFromApiData(schedules);

    setState(() {
      _medicines.clear();
      for (var schedule in schedules) {
        final med = schedule['medication'] ?? {};
        final name = med['name']?.toString() ?? 'Không rõ';
        final dosage = med['dosage']?.toString() ?? '1 viên';
        final instruction = med['instruction']?.toString() ?? 'Sau ăn';
        final time = schedule['time']?.toString() ?? '08:00';
        final frequency = schedule['frequency']?.toString() ?? '1 lần/ngày';
        
        final description = med['description']?.toString() ?? '';
        final List<MedicineDoseRecord> doseHistory = [];
        if (description.contains('· dose_history:')) {
          final parts = description.split('· dose_history:');
          try {
            final list = jsonDecode(parts[1].trim()) as List;
            for (final item in list) {
              doseHistory.add(MedicineDoseRecord(
                date: DateTime.parse(item['date']),
                time: item['time'],
                taken: item['taken'],
                takenAt: item['takenAt'] != null ? DateTime.parse(item['takenAt']) : null,
              ));
            }
          } catch (e) {
            print("Error parsing dose history: $e");
          }
        }

        int stock = schedule['stock_remaining'] is int
            ? schedule['stock_remaining'] as int
            : 30;
        int totalStock = schedule['stock_total'] is int
            ? schedule['stock_total'] as int
            : 30;
            
        if (description.contains('Tổng số viên thuốc:')) {
          final match = RegExp(r'Tổng số viên thuốc:\s*(\d+)').firstMatch(description);
          if (match != null) {
            stock = int.parse(match.group(1)!);
          }
        }

        final startDate = DateTime.tryParse(schedule['start_date']?.toString() ?? '') ?? DateTime.now();
        final endDate = DateTime.tryParse(schedule['end_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 30));
        
        final newItem = MedicineItem(
          id: schedule['schedule_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: 'khac',
          dosage: dosage,
          unit: 'viên',
          frequency: frequency,
          times: [time],
          instruction: instruction,
          startDate: startDate,
          endDate: endDate,
          stockRemaining: stock,
          stockTotal: totalStock,
          prescribedBy: 'Không rõ',
          color: '#0EA5E9',
          doseHistory: doseHistory,
        );
        newItem.notes = () {
          var desc = description;
          if (desc.contains('· dose_history:')) {
            desc = desc.split('· dose_history:')[0].trim();
          }
          return desc.isNotEmpty ? desc : null;
        }();
        _medicines.add(newItem);
      }
      _isLoadingMedications = false;
      _loadLocalDoseHistory();
    });
  }

  // --- Local Cache Dose History ---
  Future<void> _loadLocalDoseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final med in _medicines) {
        if (med.doseHistory.isNotEmpty) continue; // Prioritize DB history
        final key = 'dose_history_${med.id}';
        final jsonList = prefs.getStringList(key);
        if (jsonList != null) {
          med.doseHistory.clear();
          for (final jsonStr in jsonList) {
            try {
              final map = jsonDecode(jsonStr);
              med.doseHistory.add(MedicineDoseRecord(
                date: DateTime.parse(map['date']),
                time: map['time'],
                taken: map['taken'],
                takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
              ));
            } catch (e) {}
          }
        }
      }
      _buildTodaySlots();
    });
  }

  Future<void> _saveLocalDoseHistory(MedicineItem med) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'dose_history_${med.id}';
    final jsonList = med.doseHistory.map((r) => jsonEncode({
      'date': r.date.toIso8601String(),
      'time': r.time,
      'taken': r.taken,
      'takenAt': r.takenAt?.toIso8601String(),
    })).toList();
    await prefs.setStringList(key, jsonList);

    // Save to backend database description field
    final scheduleId = int.tryParse(med.id);
    if (scheduleId != null) {
      var baseDesc = med.notes ?? '';
      if (baseDesc.contains('· dose_history:')) {
        baseDesc = baseDesc.split('· dose_history:')[0].trim();
      } else if (baseDesc.isEmpty) {
        baseDesc = 'Nhóm: ${med.category} · Tổng số viên thuốc: ${med.stockRemaining}';
      }
      final newDesc = '$baseDesc · dose_history: ${jsonEncode(med.doseHistory.map((r) => {
        'date': r.date.toIso8601String(),
        'time': r.time,
        'taken': r.taken,
        'takenAt': r.takenAt?.toIso8601String(),
      }).toList())}';

      await ApiService.updateMedication(
        scheduleId: scheduleId,
        name: med.name,
        dosage: med.dosage,
        instruction: med.instruction,
        time: med.times.isNotEmpty ? med.times.first : '08:00',
        frequency: med.frequency,
        description: newDesc,
        startDate: med.startDate.toIso8601String().substring(0, 10),
        endDate: med.endDate.toIso8601String().substring(0, 10),
      );
    }
  }

  void _buildTodaySlots() {
    final slots = <TodayDoseSlot>[];
    final today = DateTime.now();
    for (final med in _medicines) {
      if (!med.isActive) continue;
      if (med.startDate.isAfter(today) || med.endDate.isBefore(today)) continue;
      // Skip medicines without a valid name to avoid empty slots
      if (med.name.trim().isEmpty) continue;
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
    _elderlyProvider.removeListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.removeListener(_onDataChanged);
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

  /// Calculate expected number of doses from startDate to today
  int _expectedDoses(MedicineItem med) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
    final end = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
    if (start.isAfter(today)) return 0;
    final effectiveEnd = end.isBefore(today) ? end : today;
    final daysDiff = effectiveEnd.difference(start).inDays + 1; // inclusive
    if (daysDiff <= 0) return 0;

    // Count only times that have already passed today
    int dosesToday = 0;
    if (!effectiveEnd.isBefore(today)) {
      // effectiveEnd == today
      for (final t in med.times) {
        final parts = t.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (h < now.hour || (h == now.hour && m <= now.minute)) {
          dosesToday++;
        }
      }
    }

    // Past days = (daysDiff - 1) * timesPerDay + dosesToday
    final pastDays = daysDiff - 1; // days before today
    return pastDays * med.times.length + dosesToday;
  }

  double _overallAdherence() {
    int total = 0, taken = 0;
    for (final med in _medicines) {
      if (!med.isActive) continue;
      final expected = _expectedDoses(med);
      total += expected;
      taken += med.doseHistory.where((r) => r.taken).length;
    }
    // Ensure taken doesn't exceed total
    if (taken > total) taken = total;
    return total == 0 ? 1.0 : taken / total;
  }

  // ── UI Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0EA5E9),
        child: NestedScrollView(
          headerSliverBuilder: (ctx, inner) => [_buildAppBar()],
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ElderlySwitcherBar(provider: _elderlyProvider),
              ),
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
      ),
      floatingActionButton: _isMultiSelectMode ? null : FloatingActionButton(
        onPressed: () => MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: () => _loadMedicationSchedules(_selectedElderlyId!)),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
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
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Future<void> _syncMedications() async {
    if (_selectedElderlyId != null) {
      await _loadMedicationSchedules(_selectedElderlyId!);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 – HÔM NAY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayTab() {
    final confirmedCount = _todaySlots.where((s) => s.confirmed).length;
    final total = _todaySlots.length;
    final progress = total > 0 ? confirmedCount / total : 0.0;

    return RefreshIndicator(
      onRefresh: _syncMedications,
      color: const Color(0xFF0EA5E9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // LỊCH UỐNG THUỐC HÔM NAY Header
          Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Color(0xFF0EA5E9), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LỊCH UỐNG THUỐC HÔM NAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('Hôm nay còn ${total - confirmedCount} thuốc cần uống', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tiến độ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            Text('$confirmedCount / $total thuốc đã uống', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
          ],
        ),
        const SizedBox(height: 8),
        // Visual Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF34D399),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 24),

        // Alerts
        ..._buildAlertCards(),

        // Timeline List
        if (_todaySlots.isEmpty)
          _buildEmptyState('Không có lịch uống thuốc hôm nay', Icons.check_circle_outline_rounded)
        else
          _buildTodayTimelineList(),
      ],
    ),
  );
}

  Widget _buildTodayTimelineList() {
    // Sort logic: Unconfirmed first (sorted by time), then confirmed (sorted by time)
    final unconfirmed = _todaySlots.where((s) => !s.confirmed).toList();
    final confirmed = _todaySlots.where((s) => s.confirmed).toList();
    
    // Sort each group by time
    unconfirmed.sort((a, b) => a.time.compareTo(b.time));
    confirmed.sort((a, b) => a.time.compareTo(b.time));
    
    final sortedSlots = [...unconfirmed, ...confirmed];

    return Column(
      children: List.generate(sortedSlots.length, (index) {
        final slot = sortedSlots[index];
        final isLast = index == sortedSlots.length - 1;
        return _buildTodayTimelineCard(slot, isLast);
      }),
    );
  }

  Widget _buildTodayTimelineCard(TodayDoseSlot slot, bool isLast) {
    final now = TimeOfDay.now();
    final parts = slot.time.split(':');
    final slotHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final slotMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final isPast = slotHour < now.hour || (slotHour == now.hour && slotMin <= now.minute);
    
    final isConfirmed = slot.confirmed;
    final badgeColor = isConfirmed ? const Color(0xFF16A34A) : (isPast ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9));
    final bgColor = isConfirmed ? const Color(0xFFF0FDF4) : Colors.white;
    final borderColor = isConfirmed ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slot.time,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    if (!isConfirmed)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.medicine.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isConfirmed ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                                  decoration: isConfirmed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${slot.medicine.dosage} · ${slot.medicine.instruction}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showMedicineDetail(slot.medicine),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status row / Remind button
                    if (isConfirmed)
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                               final today = DateTime.now();
                               final existing = slot.medicine.doseHistory.where((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day && r.time == slot.time).toList();
                               final takenAt = existing.isNotEmpty ? existing.first.takenAt : null;
                               final timeStr = takenAt != null ? ' lúc ${takenAt.hour.toString().padLeft(2, '0')}:${takenAt.minute.toString().padLeft(2, '0')}' : '';
                               return Text('Đã uống$timeStr', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold));
                            }
                          )
                        ],
                      )
                    else if (isPast)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 20),
                              SizedBox(width: 8),
                              Text('Quá giờ uống', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sendReminder(slot),
                            icon: const Icon(Icons.notifications_active_rounded, size: 16),
                            label: const Text('Nhắc nhở'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              foregroundColor: const Color(0xFFEF4444),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 8),
                              Text('Chưa uống', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sendReminder(slot),
                            icon: const Icon(Icons.notifications_active_rounded, size: 16),
                            label: const Text('Nhắc nhở'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFBEB),
                              foregroundColor: const Color(0xFFD97706),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendReminder(TodayDoseSlot slot) async {
    final elderlyId = ElderlyProvider.instance.selectedElderlyId;
    if (elderlyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn người cao tuổi.')),
      );
      return;
    }

    final success = await ApiService.sendReminder(
      elderlyId: elderlyId,
      medicationName: slot.medicine.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.notifications_active_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'Đã gửi thông báo nhắc uống ${slot.medicine.name}!'
                    : 'Gửi thông báo thất bại. Thử lại sau.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
    final parts = slot.time.split(':');
    final slotHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final slotMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
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
                        parts.isNotEmpty ? parts[0] : '00',
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
                        parts.length > 1 ? parts[1] : '00',
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
                padding: const EdgeInsets.all(10),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slot.medicine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${slot.medicine.dosage} · ${slot.medicine.instruction}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Compact status chip (tappable) + small info icon
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: slot.confirmed
                              ? null
                              : () {
                                  setState(() {
                                    slot.confirmed = true;
                                    final today = DateTime.now();
                                    final existing = slot.medicine.doseHistory
                                        .where((r) =>
                                            r.date.year == today.year &&
                                            r.date.month == today.month &&
                                            r.date.day == today.day &&
                                            r.time == slot.time)
                                        .toList();
                                    if (existing.isEmpty) {
                                      slot.medicine.doseHistory.add(
                                        MedicineDoseRecord(
                                          date: today,
                                          time: slot.time,
                                          taken: true,
                                          takenAt: today,
                                        ),
                                      );
                                    } else {
                                      existing.first.taken = true;
                                      existing.first.takenAt = today;
                                    }
                                  });
                                  _saveLocalDoseHistory(slot.medicine);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF16A34A),
                                      content: Text('✓ Đã xác nhận uống ${slot.medicine.name}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: slot.confirmed
                                  ? const Color(0xFFDCFCE7)
                                  : isPast
                                      ? const Color(0xFFFFF1F2)
                                      : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: slot.confirmed
                                    ? const Color(0xFF16A34A)
                                    : isPast
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF0EA5E9),
                              ),
                            ),
                            child: Text(
                              slot.confirmed
                                  ? 'Đã uống'
                                  : isPast
                                      ? 'Quên'
                                      : 'Chưa',
                              style: TextStyle(
                                  color: slot.confirmed
                                      ? const Color(0xFF16A34A)
                                      : isPast
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF0EA5E9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showMedicineDetail(slot.medicine),
                          child: Container(
                            padding: const EdgeInsets.all(6),
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
      final matchCat = _filterCategory == 'all' || m.category == _filterCategory;
      final matchSearch = _searchQuery.isEmpty || m.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
    
    final todayCount = _todaySlots.length;
    final takenCount = _todaySlots.where((s) => s.confirmed).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Thống kê tổng quan (Overview Stats)
              Row(
                children: [
                  Expanded(child: _buildOverviewStatCard('Tổng thuốc', '${_medicines.length}', Icons.medication_rounded, const Color(0xFF0EA5E9))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOverviewStatCard('Hôm nay', '$todayCount thuốc', Icons.today_rounded, const Color(0xFFD97706))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOverviewStatCard('Đã uống', '$takenCount', Icons.check_circle_rounded, const Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search
              _buildSearchBar(),
              const SizedBox(height: 12),
              // Section label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('DANH SÁCH THUỐC (${filtered.length})', Icons.medication_rounded),
                  if (_isMultiSelectMode)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedMedIds.length == filtered.length) {
                            _selectedMedIds.clear();
                          } else {
                            _selectedMedIds.addAll(filtered.map((m) => m.id));
                          }
                        });
                      },
                      child: Text(_selectedMedIds.length == filtered.length ? 'Bỏ chọn' : 'Chọn tất cả'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              
              // List
              if (filtered.isEmpty)
                _buildEmptyState('Không tìm thấy thuốc', Icons.search_off_rounded)
              else
                ...filtered.map((m) => _buildModernMedicineCard(m)),
            ],
          ),
        ),
        
        // Multi-Select Action Bar
        if (_isMultiSelectMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _isMultiSelectMode = false;
                      _selectedMedIds.clear();
                    }),
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedMedIds.isEmpty ? null : () {
                      showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Xác nhận'),
                          content: Text('Xóa ${_selectedMedIds.length} thuốc đã chọn?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Hủy')),
                            TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444)))),
                          ],
                        ),
                      ).then((ok) async {
                        if (ok == true) {
                          // Show loading
                          final toDelete = List<String>.from(_selectedMedIds);
                          setState(() {
                            _isMultiSelectMode = false;
                            _selectedMedIds.clear();
                          });
                          // Call backend delete API for each selected ID
                          int deleted = 0;
                          for (final id in toDelete) {
                            final schedId = int.tryParse(id);
                            if (schedId != null) {
                              final ok = await ApiService.deleteMedication(schedId);
                              if (ok) deleted++;
                            }
                          }
                          if (mounted) {
                            // Reload from server so elderly side is also in sync
                            if (_selectedElderlyId != null) {
                              await _loadMedicationSchedules(_selectedElderlyId!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text('Đã xóa $deleted/${toDelete.length} lịch uống thuốc'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text('Xóa (${_selectedMedIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tên thuốc...',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = ['all', 'huyet_ap', 'tieu_duong', 'tim_mach', 'vitamin', 'khac'];
    return SizedBox(
      height: 40,
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (cat != 'all') ...[
                    Icon(_categoryIcon(cat), size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _categoryLabel(cat),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernMedicineCard(MedicineItem med) {
    final time = med.times.isNotEmpty ? med.times.first : '--:--';
    final isSelected = _selectedMedIds.contains(med.id);
    
    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
        boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (_isMultiSelectMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFCBD5E1),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_categoryIcon(med.category), color: _categoryColor(med.category), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$time • ${med.dosage}', style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(med.instruction, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );

    if (_isMultiSelectMode) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMedIds.remove(med.id);
            } else {
              _selectedMedIds.add(med.id);
            }
          });
        },
        child: cardContent,
      );
    }

    return Dismissible(
      key: Key(med.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe right to left -> Edit
          MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: () => _loadMedicationSchedules(_selectedElderlyId!), initialName: med.name, initialDosage: med.dosage, initialInstruction: med.instruction, initialTime: med.times.isNotEmpty ? med.times.first : null, editScheduleId: int.tryParse(med.id));
          return false; // Don't dismiss
        } else {
          // Swipe left to right -> Delete
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Xác nhận'),
              content: Text('Xóa thuốc ${med.name}?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Hủy')),
                TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444)))),
              ],
            ),
          );
          if (ok == true) {
            final schedId = int.tryParse(med.id);
            if (schedId != null) {
              final deleted = await ApiService.deleteMedication(schedId);
              if (deleted && mounted) {
                // Reload from server to sync Elderly side
                if (_selectedElderlyId != null) {
                  await _loadMedicationSchedules(_selectedElderlyId!);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa ${med.name}'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return true;
              }
            }
            return false;
          }
          return false;
        }
      },
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _isMultiSelectMode = true;
            _selectedMedIds.add(med.id);
          });
        },
        onTap: () => _showMedicineDetail(med),
        child: cardContent,
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
                    _miniStat('Đúng giờ', '${(adherence * 100).round()}%',
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
    final total = _expectedDoses(med);
    int taken = med.doseHistory.where((r) => r.taken).length;
    if (taken > total) taken = total;
    final pct = total == 0 ? 1.0 : taken / total;
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
                        MedicationDialogHelper.showAddMedicationDialog(
                            context: context,
                            elderlyId: _selectedElderlyId!,
                            onSuccess: () =>
                                _loadMedicationSchedules(_selectedElderlyId!),
                            initialName: med.name,
                            initialDosage: med.dosage,
                            initialInstruction: med.instruction,
                            initialTime: med.times.isNotEmpty
                                ? med.times.first
                                : null,
                            editScheduleId: int.tryParse(med.id));
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
                      onPressed: () async {
                        Navigator.pop(context);
                        final scheduleId = int.tryParse(med.id);
                        if (scheduleId != null) {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xác nhận xóa'),
                                  content: const Text(
                                      'Bạn có chắc chắn muốn xóa lịch uống thuốc này?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (confirm) {
                            final success = await ApiService.deleteMedication(
                                scheduleId);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã xóa thành công!'),
                                    backgroundColor: Colors.green),
                              );
                              // _loadMedicationSchedules is automatically called by dataRefreshTrigger
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Xóa thất bại!'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
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
  


  void _showEditDeleteMedicationDialog(dynamic schedule) {
    final med = schedule['medication'] ?? {};

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${med['name'] ?? 'Thuốc'} — ${schedule['time']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${med['instruction'] ?? ''} · ${med['dosage'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              title: const Text(
                'Chỉnh sửa lịch uống',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final scheduleId = schedule['schedule_id'] ?? schedule['id'];
                MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: () => _loadMedicationSchedules(_selectedElderlyId!), 
                  initialName: med['name'],
                  initialDosage: med['dosage'],
                  initialInstruction: med['instruction'],
                  initialTime: schedule['time'],
                  initialDescription: med['description'],
                  editScheduleId: scheduleId != null
                      ? int.tryParse(scheduleId.toString())
                      : null,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              title: const Text(
                'Xóa lịch uống thuốc',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              onTap: () async {
                final ok = await ApiService.deleteMedication(
                  schedule['schedule_id'],
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa thành công.')),
                    );
                    if (_selectedElderlyId != null) { await _loadMedicationSchedules(_selectedElderlyId!); }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi xóa.')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
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

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

}


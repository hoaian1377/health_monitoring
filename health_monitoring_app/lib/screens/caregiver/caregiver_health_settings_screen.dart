import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/api_service.dart';
import '../../utils/elderly_provider.dart';
import 'widgets/elderly_switcher_bar.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Elderly Provider (centralized) ──
  final ElderlyProvider _elderlyProvider = ElderlyProvider.instance;

  // Proxy getters so existing code continues to work with minimal changes
  List<Map<String, dynamic>> get _elderlyList => _elderlyProvider.elderlyList;
  int? get _selectedElderlyId {
    if (ApiService.currentRole == 'elderly') {
      return ApiService.currentAccountId;
    }
    return _elderlyProvider.selectedElderlyId;
  }

  Map<String, dynamic>? _currentElderly;
  bool _isLoading = true;

  // ── Medical profile ──
  String _bloodType = 'N/A';
  List<String> _conditions = [];
  List<String> _allergies = [];

  // ── History data ──
  List<dynamic> _appointments = [];
  List<dynamic> _medicationSchedules = [];
  List<dynamic> _medicalDocuments = [];
  List<dynamic> _healthMetrics = [];

  // ── Filters ──
  String _selectedMedFilter = 'Tuần này';
  DateTime? _selectedDateFilter;
  DateTime? _appointmentFilterDate;
  final _searchApptCtrl = TextEditingController();

  // ── Document filters ──
  int _docFilterIndex = 0;
  final List<String> _docFilters = ['Tất cả', 'Toa thuốc', 'Xét nghiệm'];
  final _searchDocCtrl = TextEditingController();

  // ── Add treatment controllers ──
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _resultController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _elderlyProvider.addListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.addListener(_onDataChanged);
    _fetchAllData();
  }

  void _onElderlyChanged() {
    if (mounted) _fetchAllData();
  }

  void _onDataChanged() {
    if (mounted) _fetchAllData();
  }

  @override
  void dispose() {
    _elderlyProvider.removeListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.removeListener(_onDataChanged);
    _tabController.dispose();
    _searchApptCtrl.dispose();
    _searchDocCtrl.dispose();
    _hospitalController.dispose();
    _doctorController.dispose();
    _diagnosisController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    final elderlyId = _selectedElderlyId;
    if (elderlyId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    // Use elderly profile data from provider or fetch it if role is elderly
    Map<String, dynamic>? elderly;
    if (ApiService.currentRole == 'elderly') {
      final res = await ApiService.getElderlyProfile(elderlyId);
      if (res['success'] == true) {
        elderly = res['data'];
      }
    } else {
      elderly = _elderlyProvider.selectedElderly;
    }

    if (elderly != null && elderly.isNotEmpty) {
      _currentElderly = elderly;
      _bloodType =
          elderly['blood_type']?.toString().isNotEmpty == true
              ? elderly['blood_type']
              : 'N/A';
      final condStr = elderly['underlying_conditions']?.toString() ?? '';
      _conditions = condStr.isNotEmpty
          ? condStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : [];
      final allgStr = elderly['allergies']?.toString() ?? '';
      _allergies = allgStr.isNotEmpty
          ? allgStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : [];
    }

    // Fetch appointments, medications, documents, metrics
    final rawAppts = await ApiService.getAppointments(elderlyId);
    final confirmedAppts = rawAppts.where((a) => a['is_confirmed'] == true).toList();
    final meds =
        await ApiService.getElderlyMedicationSchedule(elderlyId);
    final docs =
        await ApiService.getMedicalDocument(elderlyId: elderlyId);
    final metrics = await ApiService.getHealthMetrics(elderlyId);

    if (mounted) {
      setState(() {
        _appointments = confirmedAppts;
        _medicationSchedules = meds;
        _medicalDocuments = docs;
        _healthMetrics = metrics;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (ApiService.currentRole != 'elderly') {
      await _elderlyProvider.loadElderlyList();
    }
    if (_selectedElderlyId != null) {
      await _fetchAllData();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0EA5E9),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: ApiService.currentRole == 'elderly'
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ElderlySwitcherBar(provider: _elderlyProvider),
                  ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAppointmentsTab(),
                  _buildMedicineTab(),
                  _buildDocumentsTab(),
                ],
              ),
      ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x330EA5E9),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hồ sơ bệnh án',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Quản lý toàn bộ hồ sơ y tế',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Tab Bar ──
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Khám bệnh'),
                Tab(text: 'Thuốc'),
                Tab(text: 'Tài liệu'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: TỔNG QUAN
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        children: [
          // ── Quick stats ──
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  icon: Icons.medical_services_rounded,
                  label: 'Lần khám',
                  value: '${_appointments.length}',
                  color: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  icon: Icons.medication_rounded,
                  label: 'Thuốc đang dùng',
                  value: '${_medicationSchedules.length}',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  icon: Icons.description_rounded,
                  label: 'Tài liệu',
                  value: '${_medicalDocuments.length}',
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF3E8FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Thông tin y tế cơ bản ──
          _buildSectionCard(
            title: 'Thông tin y tế cơ bản',
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFDC2626),
            child: Column(
              children: [
                _infoTile('🩸', 'Nhóm máu', _bloodType,
                    const Color(0xFFFFEBEB), const Color(0xFFC81E1E),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      onPressed: _showEditBloodTypeDialog,
                    )),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _infoTile('🤒', 'Bệnh nền', _conditions.isEmpty ? 'Không có' : _conditions.join(', '),
                    const Color(0xFFFEE2E2), const Color(0xFFB91C1C),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      onPressed: _showEditConditionsDialog,
                    )),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _infoTile('⚠️', 'Dị ứng', _allergies.isEmpty ? 'Không có' : _allergies.join(', '),
                    const Color(0xFFFEF3C7), const Color(0xFFD97706),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      onPressed: _showEditAllergiesDialog,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),



          // ── Chỉ số sức khỏe gần nhất ──
          if (_healthMetrics.isNotEmpty)
            _buildSectionCard(
              title: 'Chỉ số gần nhất',
              icon: Icons.monitor_heart_rounded,
              iconColor: const Color(0xFF0EA5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLatestMetricRow(
                      'Huyết áp',
                      _healthMetrics.first['blood_pressure']?.toString() ??
                          '--',
                      'mmHg',
                      Icons.favorite_border_rounded,
                      const Color(0xFFDC2626),
                      const Color(0xFFFFEBEB),
                    ),
                    const SizedBox(height: 10),
                    _buildLatestMetricRow(
                      'Nhịp tim',
                      _healthMetrics.first['heart_rate']?.toString() ?? '--',
                      'bpm',
                      Icons.monitor_heart_rounded,
                      const Color(0xFFE11D48),
                      const Color(0xFFFFE4E6),
                    ),
                    const SizedBox(height: 10),
                    _buildLatestMetricRow(
                      'Đường huyết',
                      _healthMetrics.first['blood_sugar']?.toString() ?? '--',
                      'mmol/L',
                      Icons.water_drop_rounded,
                      const Color(0xFF0284C7),
                      const Color(0xFFE0F2FE),
                    ),
                    const SizedBox(height: 10),
                    _buildLatestMetricRow(
                      'Nhiệt độ',
                      _healthMetrics.first['temperature']?.toString() ?? '--',
                      '°C',
                      Icons.thermostat_rounded,
                      const Color(0xFFEA580C),
                      const Color(0xFFFFEDD5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMetricRow(String label, String value, String unit,
      IconData icon, Color color, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
        ),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: KHÁM BỆNH
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAppointmentsTab() {

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchApptCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm bệnh viện, bác sĩ...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats row ──
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng số lần khám',
                  '${_appointments.length} lần',
                  const Color(0xFF16A34A),
                  Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Bác sĩ theo dõi',
                  '${_appointments.map((a) => a['doctor_name']).where((n) => n != null && n.toString().isNotEmpty).toSet().length} bác sĩ',
                  const Color(0xFF0EA5E9),
                  Icons.person_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Add treatment button ──
          GestureDetector(
            onTap: _showAddTreatmentHistorySheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                    const Color(0xFF38BDF8).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFF0EA5E9), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Thêm kết quả điều trị',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── List header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CÁC LẦN KHÁM GẦN NHẤT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              _buildDateFilterChip(),
            ],
          ),
          const SizedBox(height: 14),

          // ── Appointments list ──
          Builder(builder: (context) {
            var filteredAppts = List<Map<String, dynamic>>.from(_appointments);
            final query = _searchApptCtrl.text.toLowerCase();

            if (query.isNotEmpty) {
              filteredAppts = filteredAppts.where((appt) {
                final hospital =
                    appt['location']?.toString().toLowerCase() ?? '';
                final doctor =
                    appt['doctor_name']?.toString().toLowerCase() ?? '';
                return hospital.contains(query) || doctor.contains(query);
              }).toList();
            }

            if (_appointmentFilterDate != null) {
              String filterStr =
                  DateFormat('yyyy-MM-dd').format(_appointmentFilterDate!);
              filteredAppts = filteredAppts.where((appt) {
                return appt['appointment_date']
                        ?.toString()
                        .startsWith(filterStr) ==
                    true;
              }).toList();
            }

            if (filteredAppts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có lịch sử khám bệnh',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filteredAppts.map((appt) {
                final dateStr = appt['appointment_date']?.toString();
                final timeStr =
                    appt['appointment_time']?.toString().substring(0, 5);
                String formattedDate = 'Không rõ';
                if (dateStr != null && dateStr.length >= 10) {
                  try {
                    formattedDate = DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(dateStr));
                  } catch (_) {}
                }
                if (timeStr != null &&
                    timeStr.isNotEmpty &&
                    timeStr != "null") {
                  formattedDate = '$timeStr $formattedDate';
                }

                final hospital =
                    appt['location']?.toString().isNotEmpty == true
                        ? appt['location']
                        : 'Phòng khám / Bệnh viện';
                final doctor =
                    appt['doctor_name']?.toString().isNotEmpty == true
                        ? appt['doctor_name']
                        : 'Bác sĩ';
                String resultText =
                    appt['note']?.toString() ?? 'Không có ghi chú';
                List<dynamic> docs = appt['documents'] ?? [];
                String diagnosis = appt['diagnosis']?.toString() ?? '';
                int? appointmentId =
                    appt['appointment_id'] ?? appt['appointmentid'];

                return _buildAppointmentCard(
                  date: formattedDate,
                  hospital: hospital,
                  doctor: doctor,
                  diagnosis: diagnosis,
                  result: resultText,
                  documents: docs,
                  appointmentId: appointmentId,
                  isConfirmed: appt['is_confirmed'] == true,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _appointmentFilterDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _appointmentFilterDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _appointmentFilterDate == null
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: _appointmentFilterDate == null
                  ? const Color(0xFF64748B)
                  : const Color(0xFF0EA5E9),
            ),
            const SizedBox(width: 6),
            Text(
              _appointmentFilterDate == null
                  ? 'Lọc theo ngày'
                  : DateFormat('dd/MM/yyyy').format(_appointmentFilterDate!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _appointmentFilterDate == null
                    ? const Color(0xFF64748B)
                    : const Color(0xFF0EA5E9),
              ),
            ),
            if (_appointmentFilterDate != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _appointmentFilterDate = null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFF0EA5E9)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String date,
    required String hospital,
    required String doctor,
    required String result,
    required String diagnosis,
    required int? appointmentId,
    List<dynamic> documents = const [],
    bool isConfirmed = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDetailsSheet(
            date, hospital, doctor, diagnosis, result, documents, appointmentId, isConfirmed,
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hospital,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.person_rounded,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(doctor,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(date,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B))),
                        if (documents.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${documents.length} File',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF0284C7),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFCBD5E1), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3: THUỐC
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMedicineTab() {
    int totalTaken = 0;
    int totalMissed = 0;
    final Map<String, List<Map<String, dynamic>>> recordsByDate = {};

    final now = DateTime.now();
    DateTime? filterStartDate;
    if (_selectedMedFilter == 'Tuần này') {
      filterStartDate = now.subtract(const Duration(days: 7));
    } else if (_selectedMedFilter == 'Tháng này') {
      filterStartDate = now.subtract(const Duration(days: 30));
    }

    for (var schedule in _medicationSchedules) {
      final med = schedule['medication'] ?? {};
      final name = med['name']?.toString() ?? 'Không rõ';
      final description = med['description']?.toString() ?? '';
      if (description.contains('· dose_history:')) {
        final parts = description.split('· dose_history:');
        try {
          final list = jsonDecode(parts[1].trim()) as List;
          for (final item in list) {
            final dateStr = item['date'].toString();
            final dateObj = DateTime.tryParse(dateStr);
            if (dateObj != null) {
              if (_selectedDateFilter != null) {
                if (dateObj.year != _selectedDateFilter!.year ||
                    dateObj.month != _selectedDateFilter!.month ||
                    dateObj.day != _selectedDateFilter!.day) {
                  continue;
                }
              } else if (filterStartDate != null) {
                final filterDateOnly = DateTime(
                    filterStartDate.year,
                    filterStartDate.month,
                    filterStartDate.day);
                if (dateObj.isBefore(filterDateOnly)) continue;
              }
            }
            final taken = item['taken'] == true;
            if (taken) {
              totalTaken++;
            } else {
              totalMissed++;
            }
            if (!recordsByDate.containsKey(dateStr)) {
              recordsByDate[dateStr] = [];
            }
            recordsByDate[dateStr]!.add({
              'time': item['time'].toString().substring(0, 5),
              'name': name,
              'status': taken ? 'Đã uống' : 'Bỏ lỡ',
              'isCompleted': taken,
            });
          }
        } catch (e) {
          // skip parse errors
        }
      }
    }

    int total = totalTaken + totalMissed;
    String percentage =
        total > 0 ? '${(totalTaken / total * 100).round()}%' : '0%';

    final sortedDates = recordsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int uniqueDays = sortedDates.length;
    String averagePerDay = '0 lần/ngày';
    if (uniqueDays > 0) {
      double avg = totalTaken / uniqueDays;
      averagePerDay = avg == avg.toInt()
          ? '${avg.toInt()} lần/ngày'
          : '${avg.toStringAsFixed(1)} lần/ngày';
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ──
          Row(
            children: [
              Expanded(child: _buildMedFilterChip('Tuần này')),
              const SizedBox(width: 8),
              Expanded(child: _buildMedFilterChip('Tháng này')),
              const SizedBox(width: 8),
              Expanded(child: _buildMedFilterChip('Tất cả')),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _selectedDateFilter != null
                      ? const Color(0xFF0EA5E9)
                      : Colors.white,
                  border: Border.all(
                    color: _selectedDateFilter != null
                        ? Colors.transparent
                        : const Color(0xFFBAE6FD),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    if (_selectedDateFilter != null) {
                      setState(() {
                        _selectedDateFilter = null;
                        _selectedMedFilter = 'Tuần này';
                      });
                      return;
                    }
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDateFilter = date;
                        _selectedMedFilter = '';
                      });
                    }
                  },
                  icon: Icon(
                    _selectedDateFilter != null
                        ? Icons.clear_rounded
                        : Icons.calendar_month_rounded,
                    color: _selectedDateFilter != null
                        ? Colors.white
                        : const Color(0xFF0EA5E9),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stats grid ──
          Row(
            children: [
              Expanded(
                child: Column(children: [
                  _buildMedMetricCard(
                      'Đã uống', '$totalTaken lần', const Color(0xFF16A34A)),
                  const SizedBox(height: 10),
                  _buildMedMetricCard(
                      'Bỏ lỡ', '$totalMissed lần', const Color(0xFFEF4444)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(children: [
                  _buildMedMetricCard(
                      'Tỉ lệ', percentage, const Color(0xFF0EA5E9)),
                  const SizedBox(height: 10),
                  _buildMedMetricCard(
                      'Trung bình', averagePerDay, const Color(0xFF6B7280)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'LỊCH SỬ DÙNG THUỐC',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          if (sortedDates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.medication_rounded,
                      color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 12),
                  const Text('Chưa có dữ liệu uống thuốc',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            )
          else
            ...sortedDates.map((dateStr) {
              final dateRecords = recordsByDate[dateStr]!;
              dateRecords.sort((a, b) => a['time'].compareTo(b['time']));

              String label = dateStr;
              if (dateStr == todayStr) {
                label =
                    'Hôm nay - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))}';
              } else if (dateStr == yesterdayStr) {
                label =
                    'Hôm qua - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))}';
              } else {
                label =
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ...dateRecords.map((record) => _buildMedHistoryItem(
                        time: record['time'],
                        name: record['name'],
                        status: record['status'],
                        isCompleted: record['isCompleted'] == true,
                      )),
                  const SizedBox(height: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMedFilterChip(String label) {
    bool isSelected =
        _selectedMedFilter == label && _selectedDateFilter == null;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMedFilter = label;
          _selectedDateFilter = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFBAE6FD),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color:
                    isSelected ? Colors.white : const Color(0xFF0EA5E9),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildMedMetricCard(String title, String value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: valueColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildMedHistoryItem({
    required String time,
    required String name,
    required String status,
    bool isCompleted = false,
  }) {
    Color statusColor =
        isCompleted ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    Color iconBg =
        isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEB);
    IconData icon =
        isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4: TÀI LIỆU
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDocumentsTab() {
    final parsedDocs = _medicalDocuments.map((doc) {
      String type = doc['document_type'] ?? 'Khác';
      if (!['Toa thuốc', 'Xét nghiệm'].contains(type)) type = 'Toa thuốc';
      String date = 'N/A';
      if (doc['upload_at'] != null) {
        try {
          DateTime dt = DateTime.parse(doc['upload_at']);
          date =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        } catch (_) {}
      }
      String rawUrl = doc['file_url']?.toString() ?? '';
      String fullUrl = '';
      if (rawUrl.isNotEmpty) {
        if (rawUrl.startsWith('http')) {
          fullUrl = rawUrl;
        } else {
          fullUrl = '${ApiService.baseUrl}$rawUrl';
        }
      }
      return {
        'id': doc['medical_documentid'],
        'name': doc['file_url']?.split('/').last ??
            'Tai_lieu_${doc['medical_documentid']}.pdf',
        'date': date,
        'type': type,
        'url': fullUrl,
      };
    }).toList();

    final q = _searchDocCtrl.text.toLowerCase();
    final filtered = parsedDocs.where((d) {
      final matchFilter =
          _docFilterIndex == 0 || d['type'] == _docFilters[_docFilterIndex];
      final matchSearch =
          q.isEmpty || d['name']!.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();

    return Column(
      children: [
        // ── Search + Filters ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchDocCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tài liệu...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: _docFilters.asMap().entries.map((e) {
                  final isActive = _docFilterIndex == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _docFilterIndex = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF64748B))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Document list ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded,
                          color: Colors.grey.shade300, size: 48),
                      const SizedBox(height: 12),
                      const Text('Không tìm thấy tài liệu',
                          style: TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final isToa = doc['type'] == 'Toa thuốc';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isToa
                                  ? const Color(0xFFEBF3FF)
                                  : const Color(0xFFE6FBF3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isToa
                                  ? Icons.receipt_long_rounded
                                  : Icons.science_rounded,
                              color: isToa
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFF0D9488),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name']!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(doc['date']!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isToa
                                        ? const Color(0xFFEBF3FF)
                                        : const Color(0xFFE0F7F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(doc['type']!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isToa
                                              ? const Color(0xFF0EA5E9)
                                              : const Color(0xFF0D9488))),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              _smallIconBtn(Icons.visibility_outlined,
                                  const Color(0xFF0EA5E9),
                                  const Color(0xFFEBF3FF), () async {
                                final url = Uri.parse(doc['url']!);
                                try {
                                  await launchUrl(url);
                                } catch (_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Không thể mở tài liệu này')),
                                    );
                                  }
                                }
                              }),
                              const SizedBox(height: 8),
                              _smallIconBtn(Icons.download_rounded,
                                  const Color(0xFF16A34A),
                                  const Color(0xFFE6FBF3), () async {
                                final url = Uri.parse(doc['url']!);
                                try {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Không thể tải xuống tài liệu này')),
                                    );
                                  }
                                }
                              }),
                              const SizedBox(height: 8),
                              _smallIconBtn(Icons.delete_outline_rounded,
                                  const Color(0xFFEF4444),
                                  const Color(0xFFFEF2F2), () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xóa tài liệu'),
                                    content: const Text('Bạn có chắc chắn muốn xóa tài liệu này không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final docId = doc['id'] as int?;
                                          if (docId != null) {
                                            bool success = await ApiService.deleteMedicalDocument(docId);
                                            if (success) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Xóa thành công!')),
                                                );
                                                _fetchAllData();
                                              }
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Có lỗi xảy ra khi xóa.')),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _smallIconBtn(
      IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: iconColor)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(
      String emoji, String label, String value, Color bg, Color color, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _conditionPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF791F1F),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _allergyPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF633806),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _addButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }



  // ═══════════════════════════════════════════════════════════════════════
  // DIALOGS & BOTTOM SHEETS
  // ═══════════════════════════════════════════════════════════════════════

  void _showEditStringDialog(String title, String hint, String initialValue, Future<void> Function(String) onSave) {
    final ctrl = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final val = ctrl.text.trim();
                      if (val.isNotEmpty || initialValue.isNotEmpty) {
                        await onSave(val);
                      }
                      if (mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBloodTypeDialog() {
    String selectedBloodType = _bloodType == 'N/A' || _bloodType.isEmpty ? 'A' : _bloodType;
    final bloodTypes = ['A', 'B', 'AB', 'O'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chỉnh sửa nhóm máu',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: bloodTypes.map((type) {
                    final isSelected = selectedBloodType == type;
                    return GestureDetector(
                      onTap: () => setStateSB(() => selectedBloodType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                      child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (_currentElderly != null) {
                          setState(() => _bloodType = selectedBloodType);
                          await ApiService.updateElderly(
                            elderlyId: _currentElderly!['id'],
                            fullname: _currentElderly!['fullname'],
                            dob: _currentElderly!['dob'] ?? '',
                            gender: _currentElderly!['gender'],
                            medicalNote: _currentElderly!['medical_note'] ?? '',
                            bloodType: _bloodType,
                            allergies: _allergies.join(', '),
                            underlyingConditions: _conditions.join(', '),
                          );
                          await _elderlyProvider.loadElderlyList();
                        }
                        if (mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showEditConditionsDialog() {
    _showEditStringDialog('Chỉnh sửa bệnh nền', 'Nhập các bệnh nền (cách nhau bằng dấu phẩy)...', _conditions.join(', '), (value) async {
      if (_currentElderly != null) {
        setState(() {
          _conditions = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        });
        await ApiService.updateElderly(
          elderlyId: _currentElderly!['id'],
          fullname: _currentElderly!['fullname'],
          dob: _currentElderly!['dob'] ?? '',
          gender: _currentElderly!['gender'],
          medicalNote: _currentElderly!['medical_note'] ?? '',
          bloodType: _bloodType,
          allergies: _allergies.join(', '),
          underlyingConditions: _conditions.join(', '),
        );
        if (ApiService.currentRole != 'elderly') {
          await _elderlyProvider.loadElderlyList();
        }
      }
    });
  }

  void _showEditAllergiesDialog() {
    _showEditStringDialog('Chỉnh sửa dị ứng', 'Nhập các chất dị ứng (cách nhau bằng dấu phẩy)...', _allergies.join(', '), (value) async {
      if (_currentElderly != null) {
        setState(() {
          _allergies = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        });
        await ApiService.updateElderly(
          elderlyId: _currentElderly!['id'],
          fullname: _currentElderly!['fullname'],
          dob: _currentElderly!['dob'] ?? '',
          gender: _currentElderly!['gender'],
          medicalNote: _currentElderly!['medical_note'] ?? '',
          bloodType: _bloodType,
          allergies: _allergies.join(', '),
          underlyingConditions: _conditions.join(', '),
        );
        if (ApiService.currentRole != 'elderly') {
          await _elderlyProvider.loadElderlyList();
        }
      }
    });
  }

  void _showAddTreatmentHistorySheet() {
    _hospitalController.clear();
    _doctorController.clear();
    _diagnosisController.clear();
    _resultController.clear();
    List<Map<String, String>> selectedFiles = [];
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    24 +
                    MediaQuery.of(context).padding.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Thêm hồ sơ khám bệnh',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setModalState(() => selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy')
                                    .format(selectedDate)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setModalState(() => selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(selectedTime.format(context)),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                        'Bệnh viện / Cơ sở y tế', _hospitalController),
                    const SizedBox(height: 16),
                    _buildInputField(
                        'Bác sĩ điều trị', _doctorController),
                    const SizedBox(height: 16),
                    _buildInputField(
                        'Chẩn đoán bệnh', _diagnosisController),
                    const SizedBox(height: 16),
                    _buildInputField(
                        'Kết quả / Ghi chú thêm', _resultController,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tài liệu đính kèm',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B))),
                        TextButton.icon(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: [
                                'pdf', 'jpg', 'jpeg', 'png'
                              ],
                              allowMultiple: true,
                            );
                            if (result != null) {
                              setModalState(() {
                                for (var file in result.files) {
                                  if (file.path != null) {
                                    selectedFiles.add({
                                      'path': file.path!,
                                      'name': file.name,
                                      'type': 'Kết quả khám bệnh',
                                    });
                                  }
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm file'),
                        ),
                      ],
                    ),
                    if (selectedFiles.isNotEmpty)
                      ...selectedFiles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final file = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file,
                                  color: Color(0xFF94A3B8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(file['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(fontSize: 13)),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: file['type'],
                                        isDense: true,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0EA5E9)),
                                        items: [
                                          'Kết quả khám bệnh',
                                          'Toa thuốc',
                                          'Xét nghiệm máu',
                                          'Siêu âm',
                                          'Khác'
                                        ]
                                            .map((t) => DropdownMenuItem(
                                                value: t, child: Text(t)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setModalState(() =>
                                                selectedFiles[idx]['type'] =
                                                    val);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: Colors.red),
                                onPressed: () => setModalState(
                                    () => selectedFiles.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 28),
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
                        onPressed: () async {
                          if (_selectedElderlyId == null) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          String formattedDate =
                              DateFormat('yyyy-MM-dd').format(selectedDate);
                          String formattedTime =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                          final res = await ApiService.createMedicalVisit(
                            elderlyId: _selectedElderlyId!,
                            date: formattedDate,
                            time: formattedTime,
                            hospital: _hospitalController.text,
                            doctorName: _doctorController.text,
                            diagnosis: _diagnosisController.text,
                            result: _resultController.text,
                            files: selectedFiles,
                          );

                          Navigator.pop(context); // loading
                          Navigator.pop(context); // sheet

                          if (res['success'] == true) {
                            _fetchAllData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF0EA5E9),
                                content: Text(
                                    'Đã lưu kết quả điều trị thành công!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content:
                                    Text(res['error'] ?? 'Thêm thất bại'),
                              ),
                            );
                          }
                        },
                        child: const Text('Lưu thông tin',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1}) {
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
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showAppointmentDetailsSheet(
    String date,
    String hospital,
    String doctor,
    String diagnosis,
    String result,
    List<dynamic> documents,
    int? appointmentId,
    bool isConfirmed,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding:
              const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Chi tiết hồ sơ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF0F172A))),
                  ),
                  if (appointmentId != null && isConfirmed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _showEditAppointmentDialog(appointmentId, diagnosis, result),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F9FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF0EA5E9)),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xóa hồ sơ'),
                                content: const Text('Bạn có chắc chắn muốn xóa hồ sơ khám bệnh này không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx); // Close dialog
                                      bool success = await ApiService.deleteAppointment(appointmentId);
                                      if (success) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Xóa thành công!')),
                                          );
                                          _fetchAllData();
                                          Navigator.pop(context); // Close bottom sheet
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Có lỗi xảy ra khi xóa.')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_rounded, size: 20, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Ngày khám', date,
                          icon: Icons.calendar_today_rounded),
                      _buildDetailRow('Bệnh viện / Cơ sở', hospital,
                          icon: Icons.local_hospital_rounded),
                      _buildDetailRow('Bác sĩ điều trị', doctor,
                          icon: Icons.person_rounded),
                      if (diagnosis.isNotEmpty)
                        _buildDetailRow('Chẩn đoán bệnh', diagnosis,
                            icon: Icons.healing_rounded),
                      if (result.isNotEmpty)
                        _buildDetailRow('Kết quả / Ghi chú', result,
                            icon: Icons.description_rounded),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tài liệu đính kèm',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          if (appointmentId != null && isConfirmed)
                            TextButton.icon(
                              onPressed: () =>
                                  _addDocumentToAppointment(appointmentId),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F9FF),
                                foregroundColor: const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 18),
                              label: const Text('Thêm tài liệu',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (documents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text('Chưa có tài liệu đính kèm.',
                                style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic)),
                          ),
                        )
                      else
                        ...documents.map((doc) {
                          final String fileName =
                              doc['file_url']?.split('/').last ??
                                  'Tài liệu không tên';
                          final String type =
                              doc['document_type'] ?? 'Khác';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    type == 'Toa thuốc'
                                        ? Icons.receipt_long_rounded
                                        : Icons.science_rounded,
                                    color: const Color(0xFF0EA5E9),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fileName,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(type,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final String? fileUrl = doc['file_url'];
                                    if (fileUrl != null && fileUrl.isNotEmpty) {
                                      final fullUrl = fileUrl.startsWith('http') 
                                          ? fileUrl 
                                          : '${ApiService.baseUrl}$fileUrl';
                                      final url = Uri.parse(fullUrl);
                                      try {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } catch (_) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Không thể tải tệp.')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.file_download_outlined,
                                        color: Color(0xFF64748B),
                                        size: 20),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditAppointmentDialog(int appointmentId, String currentDiagnosis, String currentResult) {
    final diagnosisCtrl = TextEditingController(text: currentDiagnosis);
    final resultCtrl = TextEditingController(text: currentResult);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cập nhật hồ sơ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 20),
              _buildInputField('Chẩn đoán bệnh', diagnosisCtrl),
              const SizedBox(height: 16),
              _buildInputField('Kết quả / Ghi chú thêm', resultCtrl, maxLines: 3),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      showDialog(
                        context: ctx,
                        barrierDismissible: false,
                        builder: (c) => const Center(child: CircularProgressIndicator()),
                      );
                      final res = await ApiService.updateAppointment(appointmentId, {
                        'diagnosis': diagnosisCtrl.text,
                        'note': resultCtrl.text,
                      });
                      if (mounted) {
                        Navigator.pop(ctx); // close loading
                      }
                      if (res) {
                        if (mounted) {
                          Navigator.pop(ctx); // close edit dialog
                          Navigator.pop(context); // close sheet
                          _fetchAllData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Color(0xFF0EA5E9), content: Text('Cập nhật thành công'))
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.red, content: Text('Cập nhật thất bại'))
                          );
                        }
                      }
                    },
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDocumentToAppointment(int appointmentId) async {
    final List<String> docTypes = [
      'Kết quả khám bệnh',
      'Toa thuốc',
      'Xét nghiệm máu',
      'Siêu âm',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        String selectedType = docTypes.first;
        List<Map<String, String>> pickedFiles = []; // [{path, name, type}]
        bool isUploading = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Row(
                    children: [
                      Icon(Icons.upload_file_rounded,
                          color: Color(0xFF0EA5E9), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Thêm tài liệu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Document type selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF334155),
                        ),
                        items: docTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Icon(
                                        t == 'Kết quả khám bệnh'
                                            ? Icons.description_rounded
                                            : t == 'Toa thuốc'
                                                ? Icons.medication_rounded
                                                : t == 'Xét nghiệm máu'
                                                    ? Icons.science_rounded
                                                    : t == 'Siêu âm'
                                                        ? Icons
                                                            .monitor_heart_rounded
                                                        : Icons
                                                            .folder_rounded,
                                        size: 18,
                                        color: const Color(0xFF0EA5E9),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pick files button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Color(0xFF0EA5E9), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.attach_file_rounded,
                          color: Color(0xFF0EA5E9)),
                      label: Text(
                        pickedFiles.isEmpty
                            ? 'Chọn file (PDF, JPG, PNG)'
                            : 'Thêm file khác',
                        style: const TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'jpg',
                            'jpeg',
                            'png'
                          ],
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setSheetState(() {
                            for (var f in result.files) {
                              if (f.path != null) {
                                pickedFiles.add({
                                  'path': f.path!,
                                  'name': f.name,
                                  'type': selectedType,
                                });
                              }
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // File list
                  if (pickedFiles.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pickedFiles.length,
                        itemBuilder: (_, idx) {
                          final file = pickedFiles[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  file['name']!
                                          .toLowerCase()
                                          .endsWith('.pdf')
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  color: file['name']!
                                          .toLowerCase()
                                          .endsWith('.pdf')
                                      ? Colors.red.shade400
                                      : const Color(0xFF0EA5E9),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: file['type'],
                                          isDense: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0EA5E9),
                                          ),
                                          items: docTypes
                                              .map((t) =>
                                                  DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setSheetState(() =>
                                                  pickedFiles[idx]
                                                      ['type'] = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 18,
                                      color: Colors.red.shade400),
                                  onPressed: () => setSheetState(
                                      () => pickedFiles.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pickedFiles.isEmpty || isUploading
                            ? Colors.grey.shade300
                            : const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        isUploading
                            ? 'Đang tải lên...'
                            : 'Tải lên ${pickedFiles.length} file',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: pickedFiles.isEmpty || isUploading
                          ? null
                          : () async {
                              setSheetState(() => isUploading = true);
                              int successCount = 0;
                              for (var file in pickedFiles) {
                                try {
                                  final uploadUrl = Uri.parse(
                                      "${ApiService.baseUrl}/api/medication/elderly-document/upload/");
                                  var request = http.MultipartRequest(
                                      'POST', uploadUrl);
                                  request.fields['elderly_id'] =
                                      _selectedElderlyId.toString();
                                  request.fields['appointment_id'] =
                                      appointmentId.toString();
                                  request.fields['document_type'] =
                                      file['type'] ??
                                          'Kết quả khám bệnh';
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'file', file['path']!));
                                  final res = await request.send();
                                  if (res.statusCode == 200 ||
                                      res.statusCode == 201) {
                                    successCount++;
                                  }
                                } catch (_) {}
                              }
                              setSheetState(() => isUploading = false);
                              if (mounted) {
                                Navigator.pop(ctx); // close this sheet
                                Navigator.pop(
                                    context); // close detail sheet
                                _fetchAllData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    content: Text(
                                        'Đã tải lên $successCount/${pickedFiles.length} tài liệu!'),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ======================================================================
// HealthThresholdsScreen – giữ nguyên
// ======================================================================
class HealthThresholdsScreen extends StatefulWidget {
  const HealthThresholdsScreen({super.key});

  @override
  State<HealthThresholdsScreen> createState() =>
      _HealthThresholdsScreenState();
}

class _HealthThresholdsScreenState
    extends State<HealthThresholdsScreen> {
  final List<_HealthMetric> _metrics = [
    _HealthMetric(
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFDC2626),
      iconBg: const Color(0xFFFFEBEB),
      title: 'Huyết áp tâm thu',
      unit: 'mmHg',
      min: 90,
      max: 140,
      current: 128,
      absMin: 70,
      absMax: 200,
    ),
    _HealthMetric(
      icon: Icons.favorite_border_rounded,
      iconColor: const Color(0xFFEA580C),
      iconBg: const Color(0xFFFFF4E6),
      title: 'Huyết áp tâm trương',
      unit: 'mmHg',
      min: 60,
      max: 90,
      current: 82,
      absMin: 40,
      absMax: 130,
    ),
    _HealthMetric(
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF0EA5E9),
      iconBg: const Color(0xFFEBF3FF),
      title: 'Đường huyết',
      unit: 'mmol/L',
      min: 3.9,
      max: 7.8,
      current: 5.8,
      absMin: 2.0,
      absMax: 15.0,
    ),
    _HealthMetric(
      icon: Icons.monitor_heart_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBg: const Color(0xFFF3EEFF),
      title: 'Nhịp tim',
      unit: 'bpm',
      min: 60,
      max: 100,
      current: 72,
      absMin: 40,
      absMax: 200,
    ),
    _HealthMetric(
      icon: Icons.scale_rounded,
      iconColor: const Color(0xFF16A34A),
      iconBg: const Color(0xFFE6FBF3),
      title: 'Cân nặng',
      unit: 'kg',
      min: 50,
      max: 80,
      current: 62,
      absMin: 30,
      absMax: 150,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Đã lưu ngưỡng cảnh báo ✓',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF78350F), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngưỡng cảnh báo sức khỏe',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Tuỳ chỉnh giới hạn an toàn',
                          style: TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.warning_rounded,
                    color: Colors.white70, size: 24),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ..._metrics.map((m) => _buildMetricCard(m)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Lưu ngưỡng',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(_HealthMetric m) {
    String status;
    Color statusColor;
    if (m.current < m.min || m.current > m.max) {
      status = 'Cảnh báo';
      statusColor = const Color(0xFFC81E1E);
    } else if (m.current <= m.min + (m.max - m.min) * 0.1 ||
        m.current >= m.max - (m.max - m.min) * 0.1) {
      status = 'Cần chú ý';
      statusColor = const Color(0xFFD97706);
    } else {
      status = 'Bình thường';
      statusColor = const Color(0xFF16A34A);
    }

    final range = m.absMax - m.absMin;
    final safeStart = (m.min - m.absMin) / range;
    final safeEnd = (m.max - m.absMin) / range;
    final cursorPos = ((m.current - m.absMin) / range).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: m.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    Text(m.unit,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    m.current % 1 == 0
                        ? '${m.current.toInt()} ${m.unit}'
                        : '${m.current.toStringAsFixed(1)} ${m.unit}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngưỡng tối thiểu',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    _thresholdInput(m.min, m.unit, true, m),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngưỡng tối đa',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    _thresholdInput(m.max, m.unit, false, m),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LayoutBuilder(builder: (_, constraints) {
                final totalW = constraints.maxWidth;
                return Stack(
                  children: [
                    Container(color: const Color(0xFFFFCDD2)),
                    Positioned(
                      left: totalW * safeStart,
                      width: totalW * (safeEnd - safeStart),
                      top: 0,
                      bottom: 0,
                      child: Container(color: const Color(0xFF86EFAC)),
                    ),
                    Positioned(
                      left: (totalW * cursorPos - 3).clamp(0.0, totalW - 6),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${m.absMin.toInt()} ${m.unit}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8))),
              Row(
                children: [
                  Container(
                      width: 8, height: 8, color: const Color(0xFF86EFAC)),
                  const SizedBox(width: 4),
                  const Text('An toàn',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 8),
                  Container(
                      width: 8, height: 8, color: const Color(0xFFFFCDD2)),
                  const SizedBox(width: 4),
                  const Text('Nguy hiểm',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
              Text('${m.absMax.toInt()} ${m.unit}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thresholdInput(
      double value, String unit, bool isMin, _HealthMetric m) {
    return GestureDetector(
      onTap: () {
        final ctrl = TextEditingController(
            text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1));
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isMin ? 'Ngưỡng tối thiểu' : 'Ngưỡng tối đa'),
            content: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                suffixText: unit,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text);
                  if (v != null) {
                    setState(() => isMin ? m.min = v : m.max = v);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9)),
                child: const Text('Lưu',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value % 1 == 0
                    ? '${value.toInt()}'
                    : value.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
            Text(unit,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8))),
            const SizedBox(width: 4),
            const Icon(Icons.edit_rounded,
                color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }
}

class _HealthMetric {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, unit;
  double min, max, current;
  final double absMin, absMax;

  _HealthMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.current,
    required this.absMin,
    required this.absMax,
  });
}

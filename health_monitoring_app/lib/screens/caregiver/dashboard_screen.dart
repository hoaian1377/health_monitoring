import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

import '../../utils/api_service.dart';
import '../../utils/elderly_provider.dart';
import 'widgets/elderly_switcher_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Chỉ số sức khỏe ──────────────────────────────────────────────────────────
  String _bpSys = '--';
  String _bpDia = '--';
  String _heartRate = '--';
  String _bloodSugar = '--';
  String _temperature = '--';

  // ── Elderly Provider (centralized) ──
  final ElderlyProvider _elderlyProvider = ElderlyProvider.instance;

  // Proxy getters so existing code continues to work with minimal changes
  int? get _selectedElderlyId => _elderlyProvider.selectedElderlyId;
  String get _selectedElderlyName => _elderlyProvider.selectedElderlyName;

  List<dynamic> _historicalMetrics = [];
  List<dynamic> _medicationSchedules = [];



  // Bộ lọc thời gian (F09)
  String _selectedPeriod = 'Tuần';
  final List<String> _periods = ['Ngày', 'Tuần', 'Tháng', 'Quý', 'Năm'];

  @override
  void initState() {
    super.initState();
    _elderlyProvider.addListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.addListener(_onDataChanged);
    // Load metrics if elderly already selected
    if (_selectedElderlyId != null) {
      _loadLatestMetrics();
    }
  }

  void _onElderlyChanged() {
    if (mounted && _selectedElderlyId != null) {
      _loadLatestMetrics();
    }
  }

  void _onDataChanged() {
    if (mounted && _selectedElderlyId != null) {
      _loadLatestMetrics();
    }
  }

  @override
  void dispose() {
    _elderlyProvider.removeListener(_onElderlyChanged);
    ApiService.dataRefreshTrigger.removeListener(_onDataChanged);
    super.dispose();
  }

  Map<String, dynamic>? _nextAppointment;

  Future<void> _handleRefresh() async {
    await _elderlyProvider.loadElderlyList();
    if (_selectedElderlyId != null) {
      await _loadLatestMetrics();
    }
  }

  Future<void> _loadLatestMetrics() async {
    final eldId = _selectedElderlyId;
    if (eldId == null) return;

    final data = await ApiService.getHealthMetrics(eldId);
    final appts = await ApiService.getAppointments(eldId);
    final meds = await ApiService.getElderlyMedicationSchedule(eldId);

    if (mounted) {
      setState(() {
        _historicalMetrics = data;
        _medicationSchedules = meds;
        
        // Reset metrics first
        _heartRate = '--';
        _bpSys = '--';
        _bpDia = '--';
        _bloodSugar = '--';
        _temperature = '--';
        _nextAppointment = null;

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

        if (appts.isNotEmpty) {
          final now = DateTime.now();
          List<dynamic> futureAppts = appts.where((a) {
            if (a['appointment_date'] == null) return false;
            try {
              final date = DateTime.parse(a['appointment_date']);
              return date.isAfter(now) ||
                  date.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
            } catch (e) {
              return false;
            }
          }).toList();

          if (futureAppts.isNotEmpty) {
            futureAppts.sort(
              (a, b) => DateTime.parse(
                a['appointment_date'],
              ).compareTo(DateTime.parse(b['appointment_date'])),
            );
            _nextAppointment = futureAppts.first;
          }
        }
      });
    }
  }



  // ── Bottom sheet nhập / sửa chỉ số ─────────────────────────────────────────
  void _showMetricsSheet() {
    final bpSysCtrl = TextEditingController(text: _bpSys);
    final bpDiaCtrl = TextEditingController(text: _bpDia);
    final heartCtrl = TextEditingController(text: _heartRate);
    final sugarCtrl = TextEditingController(text: _bloodSugar);
    final tempCtrl = TextEditingController(text: _temperature);

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
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom +
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
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nhập / Cập nhật Chỉ Số',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Thời gian ghi nhận: Hôm nay, ngay bây giờ',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              _sheetSection(
                'Huyết Áp',
                Icons.monitor_heart_rounded,
                const Color(0xFFDC2626),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      'Tâm thu',
                      bpSysCtrl,
                      'mmHg',
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      'Tâm trương',
                      bpDiaCtrl,
                      'mmHg',
                      Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sheetSection(
                'Nhịp Tim',
                Icons.favorite_rounded,
                const Color(0xFFE11D48),
              ),
              const SizedBox(height: 10),
              _inputField(
                'Nhịp tim',
                heartCtrl,
                'lần/phút',
                Icons.favorite_border_rounded,
              ),
              const SizedBox(height: 16),
              _sheetSection(
                'Đường Huyết',
                Icons.water_drop_rounded,
                const Color(0xFF0284C7),
              ),
              const SizedBox(height: 10),
              _inputField(
                'Đường huyết',
                sugarCtrl,
                'mmol/L',
                Icons.water_drop_outlined,
              ),
              const SizedBox(height: 16),
              _sheetSection(
                'Nhiệt Độ',
                Icons.thermostat_rounded,
                const Color(0xFFEA580C),
              ),
              const SizedBox(height: 10),
              _inputField(
                'Nhiệt độ',
                tempCtrl,
                '°C',
                Icons.thermostat_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    setState(() {
                      _bpSys = bpSysCtrl.text.isEmpty ? _bpSys : bpSysCtrl.text;
                      _bpDia = bpDiaCtrl.text.isEmpty ? _bpDia : bpDiaCtrl.text;
                      _heartRate = heartCtrl.text.isEmpty
                          ? _heartRate
                          : heartCtrl.text;
                      _bloodSugar = sugarCtrl.text.isEmpty
                          ? _bloodSugar
                          : sugarCtrl.text;
                      _temperature = tempCtrl.text.isEmpty
                          ? _temperature
                          : tempCtrl.text;
                    });

                    if (_selectedElderlyId != null) {
                      await ApiService.addHealthMetric(
                        elderlyId: _selectedElderlyId!,
                        heartRate: int.tryParse(_heartRate),
                        bloodPressure: '$_bpSys/$_bpDia',
                        bloodSugar: double.tryParse(_bloodSugar),
                        temperature: double.tryParse(_temperature),
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('✓ Đã cập nhật chỉ số thành công!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Lưu Chỉ Số',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetSection(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl,
    String unit,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
            filled: true,
            fillColor: const Color(0xFFF0F9FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0EA5E9),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0EA5E9),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElderlySwitcherBar(provider: _elderlyProvider),
                  const SizedBox(height: 16),
                  // Lịch khám sắp tới
                  _buildNextAppointmentCard(),
                  const SizedBox(height: 24),

                  // Section chỉ số
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('CHỈ SỐ SỨC KHỎE HÔM NAY'),
                      GestureDetector(
                        onTap: _showMetricsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Color(0xFF0EA5E9),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Nhập / Sửa',
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hàng 1: Huyết áp + Nhịp tim
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Huyết áp',
                          icon: Icons.monitor_heart_rounded,
                          value: _bpSys,
                          unit: '/$_bpDia mmHg',
                          statusText: () {
                            final v = int.tryParse(_bpSys) ?? 0;
                            return (v > 0 && (v > 140 || v < 90))
                                ? 'Bất thường'
                                : 'Bình thường';
                          }(),
                          statusColor: () {
                            final v = int.tryParse(_bpSys) ?? 0;
                            return (v > 0 && (v > 140 || v < 90))
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A);
                          }(),
                          statusBg: () {
                            final v = int.tryParse(_bpSys) ?? 0;
                            return (v > 0 && (v > 140 || v < 90))
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7);
                          }(),
                          statusIcon: () {
                            final v = int.tryParse(_bpSys) ?? 0;
                            return (v > 0 && (v > 140 || v < 90))
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded;
                          }(),
                          accentColor: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Nhịp tim',
                          icon: Icons.favorite_rounded,
                          value: _heartRate,
                          unit: ' lần/phút',
                          statusText: () {
                            final v = int.tryParse(_heartRate) ?? 0;
                            return (v > 0 && (v > 100 || v < 60))
                                ? 'Bất thường'
                                : 'Bình thường';
                          }(),
                          statusColor: () {
                            final v = int.tryParse(_heartRate) ?? 0;
                            return (v > 0 && (v > 100 || v < 60))
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A);
                          }(),
                          statusBg: () {
                            final v = int.tryParse(_heartRate) ?? 0;
                            return (v > 0 && (v > 100 || v < 60))
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7);
                          }(),
                          statusIcon: () {
                            final v = int.tryParse(_heartRate) ?? 0;
                            return (v > 0 && (v > 100 || v < 60))
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded;
                          }(),
                          accentColor: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hàng 2: Đường huyết + Nhiệt độ
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Đường huyết',
                          icon: Icons.water_drop_rounded,
                          value: _bloodSugar,
                          unit: ' mmol/L',
                          statusText: () {
                            final v = double.tryParse(_bloodSugar) ?? 0;
                            return (v > 0 && (v > 7.8 || v < 3.9))
                                ? 'Bất thường'
                                : 'Bình thường';
                          }(),
                          statusColor: () {
                            final v = double.tryParse(_bloodSugar) ?? 0;
                            return (v > 0 && (v > 7.8 || v < 3.9))
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A);
                          }(),
                          statusBg: () {
                            final v = double.tryParse(_bloodSugar) ?? 0;
                            return (v > 0 && (v > 7.8 || v < 3.9))
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7);
                          }(),
                          statusIcon: () {
                            final v = double.tryParse(_bloodSugar) ?? 0;
                            return (v > 0 && (v > 7.8 || v < 3.9))
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded;
                          }(),
                          accentColor: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Nhiệt độ',
                          icon: Icons.thermostat_rounded,
                          value: _temperature,
                          unit: ' °C',
                          statusText: () {
                            final v = double.tryParse(_temperature) ?? 36.5;
                            if (v >= 38.0) return 'Sốt';
                            if (v < 36.0) return 'Hạ thân nhiệt';
                            return 'Bình thường';
                          }(),
                          statusColor: () {
                            final v = double.tryParse(_temperature) ?? 36.5;
                            if (v >= 38.0) return const Color(0xFFDC2626);
                            if (v < 36.0) return const Color(0xFF0284C7);
                            return const Color(0xFF16A34A);
                          }(),
                          statusBg: () {
                            final v = double.tryParse(_temperature) ?? 36.5;
                            if (v >= 38.0) return const Color(0xFFFFEBEB);
                            if (v < 36.0) return const Color(0xFFE0F2FE);
                            return const Color(0xFFDCFCE7);
                          }(),
                          statusIcon: () {
                            final v = double.tryParse(_temperature) ?? 36.5;
                            return (v >= 38.0 || v < 36.0)
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded;
                          }(),
                          accentColor: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),



                  const SizedBox(height: 24),

                  // Bộ lọc thời gian
                  _buildSectionLabel('BỘ LỌC THỜI GIAN THEO DÕI'),
                  const SizedBox(height: 10),
                  _buildPeriodFilterRow(),
                  const SizedBox(height: 24),

                  // Biểu đồ sử dụng thuốc
                  _buildSectionLabel('BIỂU ĐỒ SỬ DỤNG THUỐC (${_selectedPeriod.toUpperCase()})'),
                  const SizedBox(height: 12),
                  _buildMedicationChart(),

                  const SizedBox(height: 24),

                  // Tuân thủ uống thuốc
                  _buildSectionLabel('UỐNG THUỐC 7 NGÀY QUA'),
                  const SizedBox(height: 12),
                  _buildAdherenceChart(),

                  const SizedBox(height: 24),

                  // Cảnh báo gần đây
                  _buildSectionLabel('CẢNH BÁO GẦN ĐÂY'),
                  const SizedBox(height: 12),
                  _buildRecentAlerts(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── Sliver Header ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130.0,
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFF0284C7),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo Dõi Sức Khỏe',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Ngày ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
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
                  color: Colors.white.withOpacity(0.08),
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
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  // ── Lịch khám sắp tới ─────────────────────────────────────────────────────
  Widget _buildNextAppointmentCard() {
    if (_nextAppointment == null) return const SizedBox.shrink();

    final loc = _nextAppointment!['location'] ?? 'Không rõ';
    final doc = _nextAppointment!['doctor_name'] ?? '';
    final dateStr = _nextAppointment!['appointment_date'] ?? '';

    int daysDiff = 0;
    try {
      if (dateStr.isNotEmpty) {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        daysDiff = date
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF0EA5E9),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch khám sắp tới',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.isNotEmpty ? 'BS. $doc' : 'Chưa rõ BS',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Còn',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$daysDiff',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'ngày',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Metric Card ─────────────────────────────────────────────────────────────
  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required String value,
    required String unit,
    required String statusText,
    required Color statusColor,
    required Color statusBg,
    required IconData statusIcon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: accentColor.withOpacity(0.9),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 3),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
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



  // ── Biểu đồ sử dụng thuốc ─────────────────────────────────────────────────────
  Widget _buildMedicationChart() {
    int points = _selectedPeriod == 'Tháng' ? 30 : 7;
    final now = DateTime.now();

    // Group records by date string
    final Map<String, List<bool>> recordsByDate = {};
    for (var schedule in _medicationSchedules) {
      final med = schedule['medication'] ?? {};
      final description = med['description']?.toString() ?? '';
      if (description.contains('· dose_history:')) {
        final parts = description.split('· dose_history:');
        try {
          final list = jsonDecode(parts[1].trim()) as List;
          for (final item in list) {
            final dateStr = item['date'].toString();
            final taken = item['taken'] == true;
            if (!recordsByDate.containsKey(dateStr)) {
              recordsByDate[dateStr] = [];
            }
            recordsByDate[dateStr]!.add(taken);
          }
        } catch (_) {}
      }
    }

    // Build chart data
    List<BarChartGroupData> barGroups = [];
    List<String> bottomLabels = [];

    for (int i = points - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      if (_selectedPeriod == 'Tháng') {
        bottomLabels.add('${date.day}/${date.month}');
      } else {
        final weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        bottomLabels.add(weekDays[date.weekday % 7]);
      }

      int taken = 0;
      int missed = 0;
      if (recordsByDate.containsKey(dateStr)) {
        for (bool t in recordsByDate[dateStr]!) {
          if (t) taken++; else missed++;
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: points - 1 - i,
          barRods: [
            BarChartRodData(
              toY: taken.toDouble() + missed.toDouble(),
              rodStackItems: [
                BarChartRodStackItem(0, taken.toDouble(), const Color(0xFF16A34A)),
                BarChartRodStackItem(taken.toDouble(), taken.toDouble() + missed.toDouble(), const Color(0xFFDC2626)),
              ],
              width: _selectedPeriod == 'Tháng' ? 6 : 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 5,
                color: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < bottomLabels.length) {
                          if (_selectedPeriod == 'Tháng' && value.toInt() % 5 != 0) {
                             return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              bottomLabels[value.toInt()],
                              style: TextStyle(
                                color: const Color(0xFF64748B),
                                fontSize: _selectedPeriod == 'Tháng' ? 9 : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF16A34A), 'Đã uống'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFDC2626), 'Bỏ lỡ'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Adherence Chart ─────────────────────────────────────────────────────────
  Widget _buildAdherenceChart() {
    int totalTaken = 0;
    int totalMissed = 0;
    
    // Group records by date (yyyy-MM-dd)
    final Map<String, List<bool>> recordsByDate = {};
    
    for (var schedule in _medicationSchedules) {
      final med = schedule['medication'] ?? {};
      final description = med['description']?.toString() ?? '';
      if (description.contains('· dose_history:')) {
        final parts = description.split('· dose_history:');
        try {
          final list = jsonDecode(parts[1].trim()) as List;
          for (final item in list) {
            final dateStr = item['date'].toString();
            final taken = item['taken'] == true;
            if (taken) {
              totalTaken++;
            } else {
              totalMissed++;
            }
            if (!recordsByDate.containsKey(dateStr)) {
              recordsByDate[dateStr] = [];
            }
            recordsByDate[dateStr]!.add(taken);
          }
        } catch (e) {
          // ignore parsing error
        }
      }
    }
    
    int total = totalTaken + totalMissed;
    double adherenceRatio = total > 0 ? (totalTaken / total) : 1.0; // default 1.0 if no data
    String percentage = total > 0 ? '${(adherenceRatio * 100).round()}%' : '100%';
    String adherenceStatus = adherenceRatio >= 0.8 ? 'Rất tốt' : (adherenceRatio >= 0.5 ? 'Khá' : 'Kém');
    Color adherenceColor = adherenceRatio >= 0.8 ? const Color(0xFF16A34A) : (adherenceRatio >= 0.5 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    // Calculate last 7 days status
    final now = DateTime.now();
    List<int> status = [];
    List<String> days = [];
    final weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      days.add(weekDays[date.weekday % 7]);
      
      if (recordsByDate.containsKey(dateStr)) {
        final dayRecords = recordsByDate[dateStr]!;
        bool allTaken = dayRecords.every((t) => t == true);
        status.add(allTaken ? 1 : 0);
      } else {
        status.add(2); // no records yet
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tỉ lệ tuân thủ uống thuốc',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Text(
                    adherenceStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: adherenceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: adherenceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: adherenceRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0F2FE),
              valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: status[index] == 1
                          ? const Color(0xFFDCFCE7)
                          : status[index] == 0
                          ? const Color(0xFFFFEBEB)
                          : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status[index] == 1
                          ? Icons.check_rounded
                          : status[index] == 0
                          ? Icons.close_rounded
                          : Icons.access_time_rounded,
                      size: 16,
                      color: status[index] == 1
                          ? const Color(0xFF16A34A)
                          : status[index] == 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: status[index] == 2
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF94A3B8),
                      fontWeight: status[index] == 2
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF16A34A), 'Đã uống'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFDC2626), 'Bỏ lỡ'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFD97706), 'Chờ xác nhận'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ── Recent Alerts ──────────────────────────────────────────────────────────
  Widget _buildRecentAlerts() {
    List<Widget> alerts = [];

    // Check last metrics
    if (_historicalMetrics.isNotEmpty) {
      final latest = _historicalMetrics.last;
      
      // Blood pressure
      if (latest['blood_pressure'] != null) {
        final bpStr = latest['blood_pressure'].toString();
        final bpParts = bpStr.split('/');
        if (bpParts.isNotEmpty) {
          final sys = double.tryParse(bpParts[0]) ?? 0;
          if (sys >= 140) {
            alerts.add(_buildAlertItem(
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFDC2626),
              bg: const Color(0xFFFFEBEB),
              title: 'Huyết áp hơi cao',
              time: 'Gần đây',
              desc: 'Huyết áp $bpStr mmHg. Hãy theo dõi thêm và nghỉ ngơi.',
              sentToFamily: true,
            ));
            alerts.add(const SizedBox(height: 12));
          }
        }
      }

      // Temperature
      if (latest['temperature'] != null) {
        final temp = double.tryParse(latest['temperature'].toString()) ?? 0;
        if (temp > 37.5) {
          alerts.add(_buildAlertItem(
            icon: Icons.thermostat_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
            title: 'Nhiệt độ cơ thể tăng nhẹ',
            time: 'Gần đây',
            desc: 'Nhiệt độ $temp°C. Có thể là dấu hiệu sốt nhẹ.',
            sentToFamily: true,
          ));
          alerts.add(const SizedBox(height: 12));
        }
      }
      
      // Blood sugar
      if (latest['blood_sugar'] != null) {
        final sugar = double.tryParse(latest['blood_sugar'].toString()) ?? 0;
        if (sugar > 7.8) {
          alerts.add(_buildAlertItem(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
            title: 'Đường huyết cao',
            time: 'Gần đây',
            desc: 'Đường huyết $sugar mmol/L. Hãy chú ý chế độ ăn uống.',
            sentToFamily: true,
          ));
          alerts.add(const SizedBox(height: 12));
        }
      }
    }

    // Default message if no alerts
    if (alerts.isEmpty) {
      alerts.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Không có cảnh báo bất thường nào gần đây.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Column(children: alerts);
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String time,
    required String desc,
    bool sentToFamily = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (sentToFamily) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 11,
                        color: Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Đã thông báo người thân',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bộ lọc thời gian (F09) ─────────────────────────────────────────────────
  Widget _buildPeriodFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFBAE6FD),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Xuất báo cáo (F09) ──────────────────────────────────────────────────────
  Widget _buildExportButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              32 + MediaQuery.of(ctx).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.download_rounded, color: Color(0xFF0EA5E9)),
                    SizedBox(width: 10),
                    Text(
                      'Xuất báo cáo sức khỏe',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Khoảng thời gian: $_selectedPeriod này',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                _exportOption(
                  Icons.picture_as_pdf_rounded,
                  'Xuất file PDF',
                  'Báo cáo đầy đủ dạng PDF',
                  const Color(0xFFDC2626),
                ),
                const SizedBox(height: 10),
                _exportOption(
                  Icons.table_chart_rounded,
                  'Xuất file Excel',
                  'Dữ liệu chỉ số dạng bảng',
                  const Color(0xFF16A34A),
                ),
                const SizedBox(height: 10),
                _exportOption(
                  Icons.share_rounded,
                  'Chia sẻ với bác sĩ',
                  'Gửi link báo cáo qua Zalo/Email',
                  const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Xuất báo cáo $_selectedPeriod này',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: color,
            content: Text('✓ Đang xuất báo cáo... ($title)'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

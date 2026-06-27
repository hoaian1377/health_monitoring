import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/global_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Chỉ số sức khỏe ──────────────────────────────────────────────────────────
  String _bpSys = '120';
  String _bpDia = '80';
  String _heartRate = '72';
  String _bloodSugar = '5.5';
  String _weight = '62.0';
  String _temperature = '36.5';

  // Chart tab
  late TabController _chartTabController;

  // Bộ lọc thời gian (F09)
  String _selectedPeriod = 'Tuần';
  final List<String> _periods = ['Ngày', 'Tuần', 'Tháng', 'Quý', 'Năm'];

  // Cảnh báo bỏ lỡ thuốc
  bool _showMissedAlert = true;

  @override
  void initState() {
    super.initState();
    _chartTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _chartTabController.dispose();
    super.dispose();
  }

  // ── Bottom sheet nhập / sửa chỉ số ─────────────────────────────────────────
  void _showMetricsSheet() {
    final bpSysCtrl = TextEditingController(text: _bpSys);
    final bpDiaCtrl = TextEditingController(text: _bpDia);
    final heartCtrl = TextEditingController(text: _heartRate);
    final sugarCtrl = TextEditingController(text: _bloodSugar);
    final weightCtrl = TextEditingController(text: _weight);
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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24 + MediaQuery.of(ctx).padding.bottom,
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
                    child: const Icon(Icons.edit_rounded,
                        color: Color(0xFF0EA5E9), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nhập / Cập nhật Chỉ Số',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Thời gian ghi nhận: Hôm nay, ngay bây giờ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),
              _sheetSection('Huyết Áp', Icons.monitor_heart_rounded,
                  const Color(0xFFDC2626)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                        'Tâm thu', bpSysCtrl, 'mmHg', Icons.arrow_upward_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField('Tâm trương', bpDiaCtrl, 'mmHg',
                        Icons.arrow_downward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sheetSection(
                  'Nhịp Tim', Icons.favorite_rounded, const Color(0xFFE11D48)),
              const SizedBox(height: 10),
              _inputField(
                  'Nhịp tim', heartCtrl, 'lần/phút', Icons.favorite_border_rounded),
              const SizedBox(height: 16),
              _sheetSection('Đường Huyết', Icons.water_drop_rounded,
                  const Color(0xFF0284C7)),
              const SizedBox(height: 10),
              _inputField(
                  'Đường huyết', sugarCtrl, 'mmol/L', Icons.water_drop_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetSection('Cân Nặng', Icons.scale_rounded,
                            const Color(0xFF7C3AED)),
                        const SizedBox(height: 10),
                        _inputField(
                            'Cân nặng', weightCtrl, 'kg', Icons.scale_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetSection('Nhiệt Độ', Icons.thermostat_rounded,
                            const Color(0xFFEA580C)),
                        const SizedBox(height: 10),
                        _inputField('Nhiệt độ', tempCtrl, '°C',
                            Icons.thermostat_outlined),
                      ],
                    ),
                  ),
                ],
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
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _bpSys = bpSysCtrl.text.isEmpty ? _bpSys : bpSysCtrl.text;
                      _bpDia = bpDiaCtrl.text.isEmpty ? _bpDia : bpDiaCtrl.text;
                      _heartRate =
                          heartCtrl.text.isEmpty ? _heartRate : heartCtrl.text;
                      _bloodSugar =
                          sugarCtrl.text.isEmpty ? _bloodSugar : sugarCtrl.text;
                      _weight =
                          weightCtrl.text.isEmpty ? _weight : weightCtrl.text;
                      _temperature =
                          tempCtrl.text.isEmpty ? _temperature : tempCtrl.text;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('✓ Đã cập nhật chỉ số thành công!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Lưu Chỉ Số',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.3)),
      ],
    );
  }

  Widget _inputField(
      String label, TextEditingController ctrl, String unit, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle:
                const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
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

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cảnh báo bỏ lỡ thuốc
                  if (_showMissedAlert) ...[
                    _buildMissedMedicineAlert(),
                    const SizedBox(height: 16),
                  ],

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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 14, color: Color(0xFF0EA5E9)),
                              SizedBox(width: 4),
                              Text('Nhập / Sửa',
                                  style: TextStyle(
                                      color: Color(0xFF0EA5E9),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
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
                          statusText: int.tryParse(_bpSys) != null &&
                                  globalState.isOutOfRange('sysBp', double.parse(_bpSys))
                              ? 'Bất thường'
                              : 'Bình thường',
                          statusColor: int.tryParse(_bpSys) != null &&
                                  globalState.isOutOfRange('sysBp', double.parse(_bpSys))
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: int.tryParse(_bpSys) != null &&
                                  globalState.isOutOfRange('sysBp', double.parse(_bpSys))
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: int.tryParse(_bpSys) != null &&
                                  globalState.isOutOfRange('sysBp', double.parse(_bpSys))
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
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
                          statusText: int.tryParse(_heartRate) != null &&
                                  globalState.isOutOfRange('heartRate', double.parse(_heartRate))
                              ? 'Bất thường'
                              : 'Bình thường',
                          statusColor: int.tryParse(_heartRate) != null &&
                                  globalState.isOutOfRange('heartRate', double.parse(_heartRate))
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: int.tryParse(_heartRate) != null &&
                                  globalState.isOutOfRange('heartRate', double.parse(_heartRate))
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: int.tryParse(_heartRate) != null &&
                                  globalState.isOutOfRange('heartRate', double.parse(_heartRate))
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
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
                          statusText: double.tryParse(_bloodSugar) != null &&
                                  globalState.isOutOfRange('bloodSugar', double.parse(_bloodSugar))
                              ? 'Bất thường'
                              : 'Bình thường',
                          statusColor: double.tryParse(_bloodSugar) != null &&
                                  globalState.isOutOfRange('bloodSugar', double.parse(_bloodSugar))
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: double.tryParse(_bloodSugar) != null &&
                                  globalState.isOutOfRange('bloodSugar', double.parse(_bloodSugar))
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: double.tryParse(_bloodSugar) != null &&
                                  globalState.isOutOfRange('bloodSugar', double.parse(_bloodSugar))
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
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

                  // Hàng 3: Cân nặng (full width hoặc có thể thêm BMI)
                  _buildWeightCard(),

                  const SizedBox(height: 24),

                  // Bộ lọc thời gian
                  _buildSectionLabel('BỘ LỌC THỜI GIAN THEO DÕI'),
                  const SizedBox(height: 10),
                  _buildPeriodFilterRow(),
                  const SizedBox(height: 24),

                  // Biểu đồ đa chỉ số
                  _buildSectionLabel('BIỂU ĐỒ THEO DÕI (7 NGÀY)'),
                  const SizedBox(height: 12),
                  _buildMultiChart(),

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
              'Dashboard',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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

  // ── Cảnh báo bỏ lỡ thuốc ──────────────────────────────────────────────────
  Widget _buildMissedMedicineAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bỏ lỡ uống thuốc — Đã thông báo người thân',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C))),
                const SizedBox(height: 3),
                const Text(
                    'Vitamin D3 lúc 13:00 chưa xác nhận. Người thân đã được thông báo.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _showMissedAlert = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF16A34A),
                        content: Text('✓ Đã xác nhận uống thuốc!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Xác nhận đã uống',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showMissedAlert = false),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ── Lịch khám sắp tới ─────────────────────────────────────────────────────
  Widget _buildNextAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
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
            child: const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF0EA5E9), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lịch khám sắp tới',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Bệnh viện Chợ Rẫy',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                SizedBox(height: 2),
                Text('BS. Nguyễn Thị Lan · Tim mạch',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text('Còn',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold)),
                Text('3',
                    style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w900)),
                Text('ngày',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold)),
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
              offset: const Offset(0, 2)),
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
                      color: Color(0xFF475569)),
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
                color: accentColor.withOpacity(0.9)),
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
                      color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cân nặng + BMI card ────────────────────────────────────────────────────
  Widget _buildWeightCard() {
    final w = double.tryParse(_weight) ?? 62.0;
    // BMI giả định chiều cao 1.65m
    final bmi = w / (1.65 * 1.65);
    String bmiStatus;
    Color bmiColor;
    if (bmi < 18.5) {
      bmiStatus = 'Thiếu cân';
      bmiColor = const Color(0xFF0284C7);
    } else if (bmi < 25) {
      bmiStatus = 'Bình thường';
      bmiColor = const Color(0xFF16A34A);
    } else if (bmi < 30) {
      bmiStatus = 'Thừa cân';
      bmiColor = const Color(0xFFD97706);
    } else {
      bmiStatus = 'Béo phì';
      bmiColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.scale_rounded,
                color: Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cân nặng',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600)),
              Text('${_weight} kg',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BMI (est.)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Text(bmi.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: bmiColor)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(bmiStatus,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: bmiColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Biểu đồ đa chỉ số ─────────────────────────────────────────────────────
  Widget _buildMultiChart() {
    int points = _selectedPeriod == 'Tuần' ? 7 : (_selectedPeriod == 'Tháng' ? 30 : 12);
    if (_selectedPeriod == 'Ngày') points = 6;
    
    List<String> days = [];
    if (_selectedPeriod == 'Tuần') {
      days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    } else if (_selectedPeriod == 'Tháng') {
      days = List.generate(points, (i) => '${i+1}');
    } else if (_selectedPeriod == 'Ngày') {
      days = ['8h', '10h', '12h', '14h', '16h', '18h'];
    } else {
      days = List.generate(points, (i) => 'T${i+1}');
    }

    List<double> generateData(double base, double variance) {
      final rand = Random(42); // Fixed seed for stable UI
      return List.generate(points - 1, (i) => base + (rand.nextDouble() * 2 - 1) * variance)
          ..add(base); // last point is current
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Tab bar chọn chỉ số
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: TabBar(
              controller: _chartTabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF0EA5E9),
              indicatorWeight: 2.5,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Huyết áp'),
                Tab(text: 'Nhịp tim'),
                Tab(text: 'Đường huyết'),
                Tab(text: 'Cân nặng'),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _chartTabController,
              children: [
                _buildBarChart(
                  data: generateData(double.tryParse(_bpSys) ?? 120.0, 15.0),
                  days: days,
                  color: const Color(0xFFDC2626),
                  unit: 'mmHg',
                  threshold: globalState.thresholds.value.sysBpMax,
                ),
                _buildBarChart(
                  data: generateData(double.tryParse(_heartRate) ?? 72.0, 10.0),
                  days: days,
                  color: const Color(0xFFE11D48),
                  unit: 'l/p',
                  threshold: globalState.thresholds.value.heartRateMax,
                ),
                _buildBarChart(
                  data: generateData(double.tryParse(_bloodSugar) ?? 5.5, 1.5),
                  days: days,
                  color: const Color(0xFF0284C7),
                  unit: 'mmol',
                  threshold: globalState.thresholds.value.bloodSugarMax,
                  isDecimal: true,
                ),
                _buildBarChart(
                  data: generateData(double.tryParse(_weight) ?? 62.0, 1.0),
                  days: days,
                  color: const Color(0xFF7C3AED),
                  unit: 'kg',
                  threshold: globalState.thresholds.value.weightMax,
                  isDecimal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required List<double> data,
    required List<String> days,
    required Color color,
    required String unit,
    required double threshold,
    bool isDecimal = false,
  }) {
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final isToday = i == data.length - 1;
                final isHigh = data[i] > threshold;
                final barH = 70.0 * (data[i] - minVal) / range + 20;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isHigh)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Icon(Icons.warning_rounded, size: 12, color: Color(0xFFDC2626)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      isDecimal
                          ? data[i].toStringAsFixed(1)
                          : data[i].toInt().toString(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isHigh ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: barH,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? color : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }),
            ),
          ),
        ),
        // Ghi chú (Legend)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('Bình thường', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.warning_rounded, size: 10, color: Color(0xFFDC2626)),
              const SizedBox(width: 4),
              Text('Vượt ngưỡng (>$threshold)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Adherence Chart ─────────────────────────────────────────────────────────
  Widget _buildAdherenceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tỉ lệ tuân thủ uống thuốc',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  Text('Rất tốt',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const Text('92%',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0EA5E9))),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.92,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0F2FE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
              final status = [1, 1, 0, 1, 1, 1, 2];
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
                            : FontWeight.w500),
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
            width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  // ── Recent Alerts ──────────────────────────────────────────────────────────
  Widget _buildRecentAlerts() {
    return Column(
      children: [
        _buildAlertItem(
          icon: Icons.monitor_heart_rounded,
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFFEBEB),
          title: 'Huyết áp hơi cao',
          time: 'Hôm nay, 08:30',
          desc: 'Huyết áp 145/90 mmHg. Hãy theo dõi thêm và nghỉ ngơi.',
          sentToFamily: true,
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          icon: Icons.thermostat_rounded,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
          title: 'Nhiệt độ cơ thể tăng nhẹ',
          time: 'Hôm qua, 15:00',
          desc: 'Nhiệt độ 37.8°C. Có thể là dấu hiệu sốt nhẹ.',
          sentToFamily: true,
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          icon: Icons.cancel_rounded,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF3EEFF),
          title: 'Bỏ lỡ uống thuốc',
          time: 'Hôm qua, 13:00',
          desc: 'Vitamin D3 buổi trưa chưa được xác nhận.',
          sentToFamily: true,
        ),
      ],
    );
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
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                    ),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                if (sentToFamily) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          size: 11, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 4),
                      const Text('Đã thông báo người thân',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0EA5E9),
                              fontWeight: FontWeight.w600)),
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
                  color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFBAE6FD),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(period,
                  style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
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
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(ctx).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.download_rounded, color: Color(0xFF0EA5E9)),
                    SizedBox(width: 10),
                    Text('Xuất báo cáo sức khỏe',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Khoảng thời gian: $_selectedPeriod này',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                _exportOption(Icons.picture_as_pdf_rounded, 'Xuất file PDF', 'Báo cáo đầy đủ dạng PDF', const Color(0xFFDC2626)),
                const SizedBox(height: 10),
                _exportOption(Icons.table_chart_rounded, 'Xuất file Excel', 'Dữ liệu chỉ số dạng bảng', const Color(0xFF16A34A)),
                const SizedBox(height: 10),
                _exportOption(Icons.share_rounded, 'Chia sẻ với bác sĩ', 'Gửi link báo cáo qua Zalo/Email', const Color(0xFF7C3AED)),
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
          boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Xuất báo cáo $_selectedPeriod này',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(IconData icon, String title, String subtitle, Color color) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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

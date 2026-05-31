import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock state cho các chỉ số
  String _bpSys = '120';
  String _bpDia = '80';
  String _bloodSugar = '5.5';
  String _weight = '62.0';
  String _sleep = '7.5';

  void _showAddMetricsSheet() {
    final bpSysCtrl = TextEditingController(text: _bpSys);
    final bpDiaCtrl = TextEditingController(text: _bpDia);
    final sugarCtrl = TextEditingController(text: _bloodSugar);
    final weightCtrl = TextEditingController(text: _weight);
    final sleepCtrl = TextEditingController(text: _sleep);

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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nhập Chỉ Số Sức Khỏe',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _inputField('Huyết áp tâm thu', bpSysCtrl, 'mmHg',
                        Icons.monitor_heart_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField('Huyết áp tâm trương', bpDiaCtrl, 'mmHg',
                        Icons.favorite_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _inputField('Đường huyết', sugarCtrl, 'mmol/L',
                        Icons.water_drop_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                        'Cân nặng', weightCtrl, 'kg', Icons.scale_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _inputField('Thời gian ngủ', sleepCtrl, 'giờ',
                  Icons.nightlight_round_rounded),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9), // Light blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _bpSys = bpSysCtrl.text;
                      _bpDia = bpDiaCtrl.text;
                      _bloodSugar = sugarCtrl.text;
                      _weight = weightCtrl.text;
                      _sleep = sleepCtrl.text;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('✓ Đã cập nhật chỉ số thành công!'),
                      ),
                    );
                  },
                  child: const Text('Lưu Chỉ Số',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: unit,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF), // Sáng, đồng nhất blue theme
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNextAppointmentCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('CHỈ SỐ HÔM NAY'),
                      GestureDetector(
                        onTap: _showAddMetricsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 16, color: Color(0xFF0EA5E9)),
                              SizedBox(width: 4),
                              Text('Nhập chỉ số',
                                  style: TextStyle(
                                      color: Color(0xFF0EA5E9),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Huyết áp',
                          value: _bpSys,
                          unit: '/$_bpDia',
                          statusText: int.parse(_bpSys) > 130
                              ? 'Hơi cao'
                              : 'Bình thường',
                          statusColor: int.parse(_bpSys) > 130
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: int.parse(_bpSys) > 130
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: int.parse(_bpSys) > 130
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Đường huyết',
                          icon: Icons.water_drop_outlined,
                          value: _bloodSugar,
                          unit: ' mmol/L',
                          statusText: double.parse(_bloodSugar) > 7.0
                              ? 'Hơi cao'
                              : 'Bình thường',
                          statusColor: double.parse(_bloodSugar) > 7.0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: double.parse(_bloodSugar) > 7.0
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: double.parse(_bloodSugar) > 7.0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Cân nặng',
                          icon: Icons.scale_outlined,
                          value: _weight,
                          unit: ' kg',
                          statusText: 'Ổn định',
                          statusColor: const Color(0xFF16A34A),
                          statusBg: const Color(0xFFDCFCE7),
                          statusIcon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Giấc ngủ',
                          icon: Icons.nightlight_round_outlined,
                          value: _sleep,
                          unit: ' giờ',
                          statusText: double.parse(_sleep) < 7.0
                              ? 'Thiếu ngủ'
                              : 'Tốt',
                          statusColor: double.parse(_sleep) < 7.0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          statusBg: double.parse(_sleep) < 7.0
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          statusIcon: double.parse(_sleep) < 7.0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('BIỂU ĐỒ HUYẾT ÁP (7 NGÀY)'),
                  const SizedBox(height: 12),
                  _buildMockLineChart(),

                  const SizedBox(height: 24),
                  _buildSectionLabel('UỐNG THUỐC 7 NGÀY QUA'),
                  const SizedBox(height: 12),
                  _buildAdherenceChart(),

                  const SizedBox(height: 24),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMetricsSheet,
        backgroundColor: const Color(0xFF0EA5E9),
        child: const Icon(Icons.add_chart_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0EA5E9),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Bệnh viện Chợ Rẫy',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                SizedBox(height: 2),
                Text('BS. Nguyễn Thị Lan - Tim mạch',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text('Còn',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold)),
                Text('3',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w900)),
                Text('ngày',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Metric Card ──
  Widget _buildMetricCard({
    required String title,
    IconData? icon,
    required String value,
    required String unit,
    required String statusText,
    required Color statusColor,
    required Color statusBg,
    required IconData statusIcon,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                unit,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                      fontSize: 11,
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

  // ── Mock Line Chart for BP ──
  Widget _buildMockLineChart() {
    return Container(
      height: 160,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final heights = [60.0, 80.0, 75.0, 90.0, 65.0, 70.0, 85.0];
          final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
          final isToday = index == 6;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: heights[index],
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF0EA5E9) : const Color(0xFFBAE6FD),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(days[index],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF94A3B8))),
            ],
          );
        }),
      ),
    );
  }

  // ── Adherence Chart (Mock UI) ──
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
                  Text('Tỉ lệ tuân thủ',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  Text('Rất tốt',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('92%',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0EA5E9))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
              final status = [1, 1, 0, 1, 1, 1, 2]; // 1: full, 0: missed, 2: today partial
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
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
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                        fontSize: 12,
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
        ],
      ),
    );
  }

  // ── Recent Alerts ──
  Widget _buildRecentAlerts() {
    return Column(
      children: [
        _buildAlertItem(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFFEBEB),
          title: 'Huyết áp hơi cao',
          time: 'Hôm nay, 08:30',
          desc: 'Huyết áp 145/90 đo lúc sáng. Hãy theo dõi thêm.',
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          icon: Icons.nightlight_round_rounded,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
          title: 'Ngủ ít hơn thường lệ',
          time: 'Hôm qua',
          desc: 'Bạn chỉ ngủ 5 tiếng đêm qua. Cần nghỉ ngơi thêm.',
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

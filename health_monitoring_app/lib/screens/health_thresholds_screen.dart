import 'package:flutter/material.dart';

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
          // AppBar
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
    // Determine status
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

    // Range fractions for the slider visualization
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
          // Header
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

          // Min/Max inputs
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

          // Visual range bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LayoutBuilder(builder: (_, constraints) {
                final totalW = constraints.maxWidth;
                return Stack(
                  children: [
                    // Full background (danger)
                    Container(color: const Color(0xFFFFCDD2)),
                    // Safe zone (green)
                    Positioned(
                      left: totalW * safeStart,
                      width: totalW * (safeEnd - safeStart),
                      top: 0,
                      bottom: 0,
                      child: Container(color: const Color(0xFF86EFAC)),
                    ),
                    // Current value indicator
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
        final ctrl = TextEditingController(text: value.toStringAsFixed(
            value % 1 == 0 ? 0 : 1));
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                    setState(() =>
                        isMin ? m.min = v : m.max = v);
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

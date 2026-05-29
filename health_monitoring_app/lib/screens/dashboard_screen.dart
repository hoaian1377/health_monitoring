import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Blue Header ──
          _buildHeader(),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('CHỈ SỐ HÔM NAY'),
                  const SizedBox(height: 12),
                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Huyết áp',
                          value: '128',
                          unit: '/82',
                          statusText: 'Hơi cao',
                          statusColor: const Color(0xFFD97706),
                          statusBg: const Color(0xFFFEF3C7),
                          statusIcon: Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Đường huyết',
                          icon: Icons.water_drop_outlined,
                          value: '5.8',
                          unit: ' mmol/L',
                          statusText: 'Bình thường',
                          statusColor: const Color(0xFF16A34A),
                          statusBg: const Color(0xFFDCFCE7),
                          statusIcon: Icons.check_rounded,
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
                          value: '62',
                          unit: ' kg',
                          statusText: 'Ổn định',
                          statusColor: const Color(0xFF16A34A),
                          statusBg: const Color(0xFFDCFCE7),
                          statusIcon: Icons.check_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Giấc ngủ',
                          icon: Icons.nightlight_round_outlined,
                          value: '6.5',
                          unit: ' giờ',
                          statusText: 'Thiếu ngủ',
                          statusColor: const Color(0xFFD97706),
                          statusBg: const Color(0xFFFEF3C7),
                          statusIcon: Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('UỐNG THUỐC 7 NGÀY QUA'),
                  const SizedBox(height: 12),
                  _buildAdherenceChart(),

                  const SizedBox(height: 24),
                  _buildSectionLabel('THUỐC HÔM NAY'),
                  const SizedBox(height: 12),
                  _buildTodayMeds(),

                  const SizedBox(height: 24),
                  _buildSectionLabel('CẢNH BÁO GẦN ĐÂY'),
                  const SizedBox(height: 12),
                  _buildRecentAlerts(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tổng quan sức khỏe hôm nay',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          
          // Custom Tab Bar
          Row(
            children: [
              Expanded(child: _buildTabButton('Hôm nay', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildTabButton('7 ngày', false)),
              const SizedBox(width: 8),
              Expanded(child: _buildTabButton('30 ngày', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1D4ED8) : Colors.transparent, // Darker blue if active
        border: Border.all(color: isActive ? Colors.transparent : Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Adherence Chart ──
  Widget _buildAdherenceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tỉ lệ tuân thủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Xem chi tiết ↗', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildChartBar('T2', 1.0, '100%', const Color(0xFF2563EB)),
              _buildChartBar('T3', 0.75, '75%', const Color(0xFFF59E0B)),
              _buildChartBar('T4', 1.0, '100%', const Color(0xFF2563EB)),
              _buildChartBar('T5', 0.4, 'Bỏ', const Color(0xFFEF4444)), // Sửa lại T5 thành cột bình thường
              _buildChartBar('T6', 1.0, '100%', const Color(0xFF2563EB)),
              _buildChartBar('T7', 1.0, '100%', const Color(0xFF2563EB)),
              _buildChartBar('CN', 0.67, '67%', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF2563EB), 'Đã uống'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFF59E0B), 'Thiếu'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFFEE2E2), 'Bỏ'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double heightRatio, String label, Color color, {bool isMissing = false}) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: 80,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 24,
            height: 80 * heightRatio,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isMissing
                ? const Icon(Icons.arrow_downward, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
      ],
    );
  }

  // ── Today Meds ──
  Widget _buildTodayMeds() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('3 / 4 đã uống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Checklist ↗', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildMedItem('Amlodipine 5mg', '7:00', true),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildMedItem('Metformin 500mg', '12:00', true),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildMedItem('Atorvastatin 20mg', '20:00', false),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMedItem(String name, String time, bool isTaken) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isTaken ? 'Đã uống' : 'Chưa uống',
              style: TextStyle(
                color: isTaken ? const Color(0xFF059669) : const Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ── Recent Alerts ──
  Widget _buildRecentAlerts() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildAlertItem(
            Icons.warning_rounded,
            const Color(0xFFFEE2E2),
            const Color(0xFFDC2626),
            'Huyết áp vượt ngưỡng',
            '128/82 mmHg lúc 08:15 sáng nay',
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildAlertItem(
            Icons.medication_liquid_rounded,
            const Color(0xFFFEF3C7),
            const Color(0xFFD97706),
            'Quên uống thuốc tối',
            'Atorvastatin 20mg chưa xác nhận',
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildAlertItem(
            Icons.calendar_month_rounded,
            const Color(0xFFE0F2FE),
            const Color(0xFF0284C7),
            'Lịch tái khám sắp tới',
            'BV Chợ Rẫy — sau 3 ngày nữa',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(IconData icon, Color bg, Color iconColor, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

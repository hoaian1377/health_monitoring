import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_api_service.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _latestAlerts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final stats = await AdminApiService.getDashboardStats();
    final alerts = await AdminApiService.getLatestAlerts();
    setState(() {
      _stats = stats;
      _latestAlerts = alerts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatGrid(),
          const SizedBox(height: 32),
          if (isMobile) ...[
            _buildChartSection(),
            const SizedBox(height: 24),
            _buildLatestAlertsTable(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChartSection(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildLatestAlertsTable(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    int crossAxisCount = 6;
    double aspectRatio = 2.5;

    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      crossAxisCount = 1;
      aspectRatio = 3.0; // Higher ratio for mobile so card has enough height
    } else if (width < 800) {
      crossAxisCount = 2;
      aspectRatio = 2.2;
    } else if (width < 1200) {
      crossAxisCount = 3;
      aspectRatio = 2.5;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: aspectRatio,
      children: [
        StatCard(
          title: 'Tổng người dùng',
          value: '${_stats?['totalUsers'] ?? 0}',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF2563EB),
        ),
        StatCard(
          title: 'Tổng Elderly',
          value: '${_stats?['totalElderly'] ?? 0}',
          icon: Icons.elderly_rounded,
          color: const Color(0xFF0EA5E9),
        ),
        StatCard(
          title: 'Tổng Caregiver',
          value: '${_stats?['totalCaregiver'] ?? 0}',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFF10B981),
        ),
        StatCard(
          title: 'Tổng Admin',
          value: '${_stats?['totalAdmin'] ?? 0}',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF64748B),
        ),
        StatCard(
          title: 'Cảnh báo hôm nay',
          value: '${_stats?['alertsToday'] ?? 0}',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
        ),
        StatCard(
          title: 'SOS hôm nay',
          value: '${_stats?['sosToday'] ?? 0}',
          icon: Icons.sos_rounded,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Người dùng theo tháng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Text(titles[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 20, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 40, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 35, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 60, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 80, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF2563EB), width: 16, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestAlertsTable() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cảnh báo mới nhất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_latestAlerts == null || _latestAlerts!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('Không có cảnh báo mới.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _latestAlerts!.length,
                separatorBuilder: (ctx, index) => const Divider(),
                itemBuilder: (ctx, index) {
                  final alert = _latestAlerts![index];
                  Color statusColor = const Color(0xFFF44336);
                  if (alert['status'] == 'Đã xử lý') statusColor = const Color(0xFF4CAF50);
                  if (alert['status'] == 'Đang xử lý') statusColor = const Color(0xFFFF9800);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(Icons.warning_amber_rounded, color: statusColor, size: 20),
                    ),
                    title: Text(alert['elderlyName'] ?? ''),
                    subtitle: Text('${alert['type']} • ${alert['time']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alert['status'] ?? '',
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

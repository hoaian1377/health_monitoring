import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_api_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final data = await AdminApiService.getStatisticsCharts();
    if (mounted) {
      setState(() {
        _statsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text(
              'Thống kê chi tiết',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchStats,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Làm mới'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFF2563EB))),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Xuất báo cáo (PDF/Excel)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê chi tiết',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _fetchStats,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Làm mới'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Xuất báo cáo (PDF/Excel)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _statsData == null
                    ? const Center(child: Text('Không thể tải dữ liệu thống kê.'))
                    : _buildCharts(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildPieChartCard(),
            const SizedBox(height: 24),
            _buildBarChartCard(),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildPieChartCard(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildBarChartCard(),
        ),
      ],
    );
  }

  Widget _buildPieChartCard() {
    final roles = _statsData?['roles'] as List<dynamic>? ?? [];
    int total = 0;
    for (var r in roles) {
      total += (r['count'] as int);
    }

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
              'Tỉ lệ người dùng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: roles.isEmpty || total == 0
                  ? const Center(child: Text('Chưa có dữ liệu'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: roles.map((r) {
                          Color color = const Color(0xFF1E293B);
                          if (r['color'] != null && r['color'].toString().startsWith('#')) {
                            color = Color(int.parse(r['color'].toString().replaceFirst('#', '0xFF')));
                          }
                          final count = r['count'] as int;
                          final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                          return PieChartSectionData(
                            color: color,
                            value: count.toDouble(),
                            title: '$percentage%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            Column(
              children: roles.map((r) {
                Color color = const Color(0xFF1E293B);
                if (r['color'] != null && r['color'].toString().startsWith('#')) {
                  color = Color(int.parse(r['color'].toString().replaceFirst('#', '0xFF')));
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(r['name'], style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text('${r['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    final alerts = _statsData?['monthlyAlerts'] as List<dynamic>? ?? [];
    
    double maxY = 10;
    for (var a in alerts) {
      if (a['alerts'] > maxY) maxY = (a['alerts'] as int).toDouble() * 1.2;
    }

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
              'Số lượng cảnh báo / SOS (6 tháng qua)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: alerts.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < alerts.length) {
                                  return Text(alerts[value.toInt()]['month'].toString(), style: const TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: alerts.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value['alerts'] as int).toDouble(),
                                color: const Color(0xFFEF4444),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

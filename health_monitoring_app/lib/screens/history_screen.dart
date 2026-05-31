import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0EA5E9);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color dangerColor = const Color(0xFFEF4444);

  String selectedFilter = 'Tuần này';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineTab(),
                _buildMetricsTab(),
                _buildAppointmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x330EA5E9),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch Sử Theo Dõi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Xem lại toàn bộ hoạt động',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Đang gọi khẩn cấp...'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Dùng Thuốc'),
              Tab(text: 'Chỉ Số'),
              Tab(text: 'Khám Bệnh'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Thuốc ──
  Widget _buildMedicineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterChip('Tuần này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tháng này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tất cả')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildMetricCard('Đã uống', '18 lần', const Color(0xFF16A34A)),
                    const SizedBox(height: 12),
                    _buildMetricCard('Bỏ lỡ', '4 lần', dangerColor),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildMetricCard('Tỉ lệ', '82%', primaryColor),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                        'Trung bình', '3/ngày', const Color(0xFF6B7280)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel('LỊCH SỬ DÙNG THUỐC HÔM NAY'),
          const SizedBox(height: 12),
          _buildHistoryItem(
              time: '08:00',
              name: 'Amlodipine 5mg',
              status: 'Đã uống',
              isCompleted: true),
          _buildHistoryItem(
              time: '08:00',
              name: 'Aspirin 81mg',
              status: 'Đã uống',
              isCompleted: true),
          _buildHistoryItem(
              time: '13:00',
              name: 'Vitamin D3',
              status: 'Bỏ lỡ',
              isCompleted: false),
          _buildHistoryItem(
              time: '20:00',
              name: 'Metformin 500mg',
              status: 'Sắp tới',
              isUpcoming: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Tab 2: Chỉ Số ──
  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('LỊCH SỬ HUYẾT ÁP'),
          const SizedBox(height: 12),
          _buildMetricHistoryItem(
            date: 'Hôm nay, 07:30',
            value: '128/82 mmHg',
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildMetricHistoryItem(
            date: 'Hôm qua, 07:45',
            value: '120/80 mmHg',
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
          ),
          const SizedBox(height: 24),
          _sectionLabel('LỊCH SỬ ĐƯỜNG HUYẾT'),
          const SizedBox(height: 12),
          _buildMetricHistoryItem(
            date: '15/05/2026, 06:30',
            value: '5.8 mmol/L',
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
          ),
          _buildMetricHistoryItem(
            date: '10/05/2026, 06:15',
            value: '7.2 mmol/L',
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Tab 3: Khám Bệnh ──
  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CÁC LẦN KHÁM GẦN NHẤT'),
          const SizedBox(height: 12),
          _buildAppointmentHistoryItem(
            date: '01/03/2026',
            hospital: 'Bệnh viện Chợ Rẫy',
            doctor: 'BS. Nguyễn Thị Lan',
            result: 'Huyết áp ổn định 125/80. Tiếp tục uống thuốc.',
          ),
          _buildAppointmentHistoryItem(
            date: '15/11/2025',
            hospital: 'Phòng khám Đa khoa Thành Đô',
            doctor: 'BS. Trần Văn Minh',
            result: 'Đường huyết 5.8 mmol/L - bình thường.',
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFBAE6FD)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
          letterSpacing: 0.5),
    );
  }

  Widget _buildHistoryItem({
    required String time,
    required String name,
    required String status,
    bool isCompleted = false,
    bool isUpcoming = false,
  }) {
    Color statusColor;
    Color iconBg;
    IconData icon;

    if (isUpcoming) {
      statusColor = const Color(0xFF94A3B8);
      iconBg = const Color(0xFFF1F5F9);
      icon = Icons.access_time_rounded;
    } else if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      iconBg = const Color(0xFFDCFCE7);
      icon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626);
      iconBg = const Color(0xFFFFEBEB);
      icon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor)),
        ],
      ),
    );
  }

  Widget _buildMetricHistoryItem({
    required String date,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistoryItem({
    required String date,
    required String hospital,
    required String doctor,
    required String result,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hospital,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    Text('$doctor · $date',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(result,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF475569), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

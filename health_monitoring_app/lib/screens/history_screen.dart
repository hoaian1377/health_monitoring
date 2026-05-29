import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Color primaryColor = const Color(0xFF1A56DB);
  final Color warningColor = const Color(0xFFEF9F27);
  final Color dangerColor = const Color(0xFFE24B4A);
  final Color inactiveColor = const Color(0xFFD3D1C7);

  String selectedFilter = 'Tuần này';
  int selectedDayIndex = 3; // Chọn ngày thứ 5 (index 3)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  _buildWeekBar(),
                  const SizedBox(height: 24),
                  _buildHistoryList(),
                  const SizedBox(height: 32),
                ],
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Lịch sử dùng thuốc',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Theo dõi hằng ngày',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Nút gọi khẩn cấp (SOS) giống trang home
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
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildFilterChip('Tuần này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tháng này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tất cả')),
            ],
          ),
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
          color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMetricCard('Đã uống', '18 lần', primaryColor),
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
              _buildMetricCard('Trung bình', '3/ngày', const Color(0xFF6B7280)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    List<Map<String, dynamic>> weekDays = [
      {'day': 'T2', 'date': '26', 'status': 1}, // 1: Đủ (xanh)
      {'day': 'T3', 'date': '27', 'status': 1}, 
      {'day': 'T4', 'date': '28', 'status': 2}, // 2: Thiếu (vàng)
      {'day': 'T5', 'date': '29', 'status': 1}, // Today (selected)
      {'day': 'T6', 'date': '30', 'status': 0}, // 0: Chưa có (xám)
      {'day': 'T7', 'date': '31', 'status': 0}, 
      {'day': 'CN', 'date': '01', 'status': 0}, 
    ];

    return SizedBox(
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(weekDays.length, (index) {
          final item = weekDays[index];
          bool isSelected = index == selectedDayIndex;
          bool isToday = index == 3; // T5 là hôm nay

          Color dotColor;
          if (item['status'] == 1) dotColor = primaryColor;
          else if (item['status'] == 2) dotColor = warningColor;
          else if (item['status'] == 3) dotColor = dangerColor;
          else dotColor = inactiveColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDayIndex = index;
              });
            },
            child: Container(
              width: 42,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: (!isSelected && isToday) ? Border.all(color: primaryColor, width: 1.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['day'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['date'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        _buildDayGroup(
          dayLabel: 'Thứ Năm, 29/05',
          adherence: '100%',
          adherenceLevel: 1, // 1=xanh, 2=vàng, 3=đỏ
          meds: [
            _buildMedItem('Amlodipine 5mg', '7:00', 'Đúng giờ', 1),
            _buildMedItem('Metformin 500mg', '12:00', 'Đúng giờ', 1),
            _buildMedItem('Atorvastatin 20mg', '20:00', 'Đúng giờ', 1),
          ],
        ),
        const SizedBox(height: 24),
        _buildDayGroup(
          dayLabel: 'Thứ Tư, 28/05',
          adherence: '67%',
          adherenceLevel: 2,
          meds: [
            _buildMedItem('Amlodipine 5mg', '7:00', 'Đúng giờ', 1),
            _buildMedItem('Metformin 500mg', '12:35', 'Trễ 35p', 2),
            _buildMedItem('Atorvastatin 20mg', '—', 'Bỏ', 3),
          ],
        ),
        const SizedBox(height: 24),
        _buildDayGroup(
          dayLabel: 'Thứ Ba, 27/05',
          adherence: '100%',
          adherenceLevel: 1,
          meds: [
            _buildMedItem('Amlodipine 5mg', '7:02', 'Đúng giờ', 1),
            _buildMedItem('Metformin 500mg', '11:58', 'Đúng giờ', 1),
            _buildMedItem('Atorvastatin 20mg', '20:05', 'Đúng giờ', 1),
          ],
        ),
      ],
    );
  }

  Widget _buildDayGroup({
    required String dayLabel,
    required String adherence,
    required int adherenceLevel,
    required List<Widget> meds,
  }) {
    Color badgeBgColor;
    Color badgeTextColor;

    if (adherenceLevel == 1) { // 100%
      badgeBgColor = const Color(0xFFEAF3DE);
      badgeTextColor = const Color(0xFF27500A);
    } else if (adherenceLevel == 2) { // 67%
      badgeBgColor = const Color(0xFFFAEEDA);
      badgeTextColor = const Color(0xFF633806);
    } else { // 0%
      badgeBgColor = const Color(0xFFFCEBEB);
      badgeTextColor = const Color(0xFF791F1F);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                adherence,
                style: TextStyle(
                  color: badgeTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: meds,
          ),
        ),
      ],
    );
  }

  // statusLevel: 1 = Đúng giờ, 2 = Trễ, 3 = Bỏ
  Widget _buildMedItem(String name, String time, String statusText, int statusLevel) {
    Color iconColor;
    Color tagBgColor;
    Color tagTextColor;

    if (statusLevel == 1) { // Đúng giờ
      iconColor = primaryColor;
      tagBgColor = const Color(0xFFE0E7FF);
      tagTextColor = primaryColor;
    } else if (statusLevel == 2) { // Trễ
      iconColor = warningColor;
      tagBgColor = const Color(0xFFFEF3C7);
      tagTextColor = warningColor;
    } else { // Bỏ
      iconColor = dangerColor;
      tagBgColor = const Color(0xFFFEE2E2);
      tagTextColor = dangerColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: tagTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }
}

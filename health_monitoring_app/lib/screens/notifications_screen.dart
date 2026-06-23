import 'package:flutter/material.dart';
import 'appointment_screen.dart';
import '../utils/api_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      appBar: AppBar(
        title: const Text(
          'Thông Báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Lịch khám bệnh',
            style: TextStyle(
              fontSize: ApiService.currentRole == 'elderly' ? 20 : 16, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF475569)
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            context: context,
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Lịch khám Tim mạch sắp tới',
            time: 'Hôm nay, 08:30',
            description: 'Bác có lịch khám với BS. Nguyễn Thị Lan tại Bệnh viện Chợ Rẫy.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Lịch uống thuốc',
            style: TextStyle(
              fontSize: ApiService.currentRole == 'elderly' ? 20 : 16, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF475569)
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            context: context,
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFE0F2FE),
            title: 'Tới giờ uống thuốc Tối',
            time: '20:00, Hôm nay',
            description: 'Bác nhớ uống 1 viên Atorvastatin 20mg sau khi ăn nhé.',
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            context: context,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFEE2E2),
            title: 'Bỏ lỡ thuốc Sáng',
            time: '08:00, Hôm nay',
            description: 'Đã gửi cảnh báo tới con gái (Nguyễn Thị Bình) do bác chưa xác nhận uống Amlodipine.',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String time,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: ApiService.currentRole == 'elderly' ? 36 : 24),
          ),
          const SizedBox(width: 16),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: ApiService.currentRole == 'elderly' ? 18 : 15, 
                          color: const Color(0xFF1E293B)
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: ApiService.currentRole == 'elderly' ? 14 : 11, 
                        color: const Color(0xFF94A3B8)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ApiService.currentRole == 'elderly' ? 16 : 13, 
                    color: const Color(0xFF475569), 
                    height: 1.4
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

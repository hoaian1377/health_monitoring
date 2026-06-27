import 'package:flutter/material.dart';
import 'appointment_screen.dart';
import '../utils/api_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final String dateGroup; // 'Hôm nay' | 'Hôm qua'
  final IconData icon;
  final Color themeColor;
  final Color bgColor;
  bool isRead;
  final VoidCallback? onTapAction;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.dateGroup,
    required this.icon,
    required this.themeColor,
    required this.bgColor,
    this.isRead = false,
    this.onTapAction,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifications;
  String _filter = 'all'; // 'all' | 'unread'

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Lịch khám Tim mạch sắp tới',
        description: 'Bác có lịch khám định kỳ với BS. Nguyễn Thị Lan lúc 08:30 tại Bệnh viện Chợ Rẫy.',
        time: 'Hôm nay, 08:30',
        dateGroup: 'Hôm nay',
        icon: Icons.calendar_month_rounded,
        themeColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
        isRead: false,
        onTapAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentScreen()),
          );
        },
      ),
      NotificationItem(
        id: '2',
        title: 'Tới giờ uống thuốc Tối',
        description: 'Bác nhớ uống 1 viên thuốc mỡ máu Atorvastatin 20mg sau khi ăn tối nhé.',
        time: '20:00, Hôm nay',
        dateGroup: 'Hôm nay',
        icon: Icons.medication_rounded,
        themeColor: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Bỏ lỡ thuốc Sáng',
        description: 'Hệ thống đã tự động gửi cảnh báo tới con gái (Nguyễn Thị Bình) do bác chưa xác nhận uống Amlodipine.',
        time: '08:00, Hôm nay',
        dateGroup: 'Hôm nay',
        icon: Icons.warning_amber_rounded,
        themeColor: const Color(0xFFE11D48),
        bgColor: const Color(0xFFFFE4E6),
        isRead: false,
      ),
      NotificationItem(
        id: '4',
        title: 'Xác nhận: Đã uống thuốc trưa',
        description: 'Bác đã hoàn thành việc uống thuốc tiểu đường Metformin 500mg lúc 12:05 trưa.',
        time: '12:05, Hôm nay',
        dateGroup: 'Hôm nay',
        icon: Icons.check_circle_outline_rounded,
        themeColor: const Color(0xFF059669),
        bgColor: const Color(0xFFD1FAE5),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Nhắc nhở đo huyết áp',
        description: 'Bác hãy dành ra 5 phút nghỉ ngơi rồi đo huyết áp chiều để cập nhật nhật ký sức khỏe nhé.',
        time: '17:00, Hôm qua',
        dateGroup: 'Hôm qua',
        icon: Icons.favorite_rounded,
        themeColor: const Color(0xFFE11D48),
        bgColor: const Color(0xFFFFE4E6),
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        title: 'Nhắc nhở uống nước ấm',
        description: 'Hãy uống một cốc nước ấm lớn để duy trì tuần hoàn máu tốt bác nhé.',
        time: '10:00, Hôm qua',
        dateGroup: 'Hôm qua',
        icon: Icons.local_drink_rounded,
        themeColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFCCFBF1),
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F605A),
        content: Text('Đã đánh dấu đọc tất cả thông báo.'),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    // Lọc thông báo
    final filteredList = _notifications.where((item) {
      if (_filter == 'unread') return !item.isRead;
      return true;
    }).toList();

    // Phân nhóm thông báo theo ngày
    final todayNotifications = filteredList.where((item) => item.dateGroup == 'Hôm nay').toList();
    final yesterdayNotifications = filteredList.where((item) => item.dateGroup == 'Hôm qua').toList();

    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA), // Màu nền dịu nhẹ đồng bộ
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            title: Text(
              'Thông Báo Sức Khỏe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isElderly ? 24 : 22, color: const Color(0xFF1E293B)),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: Icon(Icons.done_all_rounded, size: isElderly ? 20 : 18, color: const Color(0xFF0F605A)),
                  label: Text(
                    'Đọc tất cả',
                    style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0F605A), fontSize: isElderly ? 16 : 14),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả (${_notifications.length})'),
                  const SizedBox(width: 10),
                  _buildFilterChip('unread', 'Chưa đọc ($unreadCount)'),
                ],
              ),
            ),
          ),
          filteredList.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Adjusted bottom padding to clear floating SOS button
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (todayNotifications.isNotEmpty) ...[
                        _buildDateHeader('Hôm nay'),
                        const SizedBox(height: 10),
                        ...todayNotifications.map((item) => _buildNotificationCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (yesterdayNotifications.isNotEmpty) ...[
                        _buildDateHeader('Hôm qua'),
                        const SizedBox(height: 10),
                        ...yesterdayNotifications.map((item) => _buildNotificationCard(item)),
                      ],
                    ]),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterType, String label) {
    final isElderly = ApiService.currentRole == 'elderly';
    final isSelected = _filter == filterType;
    return InkWell(
      onTap: () {
        setState(() {
          _filter = filterType;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F605A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF0F605A).withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isElderly ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1B8E85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: isElderly ? 17 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isElderly = ApiService.currentRole == 'elderly';
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.isRead ? 0.65 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(
            color: item.isRead ? Colors.transparent : item.themeColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  item.isRead = !item.isRead;
                });
                if (item.onTapAction != null) {
                  item.onTapAction!();
                }
              },
              child: Row(
                children: [
                  // Dải màu viền trái thể hiện phân loại
                  Container(
                    width: 6,
                    height: 100, // Chiều cao tự giãn theo nội dung
                    color: item.themeColor,
                  ),
                  const SizedBox(width: 14),

                  // Icon đại diện
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.isRead ? const Color(0xFFF1F5F9) : item.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: item.isRead ? Colors.grey : item.themeColor,
                      size: isElderly ? 26 : 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nội dung text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Chấm đỏ chỉ thị "Chưa đọc"
                              if (!item.isRead) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE11D48),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isElderly ? 18 : 16,
                                    color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: isElderly ? 16 : 14,
                              color: item.isRead ? Colors.grey.shade400 : const Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.time,
                            style: TextStyle(
                              fontSize: isElderly ? 14 : 12,
                              fontWeight: FontWeight.bold,
                              color: item.isRead ? Colors.grey.shade300 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Nút Xóa thông báo
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      setState(() {
                        _notifications.removeWhere((n) => n.id == item.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFFDC2626),
                          content: Text('Đã xóa thông báo.'),
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isElderly = ApiService.currentRole == 'elderly';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Hộp thư của bác đang trống!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isElderly ? 19 : 17, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'Không có thông báo nào cần xử lý lúc này.',
            style: TextStyle(fontSize: isElderly ? 16 : 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

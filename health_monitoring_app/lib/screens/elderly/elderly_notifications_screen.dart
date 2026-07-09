import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

class ElderlyNotificationsScreen extends StatefulWidget {
  const ElderlyNotificationsScreen({super.key});

  @override
  State<ElderlyNotificationsScreen> createState() =>
      _ElderlyNotificationsScreenState();
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final String dateGroup;
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

class _ElderlyNotificationsScreenState
    extends State<ElderlyNotificationsScreen> {
  List<NotificationItem> _notifications = [];
  String _filter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      List<NotificationItem> loaded = [];
      for (var item in data) {
        final notifDetail = item['details'] != null && item['details'].isNotEmpty
            ? item['details'][0]
            : null;
        bool isRead = notifDetail != null ? notifDetail['is_read'] : false;
        String id = notifDetail != null
            ? notifDetail['notification_detailid'].toString()
            : item['notificationid'].toString();

        String title = item['title'] ?? 'Thông báo';
        String desc = item['message'] ?? '';

        IconData icon = Icons.notifications_active_rounded;
        Color themeColor = const Color(0xFF0284C7);
        Color bgColor = const Color(0xFFE0F2FE);

        if (title.toLowerCase().contains('khám')) {
          icon = Icons.calendar_month_rounded;
          themeColor = const Color(0xFFD97706);
          bgColor = const Color(0xFFFEF3C7);
        } else if (title.toLowerCase().contains('thuốc') ||
            title.toLowerCase().contains('nhắc nhở')) {
          icon = Icons.medication_rounded;
          themeColor = const Color(0xFFE11D48);
          bgColor = const Color(0xFFFFE4E6);
        }

        String timeStr = '';
        if (item['created_at'] != null) {
          try {
            final dt = DateTime.parse(item['created_at']).toLocal();
            timeStr =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}';
          } catch (_) {}
        }

        loaded.add(NotificationItem(
          id: id,
          title: title,
          description: desc,
          time: timeStr,
          dateGroup: 'Gần đây',
          icon: icon,
          themeColor: themeColor,
          bgColor: bgColor,
          isRead: isRead,
        ));
      }
      if (mounted) {
        setState(() {
          _notifications = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0284C7),
        content: Text('Đã đánh dấu đọc tất cả thông báo.'),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredList = _notifications.where((item) {
      if (_filter == 'unread') return !item.isRead;
      return true;
    }).toList();

    final todayNotifications = filteredList
        .where((item) =>
            item.dateGroup == 'Hôm nay' || item.dateGroup == 'Gần đây')
        .toList();
    final yesterdayNotifications =
        filteredList.where((item) => item.dateGroup == 'Hôm qua').toList();

    final unreadCount =
        _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            title: const Text(
              'Thông Báo Sức Khỏe',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF1E293B)),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all_rounded,
                      size: 20, color: Color(0xFF0284C7)),
                  label: const Text(
                    'Đọc tất cả',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                        fontSize: 16),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (todayNotifications.isNotEmpty) ...[
                        _buildDateHeader('Hôm nay'),
                        const SizedBox(height: 10),
                        ...todayNotifications
                            .map((item) => _buildNotificationCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (yesterdayNotifications.isNotEmpty) ...[
                        _buildDateHeader('Hôm qua'),
                        const SizedBox(height: 10),
                        ...yesterdayNotifications
                            .map((item) => _buildNotificationCard(item)),
                      ],
                    ]),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterType, String label) {
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
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.isRead ? 0.8 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            color: item.isRead
                ? Colors.transparent
                : item.themeColor.withValues(alpha: 0.15),
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
                  Container(
                    width: 6,
                    height: 100,
                    color: item.themeColor,
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.isRead
                          ? const Color(0xFFF1F5F9)
                          : item.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color:
                          item.isRead ? Colors.grey.shade600 : item.themeColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
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
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                    color: item.isRead
                                        ? const Color(0xFF475569)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 18,
                              color: item.isRead
                                  ? Colors.grey.shade700
                                  : const Color(0xFF334155),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.time,
                            style: TextStyle(
                              fontSize: 15,
                              color: item.isRead
                                  ? Colors.grey.shade500
                                  : item.themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      setState(() {
                        _notifications
                            .removeWhere((n) => n.id == item.id);
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
          const Text(
            'Hộp thư của bác đang trống!',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Không có thông báo nào cần xử lý lúc này.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

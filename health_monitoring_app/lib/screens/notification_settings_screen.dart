import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification toggles
  final List<_NotifItem> _items = [
    _NotifItem(
        icon: Icons.medication_rounded,
        iconBg: const Color(0xFFEBF3FF),
        iconColor: const Color(0xFF2563EB),
        title: 'Nhắc uống thuốc',
        subtitle: 'Nhắc nhở theo lịch uống thuốc hàng ngày',
        enabled: true),
    _NotifItem(
        icon: Icons.calendar_month_rounded,
        iconBg: const Color(0xFFE6FBF3),
        iconColor: const Color(0xFF16A34A),
        title: 'Nhắc lịch tái khám',
        subtitle: 'Thông báo trước ngày hẹn tái khám',
        enabled: true),
    _NotifItem(
        icon: Icons.favorite_rounded,
        iconBg: const Color(0xFFFFEBEB),
        iconColor: const Color(0xFFDC2626),
        title: 'Cảnh báo huyết áp',
        subtitle: 'Khi huyết áp vượt ngưỡng an toàn',
        enabled: true),
    _NotifItem(
        icon: Icons.water_drop_rounded,
        iconBg: const Color(0xFFFFF4E6),
        iconColor: const Color(0xFFEA580C),
        title: 'Cảnh báo đường huyết',
        subtitle: 'Khi đường huyết vượt ngưỡng an toàn',
        enabled: true),
    _NotifItem(
        icon: Icons.bar_chart_rounded,
        iconBg: const Color(0xFFF3EEFF),
        iconColor: const Color(0xFF7C3AED),
        title: 'Báo cáo tuần',
        subtitle: 'Tổng hợp sức khỏe mỗi cuối tuần',
        enabled: false),
  ];

  // Quiet hours
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  // Sound & vibration
  bool _soundEnabled = true;
  String _vibrationMode = 'Rung chuẩn';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
    );
    if (picked != null) {
      setState(() => isStart ? _quietStart = picked : _quietEnd = picked);
    }
  }

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
            Text('Đã lưu cài đặt thông báo ✓',
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
                colors: [Color(0xFF14532D), Color(0xFF16A34A)],
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
                      Text('Cài đặt thông báo',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Tuỳ chỉnh nhắc nhở & cảnh báo',
                          style: TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.notifications_rounded,
                    color: Colors.white70, size: 24),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification types
                  const Text('LOẠI THÔNG BÁO',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: _items.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: item.iconBg,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(item.icon,
                                        color: item.iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B))),
                                        const SizedBox(height: 2),
                                        Text(item.subtitle,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: item.enabled,
                                    onChanged: (v) => setState(
                                        () => _items[i].enabled = v),
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                            if (i < _items.length - 1)
                              const Divider(
                                  height: 1,
                                  indent: 66,
                                  color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quiet hours
                  const Text('THỜI GIAN YÊN LẶNG',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EEFF),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.bedtime_rounded,
                                  color: Color(0xFF7C3AED), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Không nhận thông báo',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Từ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _pickTime(true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded,
                                              color: Color(0xFF7C3AED),
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                              _quietStart
                                                  .format(context),
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 20, left: 12, right: 12),
                              child: Text('đến',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF94A3B8))),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Đến',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _pickTime(false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded,
                                              color: Color(0xFF7C3AED),
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Text(_quietEnd.format(context),
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sound & vibration
                  const Text('ÂM THANH & RUNG',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Sound toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.volume_up_rounded,
                                    color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Âm thanh thông báo',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B))),
                              ),
                              Switch(
                                value: _soundEnabled,
                                onChanged: (v) =>
                                    setState(() => _soundEnabled = v),
                                activeColor: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                            height: 1, indent: 66, color: Color(0xFFF1F5F9)),
                        // Vibration dropdown
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.vibration_rounded,
                                    color: Color(0xFFEA580C), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Kiểu rung',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B))),
                              ),
                              DropdownButton<String>(
                                value: _vibrationMode,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600),
                                items: [
                                  'Không rung',
                                  'Rung chuẩn',
                                  'Rung mạnh',
                                  'Rung ngắn'
                                ]
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: Text(v)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _vibrationMode = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Lưu cài đặt',
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
}

class _NotifItem {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  bool enabled;
  _NotifItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });
}

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSOSButton(),
                  const SizedBox(height: 24),

                  _buildSectionLabel('HỒ SƠ & THÔNG TIN CÁ NHÂN'),
                  const SizedBox(height: 8),
                  _buildMenuGroup([
                    _MenuItemData(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFEBF3FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Hồ sơ cá nhân',
                      subtitle: 'Tên, ngày sinh, địa chỉ, ảnh đại diện',
                    ),
                    _MenuItemData(
                      icon: Icons.medical_services_outlined,
                      iconBg: const Color(0xFFE6FBF3),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Hồ sơ khám bệnh',
                      subtitle: 'Bệnh nền, dị ứng, nhóm máu, tiền sử bệnh',
                    ),
                    _MenuItemData(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF3EEFF),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Toa thuốc & xét nghiệm',
                      subtitle: 'Upload, xem lại toa thuốc & kết quả xét nghiệm',
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionLabel('LIÊN KẾT GIA ĐÌNH'),
                  const SizedBox(height: 8),
                  _buildMenuGroup([
                    _MenuItemData(
                      icon: Icons.people_outline_rounded,
                      iconBg: const Color(0xFFFFF4E6),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Liên kết người thân',
                      subtitle: 'Kết nối con cháu & người chăm sóc trong gia đình',
                    ),
                    _MenuItemData(
                      icon: Icons.contact_phone_outlined,
                      iconBg: const Color(0xFFFFEBEB),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Liên lạc khẩn cấp',
                      subtitle: 'Danh sách số điện thoại ưu tiên khi SOS',
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionLabel('CÀI ĐẶT & ỨNG DỤNG'),
                  const SizedBox(height: 8),
                  _buildMenuGroup([
                    _MenuItemData(
                      icon: Icons.notifications_outlined,
                      iconBg: const Color(0xFFE6FBF3),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Cài đặt thông báo',
                      subtitle: 'Nhắc uống thuốc, lịch khám, cảnh báo sức khỏe',
                    ),
                    _MenuItemData(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFFF4E6),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Ngưỡng cảnh báo sức khỏe',
                      subtitle: 'Huyết áp, đường huyết, cân nặng bất thường',
                    ),
                  ]),

                  const SizedBox(height: 8),
                  _buildLogoutButton(),
                  const SizedBox(height: 24),
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
      color: const Color(0xFF2563EB),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Người dùng',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hệ thống theo dõi sức khỏe người cao tuổi',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'NV',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nguyễn Văn An',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '079205023561 · Người lớn tuổi',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Đã xác minh',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2563EB), size: 28),
                const SizedBox(width: 14),
                // ✅ FIX: Expanded để tránh overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SOS — Gọi người thân',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gọi ngay cho người liên hệ khẩn cấp',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuItem(item),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 62, color: Color(0xFFF0F0F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thoát khỏi tài khoản hiện tại',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MenuItemData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

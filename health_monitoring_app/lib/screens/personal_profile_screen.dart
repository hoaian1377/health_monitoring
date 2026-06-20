import 'package:flutter/material.dart';
import '../utils/global_state.dart';
import '../utils/api_service.dart';

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  // ─── Tính tuổi từ ngày sinh ──────────────────────────────────────────────
  int get _age {
    final birth = DateTime(1955, 3, 15);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  void _showSaveToast() {
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
            Text('Đã lưu thành công ✓',
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
          // ── Header / Avatar block ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Hồ sơ cá nhân',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                // Avatar circle
                Builder(
                  builder: (context) {
                    final displayName = ApiService.currentFullname.isNotEmpty
                        ? ApiService.currentFullname
                        : ApiService.currentUsername;
                    final avatarText = displayName.isNotEmpty ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase() : 'ND';
                    final roleText = ApiService.currentRole == 'caregiver' ? 'Người chăm sóc' : 'Người lớn tuổi';

                    return Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(avatarText,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0EA5E9))),
                        ),
                        const SizedBox(height: 12),
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(roleText,
                            style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text('Đã xác minh',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card: Thông tin cơ bản
                  _buildCard(
                    title: 'Thông tin cơ bản',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    children: [
                      Builder(
                        builder: (context) {
                          final displayName = ApiService.currentFullname.isNotEmpty
                              ? ApiService.currentFullname
                              : ApiService.currentUsername;
                          final dobText = ApiService.currentDob.isNotEmpty ? ApiService.currentDob : 'Chưa cập nhật';
                          final genderText = ApiService.currentGender.isNotEmpty ? ApiService.currentGender : 'Chưa cập nhật';

                          return Column(
                            children: [
                              _infoRow(Icons.person_outline_rounded,
                                  const Color(0xFFEBF3FF), const Color(0xFF0EA5E9), 'Họ và tên', displayName),
                              _divider(),
                              _infoRow(Icons.cake_outlined, const Color(0xFFFFF4E6),
                                  const Color(0xFFEA580C), 'Ngày sinh', dobText),
                              _divider(),
                              _infoRow(Icons.male_rounded, const Color(0xFFE6FBF3), const Color(0xFF16A34A),
                                  'Giới tính', genderText),
                            ],
                          );
                        }
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card: Liên hệ
                  _buildCard(
                    title: 'Liên hệ',
                    icon: Icons.contact_mail_rounded,
                    iconColor: const Color(0xFF16A34A),
                    children: [
                      _infoRow(
                          Icons.phone_outlined,
                          const Color(0xFFE6FBF3),
                          const Color(0xFF16A34A),
                          'Số điện thoại',
                          ApiService.currentPhone.isNotEmpty ? ApiService.currentPhone : 'Chưa cập nhật'),
                      _divider(),
                      _infoRow(
                          Icons.email_outlined,
                          const Color(0xFFEBF3FF),
                          const Color(0xFF0EA5E9),
                          'Email',
                          ApiService.currentEmail.isNotEmpty ? ApiService.currentEmail : 'Chưa cập nhật'),
                      _divider(),
                      _infoRow(
                          Icons.credit_card_rounded,
                          const Color(0xFFFFF4E6),
                          const Color(0xFFEA580C),
                          'Username',
                          ApiService.currentUsername),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card: Vai trò & liên kết gia đình
                  _buildCard(
                    title: 'Vai trò & liên kết gia đình',
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFFEA580C),
                    children: [
                      Builder(
                          builder: (context) {
                            final displayName = ApiService.currentFullname.isNotEmpty
                                ? ApiService.currentFullname
                                : ApiService.currentUsername;
                            final roleText = ApiService.currentRole == 'caregiver' ? 'Người chăm sóc' : 'Người lớn tuổi';

                            return _roleRow(
                                color: const Color(0xFF0EA5E9),
                                name: displayName,
                                role: roleText,
                                badgeText: 'Đang dùng',
                                badgeColor: const Color(0xFF16A34A));
                          }),
                      _divider(),
                      _roleRow(
                          color: const Color(0xFF0D9488),
                          name: 'Nguyễn Thị Bình',
                          role: 'Con gái',
                          badgeText: 'Đã kết nối',
                          badgeColor: const Color(0xFF0EA5E9)),
                      _divider(),
                      _roleRow(
                          color: const Color(0xFFD97706),
                          name: 'Trần Văn C',
                          role: 'Người chăm sóc',
                          badgeText: 'Chờ xác nhận',
                          badgeColor: const Color(0xFFD97706)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showSaveToast,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Lưu thay đổi',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: iconColor)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color bg, Color iconColor, String label,
      String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1), size: 18),
        ],
      ),
    );
  }

  Widget _roleRow({
    required Color color,
    required String name,
    required String role,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                Text(role,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badgeText,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 62, color: Color(0xFFF1F5F9));
}

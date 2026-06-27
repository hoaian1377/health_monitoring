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
    final isElderly = ApiService.currentRole == 'elderly';
    final themeColor = isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9);
    final gradientColors = isElderly 
        ? [const Color(0xFF0F605A), const Color(0xFF1B8E85)]
        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)];

    return Scaffold(
      backgroundColor: isElderly ? const Color(0xFFF3F7FA) : const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // ── Header / Avatar block ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(isElderly ? 'Hồ sơ của bác' : 'Hồ sơ cá nhân',
                        style: const TextStyle(
                            fontSize: 20,
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
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(avatarText,
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor)),
                        ),
                        const SizedBox(height: 12),
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(isElderly ? 'Tài khoản người lớn tuổi' : roleText,
                            style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
                    title: isElderly ? 'Thông tin cơ bản của bác' : 'Thông tin cơ bản',
                    icon: Icons.person_rounded,
                    iconColor: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
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
                                  isElderly ? const Color(0xFFEBFDFB) : const Color(0xFFEBF3FF), 
                                  isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9), 
                                  'Họ và tên', displayName),
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
                    title: isElderly ? 'Thông tin liên hệ của bác' : 'Liên hệ',
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
                          isElderly ? const Color(0xFFEBFDFB) : const Color(0xFFEBF3FF),
                          isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
                          'Email liên hệ',
                          ApiService.currentEmail.isNotEmpty ? ApiService.currentEmail : 'Chưa cập nhật'),
                      _divider(),
                      _infoRow(
                          Icons.credit_card_rounded,
                          const Color(0xFFFFF4E6),
                          const Color(0xFFEA580C),
                          'Tên đăng nhập',
                          ApiService.currentUsername),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card: Vai trò & liên kết gia đình
                  _buildCard(
                    title: isElderly ? 'Danh sách người thân liên kết' : 'Vai trò & liên kết gia đình',
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
                                color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
                                name: displayName,
                                role: isElderly ? 'Tài khoản của bác' : roleText,
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
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(isElderly ? 'Lưu thông tin của bác' : 'Lưu thay đổi',
                          style: const TextStyle(
                              fontSize: 17,
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
    final isElderly = ApiService.currentRole == 'elderly';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isElderly ? 18 : 16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, isElderly ? 18 : 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: isElderly ? 20 : 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: isElderly ? 15 : 14,
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
    final isElderly = ApiService.currentRole == 'elderly';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isElderly ? 15 : 13),
      child: Row(
        children: [
          Container(
            width: isElderly ? 40 : 34,
            height: isElderly ? 40 : 34,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: isElderly ? 19 : 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: isElderly ? 12 : 11, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: isElderly ? 15.5 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: const Color(0xFFCBD5E1), size: isElderly ? 20 : 18),
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
    final isElderly = ApiService.currentRole == 'elderly';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isElderly ? 15 : 13),
      child: Row(
        children: [
          Container(
            width: isElderly ? 12 : 10,
            height: isElderly ? 12 : 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: isElderly ? 15.5 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B))),
                Text(role,
                    style: TextStyle(
                        fontSize: isElderly ? 12.5 : 12, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badgeText,
                style: TextStyle(
                    fontSize: isElderly ? 11.5 : 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 62, color: Color(0xFFF1F5F9));
}

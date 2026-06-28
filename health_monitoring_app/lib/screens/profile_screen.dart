import 'package:flutter/material.dart';
import 'personal_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'manage_profiles_screen.dart';
import 'admin_backup_screen.dart';
import 'health_dashboard_screen.dart';
import 'add_elderly_screen.dart';
import 'elderly_list_screen.dart';
import '../utils/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ─── SOS Bottom Sheet ───────────────────────────────────────────────────────
  void _showSOSSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SOSBottomSheet(),
    );
  }

  // ─── Logout Dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    final isElderly = ApiService.currentRole == 'elderly';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isElderly ? 24 : 20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isElderly ? 64 : 56,
                height: isElderly ? 64 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(isElderly ? 18 : 16),
                ),
                child: Icon(Icons.logout_rounded,
                    color: const Color(0xFFC81E1E), size: isElderly ? 32 : 28),
              ),
              const SizedBox(height: 16),
              Text(
                isElderly ? 'Đăng xuất tài khoản?' : 'Đăng xuất?',
                style: TextStyle(
                    fontSize: isElderly ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                isElderly 
                    ? 'Bác có chắc chắn muốn đăng xuất khỏi tài khoản không ạ?' 
                    : 'Bạn có chắc muốn thoát khỏi tài khoản?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isElderly ? 15 : 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: EdgeInsets.symmetric(vertical: isElderly ? 16 : 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isElderly ? 'Quay lại' : 'Hủy',
                          style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: isElderly ? 15 : 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC81E1E),
                        padding: EdgeInsets.symmetric(vertical: isElderly ? 16 : 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isElderly ? 'Đăng xuất' : 'Đăng xuất',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isElderly ? 15 : 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Scaffold(
      backgroundColor: isElderly ? const Color(0xFFF3F7FA) : const Color(0xFFF0F4FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isElderly)
              _buildElderlyHeader()
            else
              _buildHeader(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isElderly)
                    _buildElderlySOSButton()
                  else
                    _buildSOSButton(),
                  const SizedBox(height: 24),

                  if (isElderly) ...[
                    _sectionLabel('LIÊN LẠC & AN TOÀN'),
                    const SizedBox(height: 8),
                    _menuGroup([
                      _MenuItem(
                        icon: Icons.contact_phone_outlined,
                        iconBg: const Color(0xFFFFEBEB),
                        iconColor: const Color(0xFFDC2626),
                        title: 'Người liên hệ khẩn cấp',
                        subtitle: 'Số điện thoại của người thân khi cần hỗ trợ',
                        onTap: () => _navigate(const EmergencyContactsScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ] else ...[
                    _sectionLabel('HỒ SƠ & THÔNG TIN CÁ NHÂN'),
                    const SizedBox(height: 8),
                    _menuGroup([
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        iconBg: const Color(0xFFEBF3FF),
                        iconColor: const Color(0xFF0EA5E9),
                        title: 'Hồ sơ cá nhân',
                        subtitle: 'Tên, ngày sinh, địa chỉ, ảnh đại diện',
                        onTap: () => _navigate(const PersonalProfileScreen()),
                      ),
                      _MenuItem(
                        icon: Icons.health_and_safety_outlined,
                        iconBg: const Color(0xFFE6FBF3),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Hồ sơ sức khỏe',
                        subtitle: 'Tổng quan, toa thuốc, giấy tờ và lịch khám',
                        onTap: () => _navigate(const HealthDashboardScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── QUẢN LÝ NGƯỜI CAO TUỔI (caregiver only)
                    _sectionLabel('QUẢN LÝ NGƯỜI CAO TUỔI'),
                    const SizedBox(height: 8),
                    _menuGroup([
                      _MenuItem(
                        icon: Icons.person_add_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Thêm người cao tuổi',
                        subtitle: 'Tạo hồ sơ mới & sinh mã QR đăng nhập',
                        onTap: () => _navigate(const AddElderlyScreen()),
                      ),
                      _MenuItem(
                        icon: Icons.qr_code_scanner_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Xem danh sách người cao tuổi',
                        subtitle: 'Quản lý, xem và sửa hồ sơ đã tạo',
                        onTap: () => _navigate(const ElderlyListScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  _sectionLabel('CÀI ĐẶT & ỨNG DỤNG'),
                  const SizedBox(height: 8),
                  _menuGroup([
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: const Color(0xFFF3EEFF),
                      iconColor: const Color(0xFF7C3AED),
                      title: isElderly ? 'Đổi mật khẩu bảo mật' : 'Đổi mật khẩu',
                      subtitle: isElderly ? 'Đổi mật khẩu đăng nhập của bác' : 'Bảo mật tài khoản của bạn',
                      onTap: () => _navigate(const ChangePasswordScreen()),
                    ),
                  ]),

                  if (ApiService.currentRole == 'admin') ...[
                    const SizedBox(height: 24),
                    _sectionLabel('QUẢN TRỊ HỆ THỐNG'),
                    const SizedBox(height: 8),
                    _menuGroup([
                      _MenuItem(
                        icon: Icons.switch_account_rounded,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        title: 'Quản lý người dùng',
                        subtitle: 'Thêm, xóa, phân quyền (F02)',
                        onTap: () => _navigate(const ManageProfilesScreen()),
                      ),
                      _MenuItem(
                        icon: Icons.storage_rounded,
                        iconBg: const Color(0xFFF3EEFF),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Sao lưu & Phục hồi CSDL',
                        subtitle: 'Xuất / nhập dữ liệu toàn bộ hệ thống',
                        onTap: () => _navigate(const AdminBackupScreen()),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 16),
                  if (isElderly)
                    _buildElderlyLogoutButton()
                  else
                    _buildLogoutButton(),
                  SizedBox(height: isElderly ? 100 : 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final displayName = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;
    final avatar = displayName.isNotEmpty ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase() : 'ND';
    final roleText = ApiService.currentRole == 'caregiver' ? 'Người chăm sóc' : 'Người lớn tuổi';
    final phoneText = ApiService.currentPhone.isNotEmpty ? ApiService.currentPhone : ApiService.currentUsername;

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
              color: Color(0x332563EB),
              blurRadius: 16,
              offset: Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hồ sơ của bạn',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Hệ thống theo dõi sức khỏe người cao tuổi',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(avatar,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('$phoneText · $roleText',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.white70),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Đã xác minh',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageProfilesScreen()),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  tooltip: 'Chuyển đổi hồ sơ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SOS Button ─────────────────────────────────────────────────────────────
  Widget _buildSOSButton() {
    return Material(
      color: const Color(0xFFC81E1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showSOSSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.phone_callback_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS — Gọi người thân',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Gọi ngay cho người liên hệ khẩn cấp',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Elderly Header ─────────────────────────────────────────────────────────
  Widget _buildElderlyHeader() {
    final displayName = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;
    final avatar = displayName.isNotEmpty ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase() : 'ND';
    final phoneText = ApiService.currentPhone.isNotEmpty ? ApiService.currentPhone : ApiService.currentUsername;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F605A), Color(0xFF1B8E85)], // Brand Slate Teal
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x220F605A),
              blurRadius: 16,
              offset: Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chào bác,',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(displayName,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(avatar,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('SĐT: $phoneText · Tài khoản bác',
                          style:
                              const TextStyle(fontSize: 15, color: Colors.white70),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Đã bảo mật',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageProfilesScreen()),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                  tooltip: 'Chuyển đổi hồ sơ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Elderly SOS Button ─────────────────────────────────────────────────────
  Widget _buildElderlySOSButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _showSOSSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                const Icon(Icons.phone_callback_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GỌI KHẨN CẤP (SOS)',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                      SizedBox(height: 3),
                      Text('Nhấn vào đây để gọi nhanh cho con cháu',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section label ───────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Text(label,
        style: TextStyle(
            fontSize: isElderly ? 14 : 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.6));
  }

  // ─── Menu Group ──────────────────────────────────────────────────────────────
  Widget _menuGroup(List<_MenuItem> items) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon,
                              color: item.iconColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: TextStyle(
                                      fontSize: isElderly ? 16.5 : 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(item.subtitle,
                                  style: TextStyle(
                                      fontSize: isElderly ? 14 : 12,
                                      color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1, indent: 62, color: Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Logout Button ───────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _showLogoutDialog,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout_rounded,
                      color: Color(0xFFC81E1E), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Đăng xuất',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC81E1E))),
                      SizedBox(height: 2),
                      Text('Thoát khỏi tài khoản hiện tại',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Elderly Logout Button ──────────────────────────────────────────────────
  Widget _buildElderlyLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: const Color(0xFFFFEBEB), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _showLogoutDialog,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout_rounded,
                      color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đăng xuất tài khoản',
                          style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626))),
                      SizedBox(height: 2),
                      Text('Thoát khỏi ứng dụng',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFCBD5E1), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SOS Bottom Sheet ─────────────────────────────────────────────────────────
class _SOSBottomSheet extends StatelessWidget {
  const _SOSBottomSheet();

  static const _contacts = [
    _SOSContact(
        name: 'Nguyễn Thị Bình',
        role: 'Con gái',
        phone: '0901 234 567',
        isEmergency: false),
    _SOSContact(
        name: 'Trần Văn C',
        role: 'Người chăm sóc',
        phone: '0912 345 678',
        isEmergency: false),
    _SOSContact(
        name: 'Cấp cứu',
        role: 'Khẩn cấp',
        phone: '115',
        isEmergency: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(isElderly ? 28 : 24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: isElderly ? 46 : 40,
                height: isElderly ? 46 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(isElderly ? 12 : 10),
                ),
                child: Icon(Icons.phone_callback_rounded,
                    color: const Color(0xFFC81E1E), size: isElderly ? 24 : 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isElderly ? 'Gọi điện khẩn cấp cho con cháu' : 'SOS — Gọi người thân',
                        style: TextStyle(
                            fontSize: isElderly ? 18 : 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B))),
                    Text(isElderly ? 'Bác chọn người muốn gọi điện dưới đây' : 'Chọn người để gọi ngay',
                        style:
                            TextStyle(fontSize: isElderly ? 13 : 12, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._contacts.map((c) => _buildContactRow(context, c)),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, _SOSContact c) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isElderly ? 16 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(isElderly ? 16 : 12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: isElderly ? 50 : 44,
            height: isElderly ? 50 : 44,
            decoration: BoxDecoration(
              color: c.isEmergency
                  ? const Color(0xFFFFEBEB)
                  : const Color(0xFFEBFDFB),
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: Text(
              c.isEmergency ? '🚑' : c.name[0],
              style: TextStyle(
                fontSize: c.isEmergency ? (isElderly ? 22 : 20) : (isElderly ? 18 : 16),
                fontWeight: FontWeight.bold,
                color: c.isEmergency ? const Color(0xFFC81E1E) : const Color(0xFF0F605A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: TextStyle(
                        fontSize: isElderly ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text('${c.role} · ${c.phone}',
                    style: TextStyle(
                        fontSize: isElderly ? 13.5 : 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: const Color(0xFF16A34A),
                content: Text('Đang gọi ${c.phone}...'),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              width: isElderly ? 44 : 40,
              height: isElderly ? 44 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone_rounded,
                  color: Colors.white, size: isElderly ? 22 : 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SOSContact {
  final String name, role, phone;
  final bool isEmergency;
  const _SOSContact(
      {required this.name,
      required this.role,
      required this.phone,
      required this.isEmergency});
}

class _MenuItem {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

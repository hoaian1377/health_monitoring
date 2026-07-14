import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'elderly_emergency_contacts_screen.dart';
import '../login_screen.dart';
import 'elderly_change_password_screen.dart';
import '../../utils/api_service.dart';
import '../caregiver/caregiver_health_settings_screen.dart';
import '../../utils/elderly_provider.dart';

class ElderlyProfileScreen extends StatefulWidget {
  const ElderlyProfileScreen({super.key});

  @override
  State<ElderlyProfileScreen> createState() => _ElderlyProfileScreenState();
}

class _ElderlyProfileScreenState extends State<ElderlyProfileScreen> {
  // ─── SOS Bottom Sheet ───────────────────────────────────────────────────────
  void _showSOSSheet() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final caregivers = await ApiService.getCaregiversForElderly();
    if (mounted) {
      Navigator.pop(context); // close loading
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ElderlySOSBottomSheet(caregivers: caregivers),
      );
    }
  }

  // ─── Logout Dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFC81E1E), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đăng xuất tài khoản?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bác có chắc chắn muốn đăng xuất khỏi tài khoản không ạ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quay lại',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ApiService.logout();
                        ElderlyProvider.instance.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC81E1E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Đăng xuất',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildElderlyHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildElderlySOSButton(),
                  const SizedBox(height: 24),

                  _sectionLabel('HỒ SƠ SỨC KHOẺ'),
                  const SizedBox(height: 8),
                  _menuGroup([
                    _MenuItem(
                      icon: Icons.health_and_safety_outlined,
                      iconBg: const Color(0xFFE6FBF3),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Hồ sơ bệnh án',
                      subtitle: 'Bệnh án, toa thuốc, giấy tờ và các lần khám bệnh',
                      onTap: () => _navigate(const HealthDashboardScreen()),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  const SizedBox(height: 16),
                  _buildElderlyLogoutButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Elderly Header ─────────────────────────────────────────────────────────
  Widget _buildElderlyHeader() {
    final displayName = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;
    final avatar = displayName.isNotEmpty
        ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase()
        : 'ND';
    final phoneText = ApiService.currentPhone.isNotEmpty
        ? ApiService.currentPhone
        : ApiService.currentUsername;

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
              color: Color(0x220284C7),
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
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white70),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              fontSize: 14, color: Colors.white70)),
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
    return Text(label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.6));
  }

  // ─── Menu Group ──────────────────────────────────────────────────────────────
  Widget _menuGroup(List<_MenuItem> items) {
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
                                  style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(item.subtitle,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF94A3B8))),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

// ─── Elderly SOS Bottom Sheet ─────────────────────────────────────────────────
class _ElderlySOSBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> caregivers;
  const _ElderlySOSBottomSheet({required this.caregivers});

  @override
  Widget build(BuildContext context) {
    // Thêm các số liên lạc khẩn cấp mặc định vào cuối
    List<_SOSContact> allContacts = caregivers.map((c) => _SOSContact(
      name: c['fullname'] ?? 'Người chăm sóc',
      role: 'Người chăm sóc',
      phone: c['phone'] ?? '',
      isEmergency: false,
    )).toList();

    allContacts.add(const _SOSContact(
        name: 'Cấp cứu',
        role: 'Khẩn cấp',
        phone: '115',
        isEmergency: true));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 32 + MediaQuery.of(context).padding.bottom),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_callback_rounded,
                    color: Color(0xFFC81E1E), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gọi điện khẩn cấp cho con cháu',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    Text('Bác chọn người muốn gọi điện dưới đây',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...allContacts.map((c) => _buildContactRow(context, c)),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, _SOSContact c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: c.isEmergency
                  ? const Color(0xFFFFEBEB)
                  : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: Text(
              c.isEmergency ? '🚑' : c.name[0],
              style: TextStyle(
                fontSize: c.isEmergency ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: c.isEmergency
                    ? const Color(0xFFC81E1E)
                    : const Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text('${c.role} · ${c.phone}',
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              // Gửi notification tới người chăm sóc
              ApiService.sendSOSNotification();

              // Gọi điện bằng url_launcher
              final Uri phoneUri = Uri(
                scheme: 'tel',
                path: c.phone.replaceAll(' ', ''),
              );
              try {
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: const Color(0xFFEF4444),
                    content: Text('Không thể gọi số ${c.phone}'),
                    duration: const Duration(seconds: 2),
                  ));
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: const Color(0xFFEF4444),
                  content: Text('Thiết bị không hỗ trợ gọi điện'),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _SOSContact {
  final String name;
  final String role;
  final String phone;
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

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/global_state.dart';
import '../utils/api_service.dart';

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {

  void _switchActive(int index) {
    globalState.switchActiveProfile(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0EA5E9),
        content: Text('Đã chuyển sang hồ sơ: ${globalState.profiles.value[index].name}'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Delay slightly to let user see SnackBar before popping
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.pop(context, globalState.profiles.value[index].name);
      }
    });
  }

  void _deleteProfile(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa hồ sơ?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa hồ sơ "${globalState.profiles.value[index].name}"? Dữ liệu sức khỏe liên quan sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              globalState.deleteProfile(index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFDC2626),
                  content: Text('Đã xóa hồ sơ thành công'),
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditDialog({ElderlyProfile? existing, int? editIndex}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dobCtrl = TextEditingController(text: existing?.dob ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final bloodCtrl = TextEditingController(text: existing?.bloodType ?? '');
    final diseasesCtrl = TextEditingController(text: existing?.diseases ?? '');
    final allergiesCtrl = TextEditingController(text: existing?.allergies ?? '');
    final emergencyCtrl = TextEditingController(text: existing?.emergencyContact ?? '');
    String selectedGender = existing?.gender ?? 'Nam';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        existing == null ? Icons.person_add_rounded : Icons.edit_rounded,
                        color: const Color(0xFF0EA5E9), size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      existing == null ? 'Thêm hồ sơ mới' : 'Chỉnh sửa hồ sơ',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20, right: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.of(ctx).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formField('Họ và tên *', nameCtrl, Icons.person_outline_rounded, 'Nhập họ và tên đầy đủ'),
                      const SizedBox(height: 14),
                      _formField('Ngày sinh *', dobCtrl, Icons.cake_outlined, 'dd/mm/yyyy'),
                      const SizedBox(height: 14),
                      // Gender selector
                      const Text('Giới tính *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Nam', 'Nữ'].map((g) {
                          bool sel = selectedGender == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedGender = g),
                              child: Container(
                                margin: EdgeInsets.only(right: g == 'Nam' ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFF0EA5E9) : Colors.white,
                                  border: Border.all(
                                    color: sel ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(g,
                                    style: TextStyle(
                                        color: sel ? Colors.white : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      _formField('Số điện thoại', phoneCtrl, Icons.phone_outlined, '0901 234 567', keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      _formField('Địa chỉ', addressCtrl, Icons.location_on_outlined, 'Số nhà, đường, quận, tỉnh/thành'),
                      const SizedBox(height: 14),
                      _formField('Nhóm máu', bloodCtrl, Icons.bloodtype_outlined, 'VD: O+, A+, B-, AB+'),
                      const SizedBox(height: 14),
                      _formField('Bệnh nền', diseasesCtrl, Icons.medical_services_outlined, 'VD: Huyết áp, tiểu đường...', maxLines: 2),
                      const SizedBox(height: 14),
                      _formField('Dị ứng thuốc', allergiesCtrl, Icons.warning_amber_outlined, 'VD: Penicillin, Aspirin...'),
                      const SizedBox(height: 14),
                      _formField('Liên hệ khẩn cấp', emergencyCtrl, Icons.contact_phone_outlined, 'Tên - Số điện thoại'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty || dobCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFFDC2626),
                                  content: Text('Vui lòng nhập họ tên và ngày sinh!'),
                                ),
                              );
                              return;
                            }

                            final profile = ElderlyProfile(
                              name: nameCtrl.text,
                              dob: dobCtrl.text,
                              gender: selectedGender,
                              phone: phoneCtrl.text,
                              address: addressCtrl.text,
                              bloodType: bloodCtrl.text,
                              diseases: diseasesCtrl.text,
                              allergies: allergiesCtrl.text,
                              emergencyContact: emergencyCtrl.text,
                            );

                            if (editIndex != null) {
                              globalState.updateProfile(editIndex, profile);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF16A34A),
                                  content: Text('Đã cập nhật hồ sơ thành công!'),
                                ),
                              );
                            } else {
                              // Call backend API
                              final res = await ApiService.createElderly(
                                fullname: profile.name,
                                dob: profile.dob,
                                gender: profile.gender,
                                medicalNote: "${profile.diseases} - ${profile.allergies}",
                              );

                              if (res['success'] == true) {
                                globalState.addProfile(profile);
                                Navigator.pop(ctx);
                                
                                // Show QR Code dialog
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text("Mã QR Đăng Nhập", textAlign: TextAlign.center),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("Dùng mã QR này để người cao tuổi quét và đăng nhập vào ứng dụng.", textAlign: TextAlign.center),
                                        const SizedBox(height: 20),
                                        QrImageView(
                                          data: res['qr_token'],
                                          version: QrVersions.auto,
                                          size: 200.0,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text("Đóng"),
                                      )
                                    ],
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF16A34A),
                                    content: Text('Đã thêm hồ sơ mới thành công!'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFFDC2626),
                                    content: Text(res['error'] ?? 'Lỗi tạo hồ sơ'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(existing == null ? 'Thêm hồ sơ' : 'Lưu thay đổi',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, String hint,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // Header
          Container(
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
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, globalState.activeProfile.name);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quản lý hồ sơ',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Thêm, chỉnh sửa và chuyển đổi hồ sơ người cao tuổi',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add button
                  GestureDetector(
                    onTap: () => _showAddOrEditDialog(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.08),
                        border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.4),
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded,
                              color: Color(0xFF0EA5E9), size: 22),
                          SizedBox(width: 10),
                          Text('Thêm hồ sơ người cao tuổi mới',
                              style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // List of profiles
                  ValueListenableBuilder<List<ElderlyProfile>>(
                    valueListenable: globalState.profiles,
                    builder: (context, profiles, child) {
                      return Column(
                        children: List.generate(profiles.length, (i) {
                          final p = profiles[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: p.isActive
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFFE2E8F0),
                                width: p.isActive ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: p.isActive
                                      ? const Color(0xFF0EA5E9).withOpacity(0.1)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: p.isActive
                                              ? const Color(0xFF0EA5E9)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          p.name.isNotEmpty ? p.name[0] : '?',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: p.isActive
                                                  ? Colors.white
                                                  : const Color(0xFF94A3B8)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(p.name,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1E293B))),
                                                if (p.isActive) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0EA5E9),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text('Đang theo dõi',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold)),
                                                  ),
                                                ]
                                              ],
                                            ),
                                            Text('${p.gender} · ${p.dob}',
                                                style: const TextStyle(
                                                    fontSize: 12, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Info chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _infoChip(Icons.bloodtype_outlined, 'Nhóm máu: ${p.bloodType}'),
                                      _infoChip(Icons.phone_outlined, p.phone),
                                      if (p.diseases.isNotEmpty)
                                        _infoChip(Icons.medical_services_outlined, p.diseases, isWarning: true),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // Action buttons
                                  Row(
                                    children: [
                                      if (!p.isActive)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _switchActive(i),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF0EA5E9)),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.swap_horiz_rounded,
                                                size: 16, color: Color(0xFF0EA5E9)),
                                            label: const Text('Chuyển sang',
                                                style: TextStyle(
                                                    color: Color(0xFF0EA5E9),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                      if (!p.isActive) const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showAddOrEditDialog(existing: p, editIndex: i),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFF94A3B8)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: const Icon(Icons.edit_rounded,
                                              size: 16, color: Color(0xFF475569)),
                                          label: const Text('Chỉnh sửa',
                                              style: TextStyle(
                                                  color: Color(0xFF475569),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                        ),
                                      ),
                                      if (!p.isActive) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _deleteProfile(i),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFDC2626)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 14),
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded,
                                              size: 18, color: Color(0xFFDC2626)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFFFF4E6)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: isWarning
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isWarning
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

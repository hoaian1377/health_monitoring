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
    final isElderly = ApiService.currentRole == 'elderly';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
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
    final isElderly = ApiService.currentRole == 'elderly';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isElderly ? 24 : 20)),
        title: Text(isElderly ? 'Xóa hồ sơ sức khỏe?' : 'Xóa hồ sơ?',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isElderly
            ? 'Bác có chắc muốn xóa hồ sơ "${globalState.profiles.value[index].name}" không ạ? Dữ liệu đo sức khỏe liên quan sẽ bị mất vĩnh viễn.'
            : 'Bạn có chắc muốn xóa hồ sơ "${globalState.profiles.value[index].name}"? Dữ liệu sức khỏe liên quan sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isElderly ? 'Hủy bỏ' : 'Hủy', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isElderly ? 12 : 10)),
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
            child: Text(isElderly ? 'Xác nhận xóa' : 'Xóa', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditDialog({ElderlyProfile? existing, int? editIndex}) {
    final isElderly = ApiService.currentRole == 'elderly';
    final themeColor = isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9);
    final accentBgColor = isElderly ? const Color(0xFFE6F5F4) : const Color(0xFFE0F2FE);

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isElderly ? 32 : 28)),
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
                        color: accentBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        existing == null ? Icons.person_add_rounded : Icons.edit_rounded,
                        color: themeColor, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      existing == null 
                          ? (isElderly ? 'Thêm hồ sơ mới của bác' : 'Thêm hồ sơ mới') 
                          : (isElderly ? 'Sửa hồ sơ sức khỏe' : 'Chỉnh sửa hồ sơ'),
                      style: TextStyle(
                          fontSize: isElderly ? 20 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
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
                      Text('Giới tính *',
                          style: TextStyle(fontSize: isElderly ? 14 : 13, fontWeight: FontWeight.w700, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF475569))),
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
                                  color: sel ? themeColor : Colors.white,
                                  border: Border.all(
                                    color: sel ? themeColor : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(g,
                                    style: TextStyle(
                                        color: sel ? Colors.white : const Color(0xFF64748B),
                                        fontSize: isElderly ? 15 : 14,
                                        fontWeight: FontWeight.bold)),
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
                        height: isElderly ? 54 : 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isElderly ? 24 : 20)),
                                    title: Text(isElderly ? "Mã QR Đăng Nhập Của Bác" : "Mã QR Đăng Nhập", textAlign: TextAlign.center),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(isElderly 
                                            ? "Bác hãy lưu hoặc dùng điện thoại quét mã QR này để đăng nhập nhanh nhé."
                                            : "Dùng mã QR này để người cao tuổi quét và đăng nhập vào ứng dụng.", textAlign: TextAlign.center),
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
                                        child: Text(isElderly ? "Đóng lại" : "Đóng", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
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
                          child: Text(existing == null ? (isElderly ? 'Thêm hồ sơ sức khỏe' : 'Thêm hồ sơ') : 'Lưu thay đổi',
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
    final isElderly = ApiService.currentRole == 'elderly';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isElderly ? 14 : 13, fontWeight: FontWeight.w700, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: isElderly ? 16 : 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFFCBD5E1), fontSize: isElderly ? 14 : 13),
            prefixIcon: Icon(icon, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9), size: isElderly ? 20 : 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isElderly ? 16 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isElderly ? 14 : 12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isElderly ? 14 : 12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isElderly ? 14 : 12),
              borderSide: BorderSide(color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    final headerGradient = isElderly
        ? [const Color(0xFF0F605A), const Color(0xFF1B8E85)]
        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)];

    return Scaffold(
      backgroundColor: isElderly ? const Color(0xFFF3F7FA) : const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isElderly ? 'Danh sách hồ sơ của bác' : 'Quản lý hồ sơ',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(isElderly ? 'Chuyển đổi hoặc xem thông tin hồ sơ sức khỏe' : 'Thêm, chỉnh sửa và chuyển đổi hồ sơ người cao tuổi',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
                  if (isElderly)
                    GestureDetector(
                      onTap: () => _showAddOrEditDialog(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F605A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F605A).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text('Thêm hồ sơ sức khỏe mới',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _showAddOrEditDialog(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                          border: Border.all(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
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
                              borderRadius: BorderRadius.circular(isElderly ? 24 : 20),
                              border: Border.all(
                                color: p.isActive
                                    ? (isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9))
                                    : const Color(0xFFE2E8F0),
                                width: p.isActive ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: p.isActive
                                      ? (isElderly ? const Color(0xFF0F605A).withValues(alpha: 0.1) : const Color(0xFF0EA5E9).withValues(alpha: 0.1))
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isElderly ? 18 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: isElderly ? 54 : 50,
                                        height: isElderly ? 54 : 50,
                                        decoration: BoxDecoration(
                                          color: p.isActive
                                              ? (isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9))
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          p.name.isNotEmpty ? p.name[0] : '?',
                                          style: TextStyle(
                                              fontSize: isElderly ? 22 : 20,
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
                                                Expanded(
                                                  child: Text(p.name,
                                                      style: TextStyle(
                                                          fontSize: isElderly ? 17 : 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: const Color(0xFF1E293B)),
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                                if (p.isActive) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
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
                                            const SizedBox(height: 2),
                                            Text('${p.gender} · ${p.dob}',
                                                style: TextStyle(
                                                    fontSize: isElderly ? 13 : 12, color: const Color(0xFF64748B))),
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
                                              side: BorderSide(color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9)),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: Icon(Icons.swap_horiz_rounded,
                                                size: 16, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9)),
                                            label: Text('Chuyển sang',
                                                style: TextStyle(
                                                    color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF0EA5E9),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                      if (!p.isActive) const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showAddOrEditDialog(existing: p, editIndex: i),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF94A3B8)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: Icon(Icons.edit_rounded,
                                              size: 16, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF475569)),
                                          label: Text('Chỉnh sửa',
                                              style: TextStyle(
                                                  color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
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
    final isElderly = ApiService.currentRole == 'elderly';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isElderly ? 10 : 8, vertical: isElderly ? 5 : 4),
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
              size: isElderly ? 13 : 12,
              color: isWarning
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: isElderly ? 12 : 11,
                  color: isWarning
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

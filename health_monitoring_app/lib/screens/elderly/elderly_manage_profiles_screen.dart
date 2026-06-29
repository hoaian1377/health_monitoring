import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/global_state.dart';
import '../../utils/api_service.dart';

class ElderlyManageProfilesScreen extends StatefulWidget {
  const ElderlyManageProfilesScreen({super.key});
  @override
  State<ElderlyManageProfilesScreen> createState() => _State();
}

class _State extends State<ElderlyManageProfilesScreen> {
  static const _teal = Color(0xFF0F605A);
  static const _tealLight = Color(0xFFE6F5F4);

  void _switchActive(int index) {
    globalState.switchActiveProfile(index);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _teal,
      content: Text('Đã chuyển sang hồ sơ: ${globalState.profiles.value[index].name}'),
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.pop(context, globalState.profiles.value[index].name);
    });
  }

  void _deleteProfile(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xóa hồ sơ sức khỏe?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bác có chắc muốn xóa hồ sơ "${globalState.profiles.value[index].name}" không ạ? Dữ liệu đo sức khỏe liên quan sẽ bị mất vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              globalState.deleteProfile(index);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFDC2626), content: Text('Đã xóa hồ sơ thành công')));
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEdit({ElderlyProfile? existing, int? editIndex}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final dobC = TextEditingController(text: existing?.dob ?? '');
    final phoneC = TextEditingController(text: existing?.phone ?? '');
    final addrC = TextEditingController(text: existing?.address ?? '');
    final bloodC = TextEditingController(text: existing?.bloodType ?? '');
    final disC = TextEditingController(text: existing?.diseases ?? '');
    final allC = TextEditingController(text: existing?.allergies ?? '');
    final emergC = TextEditingController(text: existing?.emergencyContact ?? '');
    String gender = existing?.gender ?? 'Nam';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _tealLight, borderRadius: BorderRadius.circular(10)),
                    child: Icon(existing == null ? Icons.person_add_rounded : Icons.edit_rounded, color: _teal, size: 20)),
                const SizedBox(width: 12),
                Text(existing == null ? 'Thêm hồ sơ mới của bác' : 'Sửa hồ sơ sức khỏe',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ]),
            ),
            const Divider(height: 24),
            Expanded(child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.of(ctx).padding.bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _formField('Họ và tên *', nameC, Icons.person_outline_rounded, 'Nhập họ và tên đầy đủ'),
                const SizedBox(height: 14),
                _formField('Ngày sinh *', dobC, Icons.cake_outlined, 'dd/mm/yyyy'),
                const SizedBox(height: 14),
                const Text('Giới tính *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _teal)),
                const SizedBox(height: 8),
                Row(children: ['Nam', 'Nữ'].map((g) => Expanded(child: GestureDetector(
                  onTap: () => setM(() => gender = g),
                  child: Container(
                    margin: EdgeInsets.only(right: g == 'Nam' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: gender == g ? _teal : Colors.white,
                      border: Border.all(color: gender == g ? _teal : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(g, style: TextStyle(color: gender == g ? Colors.white : const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ))).toList()),
                const SizedBox(height: 14),
                _formField('Số điện thoại', phoneC, Icons.phone_outlined, '0901 234 567', type: TextInputType.phone),
                const SizedBox(height: 14),
                _formField('Địa chỉ', addrC, Icons.location_on_outlined, 'Số nhà, đường, quận, tỉnh/thành'),
                const SizedBox(height: 14),
                _formField('Nhóm máu', bloodC, Icons.bloodtype_outlined, 'VD: O+, A+, B-, AB+'),
                const SizedBox(height: 14),
                _formField('Bệnh nền', disC, Icons.medical_services_outlined, 'VD: Huyết áp, tiểu đường...', lines: 2),
                const SizedBox(height: 14),
                _formField('Dị ứng thuốc', allC, Icons.warning_amber_outlined, 'VD: Penicillin, Aspirin...'),
                const SizedBox(height: 14),
                _formField('Liên hệ khẩn cấp', emergC, Icons.contact_phone_outlined, 'Tên - Số điện thoại'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    onPressed: () async {
                      if (nameC.text.isEmpty || dobC.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFDC2626), content: Text('Vui lòng nhập họ tên và ngày sinh!')));
                        return;
                      }
                      final profile = ElderlyProfile(name: nameC.text, dob: dobC.text, gender: gender, phone: phoneC.text, address: addrC.text, bloodType: bloodC.text, diseases: disC.text, allergies: allC.text, emergencyContact: emergC.text);
                      if (editIndex != null) {
                        globalState.updateProfile(editIndex, profile);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF16A34A), content: Text('Đã cập nhật hồ sơ thành công!')));
                      } else {
                        final res = await ApiService.createElderly(fullname: profile.name, dob: profile.dob, gender: profile.gender, medicalNote: '${profile.diseases} - ${profile.allergies}');
                        if (res['success'] == true) {
                          globalState.addProfile(profile);
                          Navigator.pop(ctx);
                          showDialog(context: context, builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: const Text('Mã QR Đăng Nhập Của Bác', textAlign: TextAlign.center),
                            content: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('Bác hãy lưu hoặc dùng điện thoại quét mã QR này để đăng nhập nhanh nhé.', textAlign: TextAlign.center),
                              const SizedBox(height: 20),
                              QrImageView(data: res['qr_token'], version: QrVersions.auto, size: 200.0),
                            ]),
                            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng lại', style: TextStyle(color: _teal, fontWeight: FontWeight.bold)))],
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF16A34A), content: Text('Đã thêm hồ sơ mới thành công!')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFFDC2626), content: Text(res['error'] ?? 'Lỗi tạo hồ sơ')));
                        }
                      }
                    },
                    child: Text(existing == null ? 'Thêm hồ sơ sức khỏe' : 'Lưu thay đổi',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, String hint, {TextInputType type = TextInputType.text, int lines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _teal)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, keyboardType: type, maxLines: lines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(icon, color: _teal, size: 20),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 1.5)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_teal, Color(0xFF1B8E85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context, globalState.activeProfile.name),
              child: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Danh sách hồ sơ của bác', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Chuyển đổi hoặc xem thông tin hồ sơ sức khỏe', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ])),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Add button
            GestureDetector(
              onTap: () => _showAddOrEdit(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Thêm hồ sơ sức khỏe mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<List<ElderlyProfile>>(
              valueListenable: globalState.profiles,
              builder: (context, profiles, _) => Column(
                children: List.generate(profiles.length, (i) {
                  final p = profiles[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: p.isActive ? _teal : const Color(0xFFE2E8F0), width: p.isActive ? 2 : 1),
                      boxShadow: [BoxShadow(color: p.isActive ? _teal.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(color: p.isActive ? _teal : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.center,
                            child: Text(p.name.isNotEmpty ? p.name[0] : '?',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: p.isActive ? Colors.white : const Color(0xFF94A3B8))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                              if (p.isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Đang theo dõi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            Text('${p.gender} · ${p.dob}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ])),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          _chip(Icons.bloodtype_outlined, 'Nhóm máu: ${p.bloodType}'),
                          _chip(Icons.phone_outlined, p.phone),
                          if (p.diseases.isNotEmpty) _chip(Icons.medical_services_outlined, p.diseases, warn: true),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          if (!p.isActive) ...[
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _switchActive(i),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: _teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: _teal),
                              label: const Text('Chuyển sang', style: TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 13)),
                            )),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _showAddOrEdit(existing: p, editIndex: i),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: _teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                            icon: const Icon(Icons.edit_rounded, size: 16, color: _teal),
                            label: const Text('Chỉnh sửa', style: TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 13)),
                          )),
                          if (!p.isActive) ...[
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _deleteProfile(i),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14)),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ]),
                      ]),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        )),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: warn ? const Color(0xFFFFF4E6) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: warn ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: warn ? const Color(0xFFEA580C) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

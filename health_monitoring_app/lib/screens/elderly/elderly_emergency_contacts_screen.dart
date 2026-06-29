import 'package:flutter/material.dart';

class ElderlyEmergencyContactsScreen extends StatefulWidget {
  const ElderlyEmergencyContactsScreen({super.key});
  @override
  State<ElderlyEmergencyContactsScreen> createState() => _State();
}

class _State extends State<ElderlyEmergencyContactsScreen> {
  final List<_EContact> _contacts = [
    _EContact(name: 'Nguyễn Thị Bình', phone: '0901 234 567', relation: 'Con gái'),
    _EContact(name: 'Trần Văn C', phone: '0912 345 678', relation: 'Người chăm sóc'),
  ];
  static const _nums = [
    {'num': '115', 'label': 'Cấp cứu'},
    {'num': '113', 'label': 'Công an'},
    {'num': '114', 'label': 'Cứu hỏa'},
  ];

  void _showSheet({_EContact? existing}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final phoneC = TextEditingController(text: existing?.phone ?? '');
    final relC = TextEditingController(text: existing?.relation ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).padding.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Thêm người thân khẩn cấp' : 'Sửa thông tin liên lạc',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
            const SizedBox(height: 16),
            _field(nameC, 'Họ và tên người thân', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _field(phoneC, 'Số điện thoại', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(relC, 'Mối quan hệ', Icons.family_restroom_rounded),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
                    setState(() {
                      if (existing != null) {
                        final i = _contacts.indexOf(existing);
                        _contacts[i] = _EContact(name: nameC.text.trim(), phone: phoneC.text.trim(), relation: relC.text.trim());
                      } else {
                        _contacts.add(_EContact(name: nameC.text.trim(), phone: phoneC.text.trim(), relation: relC.text.trim().isEmpty ? 'Người thân' : relC.text.trim()));
                      }
                    });
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(existing == null ? 'Thêm người thân khẩn cấp' : 'Lưu thay đổi',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF0284C7), size: 22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Danh sách khẩn cấp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Người thân sẽ nhận thông báo khi bác nhấn SOS', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ])),
            Icon(Icons.contact_phone_rounded, color: Colors.white.withValues(alpha: 0.7), size: 24),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(children: [
                    Icon(Icons.people_rounded, color: Color(0xFF0284C7), size: 20),
                    SizedBox(width: 8),
                    Text('Người thân liên lạc chính', style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (old, ni) { setState(() { if (ni > old) ni--; final c = _contacts.removeAt(old); _contacts.insert(ni, c); }); },
                  children: _contacts.asMap().entries.map((e) => _tile(e.value, e.key, e.key == _contacts.length - 1)).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('SỐ ĐIỆN THOẠI KHẨN CẤP Y TẾ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Row(children: _nums.map((e) => Expanded(child: Container(
              margin: EdgeInsets.only(right: e['num'] != '114' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5)),
              alignment: Alignment.center,
              child: Column(children: [
                Text(e['num']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC81E1E))),
                const SizedBox(height: 2),
                Text(e['label']!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D))),
              ]),
            ))).toList()),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showSheet(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 22, color: Colors.white),
              label: const Text('Thêm người thân khẩn cấp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ]),
        )),
      ]),
    );
  }

  Widget _tile(_EContact c, int idx, bool isLast) {
    final initials = c.name.split(' ').map((w) => w[0]).take(2).join('').toUpperCase();
    return Column(
      key: ValueKey(c.name + idx.toString()),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text('${c.phone} · ${c.relation}', style: const TextStyle(fontSize: 15.5, color: Color(0xFF94A3B8))),
            ])),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFF16A34A), content: Text('Đang gọi ${c.phone}...'), duration: const Duration(seconds: 2))),
              child: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 20)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSheet(existing: c),
              child: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20)),
            ),
            const SizedBox(width: 6),
            ReorderableDragStartListener(index: idx, child: const Icon(Icons.drag_handle_rounded, color: Color(0xFFCBD5E1), size: 24)),
          ]),
        ),
        if (!isLast) const Divider(height: 1, indent: 76, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _EContact {
  final String name, phone, relation;
  _EContact({required this.name, required this.phone, required this.relation});
}

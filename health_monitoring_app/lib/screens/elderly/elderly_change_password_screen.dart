import 'package:flutter/material.dart';

class ElderlyChangePasswordScreen extends StatefulWidget {
  const ElderlyChangePasswordScreen({super.key});
  @override
  State<ElderlyChangePasswordScreen> createState() => _State();
}

class _State extends State<ElderlyChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldC = TextEditingController();
  final _newC = TextEditingController();
  final _confC = TextEditingController();
  bool _showOld = false, _showNew = false, _showConf = false, _loading = false;

  @override
  void dispose() { _oldC.dispose(); _newC.dispose(); _confC.dispose(); super.dispose(); }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Color(0xFF16A34A),
      content: Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white),
        SizedBox(width: 12),
        Text('Đổi mật khẩu thành công!', style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      duration: Duration(seconds: 2),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Column(children: [
        // Header — teal gradient
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0F605A), Color(0xFF1B8E85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đổi mật khẩu của bác', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Hãy tạo mật khẩu mới để bảo vệ tài khoản', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ])),
          ]),
        ),
        // Form
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEBFDFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF0F605A), size: 20),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Mật khẩu mới của bác phải có ít nhất 6 ký tự và khác mật khẩu hiện tại.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF0F605A), fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            const SizedBox(height: 28),
            _label('Nhập mật khẩu hiện tại'),
            const SizedBox(height: 8),
            _passField(controller: _oldC, hint: 'Mật khẩu hiện tại của bác', show: _showOld,
                onToggle: () => setState(() => _showOld = !_showOld),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null),
            const SizedBox(height: 20),
            _label('Nhập mật khẩu mới'),
            const SizedBox(height: 8),
            _passField(controller: _newC, hint: 'Mật khẩu mới (tối thiểu 6 ký tự)', show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  if (v == _oldC.text) return 'Mật khẩu mới không được trùng mật khẩu cũ';
                  return null;
                }),
            const SizedBox(height: 20),
            _label('Nhập lại mật khẩu mới để xác nhận'),
            const SizedBox(height: 8),
            _passField(controller: _confC, hint: 'Xác nhận lại mật khẩu mới', show: _showConf,
                onToggle: () => setState(() => _showConf = !_showConf),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                  if (v != _newC.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                }),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F605A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu mật khẩu mới của bác', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ])),
        )),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F605A)));

  Widget _passField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0F605A), size: 22),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8), size: 22),
          onPressed: onToggle,
        ),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F605A), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Đổi mật khẩu thành công!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    final themeColor = isElderly ? const Color(0xFF0F605A) : const Color(0xFF7C3AED);
    final headerGradient = isElderly
        ? [const Color(0xFF0F605A), const Color(0xFF1B8E85)]
        : [const Color(0xFF7C3AED), const Color(0xFFA78BFA)];

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
                  onTap: () => Navigator.pop(context),
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
                      Text(isElderly ? 'Đổi mật khẩu của bác' : 'Đổi Mật Khẩu',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(isElderly ? 'Hãy tạo mật khẩu mới để bảo vệ tài khoản' : 'Bảo mật tài khoản của bạn',
                          style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isElderly ? const Color(0xFFEBFDFB) : const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isElderly ? const Color(0xFF99F6E4) : const Color(0xFFDDD6FE)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: themeColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isElderly 
                                  ? 'Mật khẩu mới của bác phải có ít nhất 6 ký tự và khác mật khẩu hiện tại.'
                                  : 'Mật khẩu mới phải có ít nhất 6 ký tự và khác mật khẩu hiện tại.',
                              style: TextStyle(
                                  fontSize: isElderly ? 14 : 13, color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF5B21B6), fontWeight: isElderly ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLabel(isElderly ? 'Nhập mật khẩu hiện tại' : 'Mật khẩu hiện tại'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _oldPassCtrl,
                      hint: 'Mật khẩu hiện tại của bác',
                      show: _showOld,
                      onToggle: () => setState(() => _showOld = !_showOld),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(isElderly ? 'Nhập mật khẩu mới' : 'Mật khẩu mới'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _newPassCtrl,
                      hint: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                      show: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                        if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                        if (v == _oldPassCtrl.text) return 'Mật khẩu mới không được trùng mật khẩu cũ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(isElderly ? 'Nhập lại mật khẩu mới để xác nhận' : 'Xác nhận mật khẩu mới'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _confirmCtrl,
                      hint: 'Xác nhận lại mật khẩu mới',
                      show: _showConfirm,
                      onToggle: () => setState(() => _showConfirm = !_showConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (v != _newPassCtrl.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: isElderly ? 56 : 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isElderly ? 18 : 16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isElderly ? 'Lưu mật khẩu mới của bác' : 'Xác nhận đổi mật khẩu',
                                style: TextStyle(
                                    fontSize: isElderly ? 17 : 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isElderly = ApiService.currentRole == 'elderly';
    return Text(text,
        style: TextStyle(
            fontSize: isElderly ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: isElderly ? const Color(0xFF0F605A) : const Color(0xFF475569)));
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    final isElderly = ApiService.currentRole == 'elderly';
    final themeColor = isElderly ? const Color(0xFF0F605A) : const Color(0xFF7C3AED);

    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: TextStyle(fontSize: isElderly ? 16 : 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFFCBD5E1), fontSize: isElderly ? 15 : 14),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: themeColor, size: isElderly ? 22 : 20),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: const Color(0xFF94A3B8),
            size: isElderly ? 22 : 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: isElderly ? 18 : 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
          borderSide:
              BorderSide(color: themeColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isElderly ? 16 : 14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'elderly'; // 'elderly' or 'caregiver'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('Vui lòng đồng ý với Điều khoản sử dụng dịch vụ.'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF16A34A),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng ký thành công!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tài khoản của bác với vai trò là ${
                        _selectedRole == 'elderly' ? 'Người cao tuổi' : 'Người chăm sóc'
                      } đã được khởi tạo thành công.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Go back to login screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đăng nhập ngay',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Art
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.06),
              ),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Đăng ký tài khoản',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Hãy điền các thông tin để kết nối chăm sóc sức khỏe',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),

                        // Signup Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role selector label
                                const Text(
                                  'Tôi muốn đăng ký làm:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Customized Role Selection Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRoleCard(
                                        role: 'elderly',
                                        icon: Icons.elderly_rounded,
                                        label: 'Người lớn tuổi',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildRoleCard(
                                        role: 'caregiver',
                                        icon: Icons.badge_rounded,
                                        label: 'Người chăm sóc',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Name Input
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.text,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Họ và tên',
                                    hintText: 'Nhập họ và tên đầy đủ',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Phone Input
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Số điện thoại',
                                    hintText: 'Nhập số điện thoại',
                                    icon: Icons.phone_iphone_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập số điện thoại';
                                    }
                                    if (value.length < 9) {
                                      return 'Số điện thoại phải từ 9-11 số';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Mật khẩu',
                                    hintText: 'Nhập mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải từ 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password Input
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    hintText: 'Nhập lại mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Mật khẩu nhập lại không khớp';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Agree to terms
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _agreeTerms,
                                        activeColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                        onChanged: (val) {
                                          setState(() {
                                            _agreeTerms = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Tôi đồng ý với các Điều khoản dịch vụ và Chính sách bảo mật thông tin y tế của CareLink.',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Signup submit button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Đăng ký',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bác đã có tài khoản? ',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Đăng nhập ngay',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF3FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

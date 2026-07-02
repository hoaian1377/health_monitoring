import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/api_service.dart';

class AddElderlyScreen extends StatefulWidget {
  const AddElderlyScreen({super.key});

  @override
  State<AddElderlyScreen> createState() => _AddElderlyScreenState();
}

class _AddElderlyScreenState extends State<AddElderlyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameCtrl = TextEditingController();
  final _medicalNoteCtrl = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isLoading = false;

  // After creation
  String? _createdQrToken;
  String? _createdName;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void dispose() {
    _fullnameCtrl.dispose();
    _medicalNoteCtrl.dispose();
    super.dispose();
  }

  String get _dobText {
    if (_selectedDob == null) return 'Chọn ngày sinh';
    return '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 65),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 40),
      helpText: 'Chọn ngày sinh',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    if (_fullnameCtrl.text.trim().isEmpty) {
      _showError('Vui lòng nhập họ và tên');
      return;
    }
    if (_selectedDob == null) {
      _showError('Vui lòng chọn ngày sinh');
      return;
    }
    if (_selectedGender == null) {
      _showError('Vui lòng chọn giới tính');
      return;
    }

    setState(() => _isLoading = true);
    final dob = _dobText;
    final result = await ApiService.createElderly(
      fullname: _fullnameCtrl.text.trim(),
      dob: dob,
      gender: _selectedGender!,
      medicalNote: _medicalNoteCtrl.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _createdQrToken = result['qr_token'] as String?;
        _createdName = _fullnameCtrl.text.trim();
      });
      // Tự động lưu ảnh QR sau khi tạo hồ sơ thành công
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) await _saveQrImage();
      });
    } else {
      _showError(result['error'] ?? 'Có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _createdQrToken = null;
      _createdName = null;
      _fullnameCtrl.clear();
      _medicalNoteCtrl.clear();
      _selectedDob = null;
      _selectedGender = null;
    });
  }

  Future<void> _saveQrImage() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu ảnh QR chỉ hỗ trợ trên thiết bị di động.')),
        );
      }
      return;
    }
    if (Platform.isAndroid) {
      final statuses = await [Permission.storage, Permission.photos].request();
      final ok = (statuses[Permission.storage]?.isGranted ?? false) ||
          (statuses[Permission.photos]?.isGranted ?? false);
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền lưu ảnh bị từ chối.')),
          );
        }
        return;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền ảnh bị từ chối.')),
          );
        }
        return;
      }
    }
    try {
      final boundary = _qrKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw Exception('Không thể tạo ảnh từ QR');
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Không lấy được dữ liệu ảnh');
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(byteData.buffer.asUint8List()),
        name: 'qr_ho_so_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );
      if (!mounted) return;
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: const Text('✓ Đã lưu ảnh QR vào thư viện ảnh!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu ảnh QR không thành công.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu ảnh QR: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x507C3AED),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm người cao tuổi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tạo hồ sơ & sinh mã QR đăng nhập',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress indicator
                if (_createdQrToken == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        _StepDot(number: '1', label: 'Nhập thông tin', active: true),
                        _StepLine(),
                        _StepDot(number: '2', label: 'Tạo hồ sơ', active: false),
                        _StepLine(),
                        _StepDot(number: '3', label: 'Nhận QR', active: false),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        _StepDot(number: '✓', label: 'Nhập thông tin', active: true, done: true),
                        _StepLine(),
                        _StepDot(number: '✓', label: 'Tạo hồ sơ', active: true, done: true),
                        _StepLine(),
                        _StepDot(number: '3', label: 'Nhận QR', active: true),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _createdQrToken != null
                ? _buildQrView()
                : _buildForm(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FORM VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Họ và tên ───────────────────────────────────────────────────
          _buildSection(
            title: 'Họ và tên *',
            child: _buildTextField(
              controller: _fullnameCtrl,
              hint: 'Ví dụ: Nguyễn Văn An',
              icon: Icons.badge_rounded,
              capitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 16),

          // ── Ngày sinh ───────────────────────────────────────────────────
          _buildSection(
            title: 'Ngày sinh *',
            child: GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedDob != null
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFE2E8F0),
                    width: _selectedDob != null ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cake_rounded,
                          color: Color(0xFF7C3AED), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dobText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _selectedDob != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedDob != null
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: Color(0xFF7C3AED)),
                          SizedBox(width: 4),
                          Text(
                            'Chọn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Giới tính ───────────────────────────────────────────────────
          _buildSection(
            title: 'Giới tính *',
            child: Row(
              children: [
                Expanded(
                  child: _GenderTile(
                    label: 'Nam',
                    icon: Icons.male_rounded,
                    isSelected: _selectedGender == 'Nam',
                    onTap: () => setState(() => _selectedGender = 'Nam'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderTile(
                    label: 'Nữ',
                    icon: Icons.female_rounded,
                    isSelected: _selectedGender == 'Nữ',
                    onTap: () => setState(() => _selectedGender = 'Nữ'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Ghi chú y tế ────────────────────────────────────────────────
          _buildSection(
            title: 'Ghi chú y tế (tuỳ chọn)',
            child: _buildTextField(
              controller: _medicalNoteCtrl,
              hint: 'Ví dụ: Tiểu đường, huyết áp cao, dị ứng thuốc...',
              icon: Icons.medical_information_rounded,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                shadowColor: const Color(0x507C3AED),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Tạo hồ sơ & Sinh mã QR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  QR VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQrView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tạo hồ sơ thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _createdName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF7C3AED), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cho người cao tuổi quét mã QR bên dưới bằng ứng dụng để đăng nhập vào tài khoản.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D28D9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Image
                RepaintBoundary(
                  key: _qrKey,
                  child: QrImageView(
                    data: _createdQrToken!,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF7C3AED),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Token preview
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.key_rounded,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        _createdQrToken!.length > 20
                            ? '${_createdQrToken!.substring(0, 20)}...'
                            : _createdQrToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C3AED),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Copy token
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF7C3AED)),
              foregroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _createdQrToken!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('✓ Đã sao chép mã token vào clipboard'),
                  backgroundColor: const Color(0xFF7C3AED),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text(
              'Sao chép mã token',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          // Save QR Image button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF16A34A)),
              foregroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _saveQrImage,
            icon: const Icon(Icons.save_alt_rounded, size: 16),
            label: const Text(
              'Lưu ảnh QR vào máy',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // Add another
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _resetForm,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text(
                'Thêm người cao tuổi khác',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Quay lại',
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: capitalization,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
            ),
          ),
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
            borderSide:
                const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Gender tile ────────────────────────────────────────────────────────────

class _GenderTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              done ? '✓' : number,
              style: TextStyle(
                fontSize: done ? 13 : 12,
                fontWeight: FontWeight.bold,
                color: active
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1.5,
      color: Colors.white.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 18),
    );
  }
}

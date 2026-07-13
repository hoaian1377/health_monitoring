import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/api_service.dart';
import 'add_elderly_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ELDERLY LIST SCREEN — Danh sách người cao tuổi
// ═══════════════════════════════════════════════════════════════════════════════
class ElderlyListScreen extends StatefulWidget {
  const ElderlyListScreen({super.key});

  @override
  State<ElderlyListScreen> createState() => _ElderlyListScreenState();
}

class _ElderlyListScreenState extends State<ElderlyListScreen> {
  List<Map<String, dynamic>> _elderlyList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService.getElderlyList();
    if (!mounted) return;
    if (result['success'] == true) {
      final raw = result['elderly_list'] as List<dynamic>;
      setState(() {
        _elderlyList = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _openDetail(Map<String, dynamic> elderly) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ElderlyDetailScreen(elderly: elderly),
      ),
    );
    if (updated == true) _loadList();
  }

  void _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddElderlyScreen()),
    );
    if (added == true) _loadList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
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
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Người cao tuổi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Danh sách hồ sơ đang quản lý',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    GestureDetector(
                      onTap: _loadList,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_rounded,
                      label: '${_elderlyList.length} người',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.verified_rounded,
                      label: 'Đang theo dõi',
                      color: const Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED)))
                : _error != null
                    ? _buildErrorView()
                    : _elderlyList.isEmpty
                        ? _buildEmptyView()
                        : _buildList(),
          ),
        ],
      ),

      // FAB - Thêm mới
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Thêm mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: _loadList,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _elderlyList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final e = _elderlyList[i];
          return _ElderlyCard(
            elderly: e,
            onTap: () => _openDetail(e),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 52, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có hồ sơ nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn nút bên dưới để thêm người\ncao tuổi đầu tiên',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _openAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Thêm người cao tuổi',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Có lỗi xảy ra',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadList,
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED))),
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF7C3AED)),
            label: const Text('Thử lại',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
}

// ─── Elderly Card ─────────────────────────────────────────────────────────────
class _ElderlyCard extends StatelessWidget {
  final Map<String, dynamic> elderly;
  final VoidCallback onTap;
  const _ElderlyCard({required this.elderly, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = elderly['fullname'] ?? '';
    final gender = elderly['gender'] ?? '';
    final dob = elderly['dob'] ?? '';
    final medNote = elderly['medical_note'] ?? '';
    final avatarText = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '??';
    final isNam = gender == 'Nam';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isNam
                        ? [const Color(0xFF6366F1), const Color(0xFF818CF8)]
                        : [const Color(0xFFEC4899), const Color(0xFFF9A8D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isNam ? Icons.male_rounded : Icons.female_rounded,
                          size: 14,
                          color: isNam
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gender,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        if (dob.isNotEmpty) ...[
                          const Text(' · ',
                              style: TextStyle(color: Color(0xFFCBD5E1))),
                          const Icon(Icons.cake_outlined,
                              size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            _formatDob(dob),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                    if (medNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.medical_information_outlined,
                              size: 13, color: Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              medNote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFEA580C)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // QR badge + arrow
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        size: 18, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDob(String dob) {
    // dob from server: yyyy-MM-dd
    try {
      final parts = dob.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dob;
  }
}

// ─── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ELDERLY DETAIL SCREEN — Xem chi tiết + Sửa + QR
// ═══════════════════════════════════════════════════════════════════════════════
class ElderlyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> elderly;
  const ElderlyDetailScreen({super.key, required this.elderly});

  @override
  State<ElderlyDetailScreen> createState() => _ElderlyDetailScreenState();
}

class _ElderlyDetailScreenState extends State<ElderlyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey _qrKey = GlobalKey();

  // Edit state
  bool _isEditing = false;
  late TextEditingController _fullnameCtrl;
  late TextEditingController _medNoteCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fullnameCtrl =
        TextEditingController(text: widget.elderly['fullname'] ?? '');
    _medNoteCtrl =
        TextEditingController(text: widget.elderly['medical_note'] ?? '');
    _usernameCtrl = TextEditingController(text: widget.elderly['username'] ?? '');
    _passwordCtrl = TextEditingController();
    _selectedGender = widget.elderly['gender'];
    // parse dob yyyy-MM-dd
    final dobStr = widget.elderly['dob'] as String?;
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        final parts = dobStr.split('-');
        if (parts.length == 3) {
          _selectedDob = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullnameCtrl.dispose();
    _medNoteCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String get _dobDisplay {
    if (_selectedDob == null) return 'Chưa cập nhật';
    return '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}';
  }

  String get _dobForApi {
    if (_selectedDob == null) return '';
    return '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 65),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 40),
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

  Future<void> _save() async {
    if (_fullnameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ và tên'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final result = await ApiService.updateElderly(
      elderlyId: widget.elderly['id'] as int,
      fullname: _fullnameCtrl.text.trim(),
      dob: _dobForApi,
      gender: _selectedGender ?? '',
      medicalNote: _medNoteCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Đã cập nhật thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Signal the list to refresh
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Cập nhật thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      final result = await ImageGallerySaverPlus.saveImage(
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
    final name = _fullnameCtrl.text.isNotEmpty
        ? _fullnameCtrl.text
        : (widget.elderly['fullname'] ?? '');
    final avatarText = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '??';
    final isNam = (_selectedGender ?? '') == 'Nam';
    final qrToken = widget.elderly['qr_token'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
            child: Column(
              children: [
                // Top row
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
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Chi tiết hồ sơ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!_isEditing)
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Sửa',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isNam
                          ? [
                              const Color(0xFF6366F1),
                              const Color(0xFF818CF8)
                            ]
                          : [
                              const Color(0xFFEC4899),
                              const Color(0xFFF9A8D4)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEditing ? 'Đang chỉnh sửa...' : 'Người cao tuổi',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Thông tin'),
                    Tab(icon: Icon(Icons.qr_code_rounded, size: 18), text: 'Mã QR'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tabs body ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Thông tin / Sửa
                _buildInfoTab(),
                // Tab 2: QR code
                _buildQrTab(qrToken, name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Thông tin ────────────────────────────────────────────────────
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isEditing) _buildEditBanner(),
          const SizedBox(height: 4),
          // Card thông tin
          _buildInfoCard(),
          const SizedBox(height: 16),
          if (_isEditing) _buildSaveButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEditBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded,
              color: Color(0xFFD97706), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang chỉnh sửa — Nhấn Lưu để cập nhật hoặc Hủy để thoát',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    const purple = Color(0xFF7C3AED);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isEditing
            ? Border.all(color: purple.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: purple, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin cơ bản',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Có thể sửa',
                        style: TextStyle(
                            fontSize: 10,
                            color: purple,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Họ tên
          _isEditing
              ? _editFieldRow(
                  icon: Icons.badge_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  label: 'Họ và tên',
                  controller: _fullnameCtrl,
                  hint: 'Nhập họ và tên',
                )
              : _infoRowView(
                  Icons.badge_rounded,
                  const Color(0xFFF3E8FF),
                  purple,
                  'Họ và tên',
                  widget.elderly['fullname'] ?? ''),
          const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),

          // Ngày sinh
          _isEditing
              ? GestureDetector(
                  onTap: _pickDob,
                  child: _dobEditRow(),
                )
              : _infoRowView(
                  Icons.cake_rounded,
                  const Color(0xFFFFF4E6),
                  const Color(0xFFEA580C),
                  'Ngày sinh',
                  _dobDisplay),
          const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),

          // Giới tính
          _isEditing
              ? _genderEditRow()
              : _infoRowView(
                  Icons.wc_rounded,
                  const Color(0xFFE6FBF3),
                  const Color(0xFF16A34A),
                  'Giới tính',
                  _selectedGender ?? 'Chưa cập nhật'),
          const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),

          // Ghi chú y tế
          _isEditing
              ? _editFieldRow(
                  icon: Icons.medical_information_rounded,
                  iconBg: const Color(0xFFFFF0E6),
                  label: 'Ghi chú y tế',
                  controller: _medNoteCtrl,
                  hint: 'Tiểu đường, huyết áp...',
                  maxLines: 3,
                )
              : _infoRowView(
                  Icons.medical_information_rounded,
                  const Color(0xFFFFF0E6),
                  const Color(0xFFEA580C),
                  'Ghi chú y tế',
                  widget.elderly['medical_note']?.isNotEmpty == true
                      ? widget.elderly['medical_note']
                      : 'Chưa có ghi chú'),
          const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),

          // Tên đăng nhập
          _isEditing
              ? (widget.elderly['username']?.isNotEmpty == true
                  ? _infoRowView(
                      Icons.account_circle_rounded,
                      const Color(0xFFE0E7FF),
                      const Color(0xFF4F46E5),
                      'Tên đăng nhập',
                      widget.elderly['username'],
                    )
                  : _editFieldRow(
                      icon: Icons.account_circle_rounded,
                      iconBg: const Color(0xFFE0E7FF),
                      label: 'Tên đăng nhập',
                      controller: _usernameCtrl,
                      hint: 'Nhập tên đăng nhập',
                    ))
              : _infoRowView(
                  Icons.account_circle_rounded,
                  const Color(0xFFE0E7FF),
                  const Color(0xFF4F46E5),
                  'Tên đăng nhập',
                  widget.elderly['username']?.isNotEmpty == true
                      ? widget.elderly['username']
                      : 'Chưa có tên đăng nhập'),
          const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),

          // Đổi mật khẩu
          if (_isEditing)
            _editFieldRow(
              icon: Icons.lock_outline_rounded,
              iconBg: const Color(0xFFFEE2E2),
              label: 'Đổi mật khẩu mới',
              controller: _passwordCtrl,
              hint: 'Bỏ trống nếu không muốn đổi',
            )
          else
            _infoRowView(
                Icons.lock_rounded,
                const Color(0xFFFEE2E2),
                const Color(0xFFDC2626),
                'Mật khẩu',
                'Đã thiết lập (Bảo mật)'),
        ],
      ),
    );
  }

  Widget _buildSaveButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => setState(() => _isEditing = false),
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFF64748B), size: 18),
            label: const Text('Hủy',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 18),
            label:
                Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── Tab 2: QR ───────────────────────────────────────────────────────────
  Widget _buildQrTab(String qrToken, String name) {
    if (qrToken.isEmpty) {
      return const Center(
        child: Text('Không có mã QR', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                    'Người cao tuổi quét mã QR này bằng ứng dụng để đăng nhập vào tài khoản.',
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
          // QR
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    child: QrImageView(
                      data: qrToken,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
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
                ),
                const SizedBox(height: 16),
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
                        qrToken.length > 22
                            ? '${qrToken.substring(0, 22)}...'
                            : qrToken,
                        style: const TextStyle(
                          fontSize: 11,
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
          // Copy button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                foregroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrToken));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✓ Đã sao chép mã QR token'),
                    backgroundColor: const Color(0xFF7C3AED),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Sao chép mã token',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          // Save QR Image button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF16A34A)),
                foregroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveQrImage,
              icon: const Icon(Icons.save_alt_rounded, size: 16),
              label: const Text('Lưu ảnh QR vào máy',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _infoRowView(
      IconData icon, Color bg, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value.contains('Chưa')
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: const Color(0xFFCBD5E1), size: 18),
        ],
      ),
    );
  }

  Widget _editFieldRow({
    required IconData icon,
    required Color iconBg,
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child:
                Icon(icon, color: const Color(0xFF7C3AED), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 0),
                    border: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Color(0xFF7C3AED), width: 1.5),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dobEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.cake_rounded,
                color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ngày sinh',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  _dobDisplay,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedDob != null
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFFEA580C)),
                SizedBox(width: 4),
                Text('Chọn',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEA580C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFE6FBF3),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.wc_rounded,
                color: Color(0xFF16A34A), size: 18),
          ),
          const SizedBox(width: 14),
          const Text('Giới tính',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          _genderChip('Nam', Icons.male_rounded),
          const SizedBox(width: 8),
          _genderChip('Nữ', Icons.female_rounded),
        ],
      ),
    );
  }

  Widget _genderChip(String label, IconData icon) {
    final selected = _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C3AED)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

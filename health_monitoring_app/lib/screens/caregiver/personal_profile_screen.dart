import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  bool _isEditing = false;

  late TextEditingController _fullnameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  DateTime? _selectedDob;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fullnameCtrl = TextEditingController(text: ApiService.currentFullname);
    _phoneCtrl = TextEditingController(text: ApiService.currentPhone);
    _emailCtrl = TextEditingController(text: ApiService.currentEmail);
    // Parse dob if available
    if (ApiService.currentDob.isNotEmpty) {
      try {
        final parts = ApiService.currentDob.split('-');
        if (parts.length == 3) {
          _selectedDob = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }
    _selectedGender =
        ApiService.currentGender.isNotEmpty ? ApiService.currentGender : null;
  }

  @override
  void dispose() {
    _fullnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _cancelEdit() {
    // Restore old values
    _fullnameCtrl.text = ApiService.currentFullname;
    _phoneCtrl.text = ApiService.currentPhone;
    _emailCtrl.text = ApiService.currentEmail;
    setState(() => _isEditing = false);
  }

  void _saveChanges() {
    // Save to ApiService static fields
    ApiService.currentFullname = _fullnameCtrl.text.trim();
    ApiService.currentPhone = _phoneCtrl.text.trim();
    ApiService.currentEmail = _emailCtrl.text.trim();
    if (_selectedGender != null) {
      ApiService.currentGender = _selectedGender!;
    }
    if (_selectedDob != null) {
      ApiService.currentDob =
          '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
    }
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Đã lưu thành công ✓',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 30),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10),
      helpText: 'Chọn ngày sinh',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0EA5E9),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF0EA5E9);
    const gradientColors = [Color(0xFF0284C7), Color(0xFF38BDF8)];

    final displayName = _fullnameCtrl.text.isNotEmpty
        ? _fullnameCtrl.text
        : ApiService.currentUsername;
    final avatarText = displayName.isNotEmpty
        ? displayName
            .substring(0, displayName.length >= 2 ? 2 : 1)
            .toUpperCase()
        : 'ND';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x330EA5E9),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            child: Column(
              children: [
                // Top row: back + title + edit button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isEditing) {
                          _cancelEdit();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hồ sơ cá nhân',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isEditing)
                      // Cancel button
                      GestureDetector(
                        onTap: _cancelEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Edit / Save button
                    GestureDetector(
                      onTap: _toggleEdit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isEditing
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              color: _isEditing ? themeColor : Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isEditing ? 'Lưu' : 'Sửa',
                              style: TextStyle(
                                color: _isEditing ? themeColor : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar + name
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _isEditing ? 'Đang chỉnh sửa...' : 'Đã xác minh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Edit mode banner ────────────────────────────────────────────────
          if (_isEditing)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFFBEB),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Đang ở chế độ chỉnh sửa — nhấn Lưu để cập nhật',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── Scrollable content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card: Thông tin cơ bản
                  _buildCard(
                    title: 'Thông tin cơ bản',
                    icon: Icons.person_rounded,
                    iconColor: themeColor,
                    children: [
                      // Họ và tên
                      _isEditing
                          ? _editField(
                              icon: Icons.badge_rounded,
                              iconBg: const Color(0xFFEBF3FF),
                              iconColor: themeColor,
                              label: 'Họ và tên',
                              controller: _fullnameCtrl,
                              hint: 'Nhập họ và tên',
                            )
                          : _infoRow(
                              Icons.person_outline_rounded,
                              const Color(0xFFEBF3FF),
                              themeColor,
                              'Họ và tên',
                              ApiService.currentFullname.isNotEmpty
                                  ? ApiService.currentFullname
                                  : 'Chưa cập nhật',
                            ),
                      _divider(),

                      // Ngày sinh
                      _isEditing
                          ? _editDateRow(themeColor)
                          : _infoRow(
                              Icons.cake_outlined,
                              const Color(0xFFFFF4E6),
                              const Color(0xFFEA580C),
                              'Ngày sinh',
                              _selectedDob != null
                                  ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                                  : (ApiService.currentDob.isNotEmpty
                                      ? ApiService.currentDob
                                      : 'Chưa cập nhật'),
                            ),
                      _divider(),

                      // Giới tính
                      _isEditing
                          ? _editGenderRow(themeColor)
                          : _infoRow(
                              Icons.male_rounded,
                              const Color(0xFFE6FBF3),
                              const Color(0xFF16A34A),
                              'Giới tính',
                              ApiService.currentGender.isNotEmpty
                                  ? ApiService.currentGender
                                  : 'Chưa cập nhật',
                            ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card: Liên hệ
                  _buildCard(
                    title: 'Liên hệ',
                    icon: Icons.contact_mail_rounded,
                    iconColor: const Color(0xFF16A34A),
                    children: [
                      // Số điện thoại
                      _isEditing
                          ? _editField(
                              icon: Icons.phone_outlined,
                              iconBg: const Color(0xFFE6FBF3),
                              iconColor: const Color(0xFF16A34A),
                              label: 'Số điện thoại',
                              controller: _phoneCtrl,
                              hint: 'Nhập số điện thoại',
                              keyboardType: TextInputType.phone,
                            )
                          : _infoRow(
                              Icons.phone_outlined,
                              const Color(0xFFE6FBF3),
                              const Color(0xFF16A34A),
                              'Số điện thoại',
                              ApiService.currentPhone.isNotEmpty
                                  ? ApiService.currentPhone
                                  : 'Chưa cập nhật',
                            ),
                      _divider(),

                      // Email
                      _isEditing
                          ? _editField(
                              icon: Icons.email_outlined,
                              iconBg: const Color(0xFFEBF3FF),
                              iconColor: themeColor,
                              label: 'Email liên hệ',
                              controller: _emailCtrl,
                              hint: 'Nhập địa chỉ email',
                              keyboardType: TextInputType.emailAddress,
                            )
                          : _infoRow(
                              Icons.email_outlined,
                              const Color(0xFFEBF3FF),
                              themeColor,
                              'Email liên hệ',
                              ApiService.currentEmail.isNotEmpty
                                  ? ApiService.currentEmail
                                  : 'Chưa cập nhật',
                            ),
                      _divider(),

                      // Username (readonly always)
                      _infoRow(
                        Icons.credit_card_rounded,
                        const Color(0xFFFFF4E6),
                        const Color(0xFFEA580C),
                        'Tên đăng nhập',
                        ApiService.currentUsername,
                        isEditable: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card: Vai trò & liên kết gia đình
                  _buildCard(
                    title: 'Vai trò & liên kết gia đình',
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFFEA580C),
                    children: [
                      Builder(builder: (context) {
                        final name = ApiService.currentFullname.isNotEmpty
                            ? ApiService.currentFullname
                            : ApiService.currentUsername;
                        final roleText =
                            ApiService.currentRole == 'admin'
                                ? 'Quản trị viên'
                                : 'Người chăm sóc';
                        return _roleRow(
                          color: themeColor,
                          name: name,
                          role: roleText,
                          badgeText: 'Đang dùng',
                          badgeColor: const Color(0xFF16A34A),
                        );
                      }),
                      _divider(),
                      _roleRow(
                        color: const Color(0xFF0D9488),
                        name: 'Nguyễn Thị Bình',
                        role: 'Con gái',
                        badgeText: 'Đã kết nối',
                        badgeColor: const Color(0xFF0EA5E9),
                      ),
                      _divider(),
                      _roleRow(
                        color: const Color(0xFFD97706),
                        name: 'Trần Văn C',
                        role: 'Người chăm sóc',
                        badgeText: 'Chờ xác nhận',
                        badgeColor: const Color(0xFFD97706),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Save / Cancel buttons (visible when editing)
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFCBD5E1)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _cancelEdit,
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF64748B), size: 18),
                            label: const Text(
                              'Hủy',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: _saveChanges,
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 18),
                            label: const Text(
                              'Lưu thay đổi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Static save button when not editing — triggers edit mode
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Chỉnh sửa thông tin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit field (text) ────────────────────────────────────────────────────
  Widget _editField({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 0),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: iconColor, width: 1.5),
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
          const SizedBox(width: 8),
          Icon(Icons.edit_rounded, color: iconColor, size: 14),
        ],
      ),
    );
  }

  // ── Edit date row ────────────────────────────────────────────────────────
  Widget _editDateRow(Color themeColor) {
    final dobText = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
        : 'Chọn ngày sinh';

    return GestureDetector(
      onTap: _pickDob,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cake_outlined,
                  color: Color(0xFFEA580C), size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ngày sinh',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dobText,
                    style: TextStyle(
                      fontSize: 15.5,
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
                  Text(
                    'Chọn',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEA580C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit gender row ──────────────────────────────────────────────────────
  Widget _editGenderRow(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FBF3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.wc_rounded,
                color: Color(0xFF16A34A), size: 17),
          ),
          const SizedBox(width: 12),
          const Text(
            'Giới tính',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Nam button
          _genderChip('Nam', Icons.male_rounded, themeColor),
          const SizedBox(width: 8),
          // Nữ button
          _genderChip('Nữ', Icons.female_rounded, themeColor),
        ],
      ),
    );
  }

  Widget _genderChip(String label, IconData icon, Color themeColor) {
    final selected = _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? themeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? themeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: selected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card wrapper ──────────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isEditing
            ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: _isEditing ? 14 : 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Có thể sửa',
                      style: TextStyle(
                        fontSize: 10,
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  // ── Info row (view mode) ─────────────────────────────────────────────────
  Widget _infoRow(
    IconData icon,
    Color bg,
    Color iconColor,
    String label,
    String value, {
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: value == 'Chưa cập nhật'
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          if (!isEditable)
            const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFCBD5E1), size: 16)
          else
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 18),
        ],
      ),
    );
  }

  // ── Role row ─────────────────────────────────────────────────────────────
  Widget _roleRow({
    required Color color,
    required String name,
    required String role,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 62, color: Color(0xFFF1F5F9));
}

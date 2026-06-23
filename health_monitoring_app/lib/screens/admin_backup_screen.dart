import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/api_service.dart';

class AdminBackupScreen extends StatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  State<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends State<AdminBackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Backup state ────────────────────────────────────────────────────────────
  bool _isBackingUp = false;
  Map<String, dynamic>? _lastBackupData;
  String? _lastBackupTime;

  // ── Restore state ───────────────────────────────────────────────────────────
  bool _isRestoring = false;
  final _restoreController = TextEditingController();
  bool _restoreJsonValid = false;
  Map<String, dynamic>? _parsedRestoreData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _restoreController.dispose();
    super.dispose();
  }

  // ── UC-6: Thực hiện sao lưu ─────────────────────────────────────────────────
  Future<void> _doBackup() async {
    setState(() => _isBackingUp = true);

    final res = await ApiService.backupDatabase();

    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (res['success'] == true) {
      final payload = res['data'] as Map<String, dynamic>;
      final backupPayload = payload['data'] as Map<String, dynamic>? ?? payload;
      setState(() {
        _lastBackupData = backupPayload;
        _lastBackupTime = _formatNow();
      });
      _showSuccessSnack('Sao lưu thành công! Dữ liệu đã sẵn sàng để tải xuống.');
    } else {
      _showErrorSnack(res['error'] ?? 'Sao lưu thất bại.');
    }
  }

  // ── Copy JSON to clipboard ───────────────────────────────────────────────────
  Future<void> _copyJsonToClipboard() async {
    if (_lastBackupData == null) return;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(_lastBackupData);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    _showSuccessSnack('Đã sao chép JSON vào clipboard!');
  }

  // ── UC-7: Validate JSON nhập vào ────────────────────────────────────────────
  void _validateRestoreJson(String value) {
    try {
      final parsed = jsonDecode(value) as Map<String, dynamic>;
      final hasTables = parsed.containsKey('tables');
      setState(() {
        _restoreJsonValid = hasTables;
        _parsedRestoreData = hasTables ? parsed : null;
      });
    } catch (_) {
      setState(() {
        _restoreJsonValid = false;
        _parsedRestoreData = null;
      });
    }
  }

  // ── Paste from clipboard ─────────────────────────────────────────────────────
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _restoreController.text = data!.text!;
      _validateRestoreJson(data.text!);
    }
  }

  // ── UC-7: Xác nhận và phục hồi ──────────────────────────────────────────────
  Future<void> _doRestore() async {
    if (_parsedRestoreData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restore_rounded,
                    color: Color(0xFFDC2626), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác nhận phục hồi?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Thao tác này sẽ XÓA toàn bộ dữ liệu hiện tại và thay thế bằng dữ liệu từ file backup. Hành động không thể hoàn tác!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Phục hồi',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    final res =
        await ApiService.restoreDatabase(backupData: _parsedRestoreData!);
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (res['success'] == true) {
      _restoreController.clear();
      setState(() {
        _parsedRestoreData = null;
        _restoreJsonValid = false;
      });
      _showSuccessSnack('Phục hồi cơ sở dữ liệu thành công!');
    } else {
      _showErrorSnack(res['error'] ?? 'Phục hồi thất bại.');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _formatNow() {
    final now = DateTime.now();
    return '${_pad(now.day)}/${_pad(now.month)}/${now.year} '
        '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF16A34A),
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFDC2626),
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBackupTab(),
                _buildRestoreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x337C3AED),
              blurRadius: 20,
              offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sao lưu & Phục hồi',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'Quản lý dữ liệu hệ thống',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storage_rounded,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.cloud_upload_rounded, size: 20),
            text: 'Sao lưu',
          ),
          Tab(
            icon: Icon(Icons.restore_rounded, size: 20),
            text: 'Phục hồi',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UC-6: TAB SAO LƯU
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3EEFF),
            title: 'Sao lưu cơ sở dữ liệu',
            body:
                'Tạo bản sao lưu toàn bộ dữ liệu hệ thống gồm: tài khoản, người chăm sóc, người cao tuổi và các liên kết. Lưu JSON vào thiết bị để dùng khi phục hồi.',
          ),
          const SizedBox(height: 16),

          // Backup button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _doBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.cloud_upload_rounded, size: 22),
              label: Text(
                _isBackingUp ? 'Đang sao lưu...' : 'Bắt đầu sao lưu',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_lastBackupData != null) ...[
            const SizedBox(height: 24),
            _buildSectionLabel('KẾT QUẢ SAO LƯU'),
            const SizedBox(height: 12),

            // Backup stats
            _buildBackupStats(),
            const SizedBox(height: 16),

            // Timestamp
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thời điểm sao lưu',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600)),
                      Text(_lastBackupTime ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copy JSON button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _copyJsonToClipboard,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.copy_rounded,
                    color: Color(0xFF7C3AED), size: 20),
                label: const Text(
                  'Sao chép JSON vào clipboard',
                  style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Preview JSON box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code_rounded,
                          color: Color(0xFFA78BFA), size: 14),
                      const SizedBox(width: 6),
                      const Text('Xem trước JSON',
                          style: TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _buildPreviewJson(),
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBackupStats() {
    final stats = _lastBackupData?['stats'] as Map<String, dynamic>? ?? {};
    final items = [
      _StatItem('Tài khoản', stats['total_accounts']?.toString() ?? '—',
          Icons.manage_accounts_rounded, const Color(0xFF0EA5E9)),
      _StatItem('Người chăm sóc', stats['total_caregivers']?.toString() ?? '—',
          Icons.person_rounded, const Color(0xFF16A34A)),
      _StatItem('Người cao tuổi', stats['total_elderlies']?.toString() ?? '—',
          Icons.elderly_rounded, const Color(0xFFEA580C)),
      _StatItem('Liên kết', stats['total_links']?.toString() ?? '—',
          Icons.link_rounded, const Color(0xFF7C3AED)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: items
          .map((s) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.count,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: s.color)),
                          Text(s.label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  String _buildPreviewJson() {
    if (_lastBackupData == null) return '';
    final stats = _lastBackupData!['stats'] ?? {};
    final time = _lastBackupData!['backup_time'] ?? _lastBackupTime ?? '';
    return '{\n'
        '  "backup_time": "$time",\n'
        '  "version": "${_lastBackupData!['version'] ?? '1.0'}",\n'
        '  "stats": {\n'
        '    "total_accounts": ${stats['total_accounts'] ?? 0},\n'
        '    "total_caregivers": ${stats['total_caregivers'] ?? 0},\n'
        '    "total_elderlies": ${stats['total_elderlies'] ?? 0},\n'
        '    "total_links": ${stats['total_links'] ?? 0}\n'
        '  },\n'
        '  "tables": { ... }\n'
        '}';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UC-7: TAB PHỤC HỒI
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRestoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning card
          _buildInfoCard(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFFF1F2),
            title: 'Cảnh báo quan trọng',
            body:
                'Phục hồi sẽ XÓA toàn bộ dữ liệu hiện tại và thay thế bằng dữ liệu từ file backup. Hãy chắc chắn bạn đã sao lưu trước khi thực hiện.',
            isWarning: true,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFEBF3FF),
            title: 'Cách phục hồi',
            body:
                '1. Vào tab "Sao lưu" và sao chép JSON.\n2. Dán vào ô bên dưới.\n3. Nhấn "Phục hồi dữ liệu" và xác nhận.',
          ),
          const SizedBox(height: 16),

          // JSON input
          _buildSectionLabel('DÁN JSON SAO LƯU VÀO ĐÂY'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _restoreJsonValid
                    ? const Color(0xFF16A34A)
                    : _restoreController.text.isNotEmpty
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _restoreJsonValid
                            ? Icons.check_circle_rounded
                            : Icons.data_object_rounded,
                        color: _restoreJsonValid
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _restoreJsonValid
                            ? 'JSON hợp lệ — sẵn sàng phục hồi'
                            : 'Dán JSON backup tại đây',
                        style: TextStyle(
                            fontSize: 12,
                            color: _restoreJsonValid
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pasteFromClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_paste_rounded,
                                  size: 13, color: Color(0xFF475569)),
                              SizedBox(width: 4),
                              Text('Dán',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                TextField(
                  controller: _restoreController,
                  maxLines: 10,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF1E293B)),
                  decoration: const InputDecoration(
                    hintText: '{\n  "backup_time": "...",\n  "tables": {...}\n}',
                    hintStyle: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontFamily: 'monospace',
                        fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                  onChanged: _validateRestoreJson,
                ),
              ],
            ),
          ),

          // JSON validation info
          if (_restoreJsonValid && _parsedRestoreData != null) ...[
            const SizedBox(height: 12),
            _buildRestorePreviewChips(),
          ],

          const SizedBox(height: 20),

          // Clear button
          if (_restoreController.text.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _restoreController.clear();
                  setState(() {
                    _restoreJsonValid = false;
                    _parsedRestoreData = null;
                  });
                },
                icon: const Icon(Icons.clear_rounded,
                    size: 16, color: Color(0xFF94A3B8)),
                label: const Text('Xóa nội dung',
                    style:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
            ),

          const SizedBox(height: 8),

          // Restore button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed:
                  (_restoreJsonValid && !_isRestoring) ? _doRestore : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.restore_rounded, size: 22),
              label: Text(
                _isRestoring ? 'Đang phục hồi...' : 'Phục hồi dữ liệu',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRestorePreviewChips() {
    final tables = _parsedRestoreData?['tables'] as Map<String, dynamic>? ?? {};
    final chips = [
      ('Account', (tables['Account'] as List?)?.length ?? 0,
          const Color(0xFF0EA5E9)),
      ('Caregiver', (tables['Caregiver'] as List?)?.length ?? 0,
          const Color(0xFF16A34A)),
      ('Elderly', (tables['Elderly'] as List?)?.length ?? 0,
          const Color(0xFFEA580C)),
      ('Liên kết', (tables['CaregiverElderly'] as List?)?.length ?? 0,
          const Color(0xFF7C3AED)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 16),
              SizedBox(width: 6),
              Text('Dữ liệu sẽ được phục hồi:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.$3.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${c.$1}: ${c.$2} bản ghi',
                        style: TextStyle(
                            fontSize: 11,
                            color: c.$3,
                            fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String body,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFECACA)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isWarning
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF1E293B))),
                const SizedBox(height: 5),
                Text(body,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: isWarning
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF64748B),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.6));
  }
}

class _StatItem {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.count, this.icon, this.color);
}

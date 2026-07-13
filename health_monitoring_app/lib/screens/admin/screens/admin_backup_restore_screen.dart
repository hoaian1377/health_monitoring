import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_api_service.dart';

class AdminBackupRestoreScreen extends StatefulWidget {
  final bool isRestore;

  const AdminBackupRestoreScreen({super.key, required this.isRestore});

  @override
  State<AdminBackupRestoreScreen> createState() => _AdminBackupRestoreScreenState();
}

class _AdminBackupRestoreScreenState extends State<AdminBackupRestoreScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBackups();
  }

  Future<void> _fetchBackups() async {
    setState(() => _isLoading = true);
    final data = await AdminApiService.getBackups();
    if (mounted) {
      setState(() {
        _backups = data;
        _isLoading = false;
      });
    }
  }

  void _onBackupNow() async {
    setState(() => _isLoading = true);
    final success = await AdminApiService.createBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sao lưu CSDL thành công' : 'Sao lưu thất bại. Vui lòng thử lại.'),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      if (success) {
        await _fetchBackups();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRestore(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận phục hồi', style: TextStyle(color: Color(0xFFEF4444))),
        content: const Text('Bạn có chắc chắn muốn phục hồi CSDL từ bản sao lưu này? Mọi dữ liệu hiện tại sẽ bị thay thế. Quá trình này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await AdminApiService.restoreBackup(id);
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Phục hồi thành công' : 'Phục hồi thất bại. Có thể file bị lỗi.'),
                    backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Phục hồi'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDownload(String filename) async {
    final url = AdminApiService.getDownloadBackupUrl(filename);
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải xuống file. Vui lòng kiểm tra lại liên kết.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Text(
              widget.isRestore ? 'Phục hồi Cơ sở dữ liệu' : 'Sao lưu Cơ sở dữ liệu',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            if (!widget.isRestore) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onBackupNow,
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('Sao lưu ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isRestore ? 'Phục hồi Cơ sở dữ liệu' : 'Sao lưu Cơ sở dữ liệu',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (!widget.isRestore)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _onBackupNow,
                    icon: const Icon(Icons.backup_rounded),
                    label: const Text('Sao lưu ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _backups.isEmpty
                      ? const Center(child: Text('Chưa có bản sao lưu nào.', style: TextStyle(color: Color(0xFF64748B))))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _backups.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB)),
                              ),
                              title: Text(
                                backup['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              subtitle: Text(
                                'Ngày tạo: ${backup['date']} \nKích thước: ${backup['size']}',
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
                                    tooltip: 'Tải về máy',
                                    onPressed: () => _onDownload(backup['name']),
                                  ),
                                  if (widget.isRestore)
                                    IconButton(
                                      icon: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFEF4444)),
                                      tooltip: 'Phục hồi',
                                      onPressed: () => _onRestore(backup['id']),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

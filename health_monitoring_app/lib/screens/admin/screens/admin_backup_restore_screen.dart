import 'package:flutter/material.dart';
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
    setState(() {
      _backups = data;
      _isLoading = false;
    });
  }

  void _onBackupNow() async {
    setState(() => _isLoading = true);
    await AdminApiService.createBackup();
    await _fetchBackups();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sao lưu CSDL thành công')));
  }

  void _onRestore(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận phục hồi', style: TextStyle(color: Color(0xFFF44336))),
        content: const Text('Bạn có chắc chắn muốn phục hồi CSDL từ bản sao lưu này? Mọi dữ liệu hiện tại sẽ bị thay thế.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await AdminApiService.restoreBackup(id);
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phục hồi thành công')));
            },
            child: const Text('Phục hồi'),
          ),
        ],
      ),
    );
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
                    backgroundColor: const Color(0xFF1976D2),
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
                  ),
                ),
                if (!widget.isRestore)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _onBackupNow,
                    icon: const Icon(Icons.backup_rounded),
                    label: const Text('Sao lưu ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
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
                  : _buildBackupList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    if (_backups.isEmpty) {
      return const Center(child: Text('Chưa có bản sao lưu nào.'));
    }

    return ListView.separated(
      itemCount: _backups.length,
      separatorBuilder: (ctx, idx) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final item = _backups[idx];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.source_rounded, color: Color(0xFF1976D2)),
          ),
          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Thời gian: ${item['time']} - Dung lượng: ${item['size']}'),
          trailing: widget.isRestore
              ? ElevatedButton.icon(
                  onPressed: () => _onRestore(item['id']),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Phục hồi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              : const SizedBox(),
        );
      },
    );
  }
}

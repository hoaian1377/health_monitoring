import 'package:flutter/material.dart';
import '../models/admin_user_model.dart';
import '../services/admin_api_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  
  // Pagination
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await AdminApiService.getUsers(
      page: _currentPage,
      search: _searchQuery,
      role: _selectedRole,
      status: _selectedStatus,
    );
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
    _fetchUsers();
  }

  void _showAddUserDialog() {
    // Basic dialog placeholder for Add/Edit
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm người dùng'),
        content: const SizedBox(
          width: 400,
          child: Text('Form thêm người dùng (Họ tên, Email, Mật khẩu, Số điện thoại, Role...) sẽ hiển thị ở đây.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Lưu')),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa người dùng này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminApiService.deleteUser(id);
              _fetchUsers();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(),
          const SizedBox(height: 24),
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
                  : _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      items: ['All', 'elderly', 'caregiver', 'admin']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'Tất cả Role' : e.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRole = val;
                            _currentPage = 1;
                          });
                          _fetchUsers();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStatus,
                      items: ['All', 'active', 'inactive']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'Tất cả trạng thái' : e.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                            _currentPage = 1;
                          });
                          _fetchUsers();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Thêm người dùng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showAddUserDialog,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              items: ['All', 'elderly', 'caregiver', 'admin']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'Tất cả Role' : e.toUpperCase())))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedRole = val;
                    _currentPage = 1;
                  });
                  _fetchUsers();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              items: ['All', 'active', 'inactive']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'Tất cả trạng thái' : e.toUpperCase())))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                    _currentPage = 1;
                  });
                  _fetchUsers();
                }
              },
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Thêm người dùng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _showAddUserDialog,
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_users.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Họ tên')),
            DataColumn(label: Text('Email/SĐT')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Trạng thái')),
            DataColumn(label: Text('Ngày tạo')),
            DataColumn(label: Text('Hành động')),
          ],
          rows: _users.map((user) {
            final isInactive = user.status == 'inactive';
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?'),
                      ),
                      const SizedBox(width: 12),
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.email.isNotEmpty ? user.email : 'N/A'),
                      Text(user.phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.role == 'admin' ? const Color(0xFF1976D2).withOpacity(0.1) : const Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        color: user.role == 'admin' ? const Color(0xFF1976D2) : const Color(0xFF9C27B0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Switch(
                    value: !isInactive,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (val) async {
                      await AdminApiService.toggleUserStatus(user.id, val);
                      _fetchUsers();
                    },
                  ),
                ),
                DataCell(Text(user.createdAt)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF1976D2)),
                        onPressed: () {},
                        tooltip: 'Sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF44336)),
                        onPressed: () => _showDeleteConfirm(user.id),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

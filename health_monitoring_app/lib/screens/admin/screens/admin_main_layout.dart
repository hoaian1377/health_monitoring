import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_backup_restore_screen.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Quản lý người dùng',
    'Thống kê',
    'Sao lưu CSDL',
    'Phục hồi CSDL',
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AdminDashboardScreen(),
      const AdminUserManagementScreen(),
      const AdminStatisticsScreen(),
      const AdminBackupRestoreScreen(isRestore: false),
      const AdminBackupRestoreScreen(isRestore: true),
    ];
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: isDesktop ? null : AdminTopbar(title: _titles[_selectedIndex]),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  _onItemSelected(index);
                  Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) AdminTopbar(title: _titles[_selectedIndex]),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

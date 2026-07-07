import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/caregiver/medicine_management_screen.dart';
import 'screens/caregiver/history_screen.dart';
import 'screens/caregiver/dashboard_screen.dart';
import 'screens/caregiver/profile_screen.dart';
import 'screens/login_screen.dart';
import 'utils/alarm_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
// ── Elderly-specific screens ────────────────────────────────────────────────
import 'screens/elderly/elderly_profile_screen.dart';
import 'screens/elderly/elderly_notifications_screen.dart';
import 'screens/elderly/elderly_checklist_screen.dart';
import 'utils/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo timezone, set về giờ Việt Nam
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  await AlarmService.init();
  runApp(const HealthApp());
}


class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HealthCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F4FB),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  // ignore: library_private_types_in_public_api
  static _MainNavigatorState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainNavigatorState>();
  }

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0; 

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBody() {
    if (ApiService.currentRole == 'elderly') {
      // Elderly role uses dedicated screens — no shared caregiver screens
      return IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),           // routes to ElderlyHomeScreen internally
          ElderlyChecklistScreen(),
          ElderlyNotificationsScreen(),
          ElderlyProfileScreen(),
        ],
      );
    } else {
      return IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          MedicineManagementScreen(),
          HistoryScreen(),
          DashboardScreen(),
          ProfileScreen(),
        ],
      );
    }
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    if (ApiService.currentRole == 'elderly') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_rounded),
          activeIcon: Icon(Icons.checklist_rounded),
          label: 'Việc cần làm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications_rounded),
          label: 'Thông báo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined),
          activeIcon: Icon(Icons.medication_rounded),
          label: 'Quản lý thuốc',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          activeIcon: Icon(Icons.history_rounded),
          label: 'Lịch sử',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Theo dõi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: ApiService.currentRole == 'caregiver' ? null : FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Đang gọi khẩn cấp...'),
            ),
          );
        },
        backgroundColor: Colors.red.shade600,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1A56DB),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 11
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, 
              fontSize: 11
            ),
            iconSize: 24,
            elevation: 0,
            items: _buildNavItems(),
          ),
        ),
      ),
    );
  }
}

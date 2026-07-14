import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/caregiver/medicine_management_screen.dart';
import 'screens/caregiver/caregiver_health_settings_screen.dart';
import 'screens/caregiver/dashboard_screen.dart';
import 'screens/caregiver/profile_screen.dart';
import 'screens/caregiver/caregiver_home_screen.dart';
import 'screens/admin/screens/admin_login_screen.dart';
import 'screens/login_screen.dart';
import 'utils/alarm_service.dart';
import 'utils/elderly_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
// ── Elderly-specific screens ────────────────────────────────────────────────
import 'screens/elderly/elderly_profile_screen.dart';
import 'screens/elderly/elderly_notifications_screen.dart';
import 'screens/elderly/elderly_checklist_screen.dart';
import 'utils/api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/medication_confirmation_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? initialPayload;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo timezone, set về giờ Việt Nam
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  // Check if launched via notification
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = notificationAppLaunchDetails?.notificationResponse?.payload;
  }

  await AlarmService.init(
    onNotificationClick: (payload) {
      if (payload != null && navigatorKey.currentState != null) {
        if (payload.startsWith('medicine_')) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => MedicationConfirmationScreen(payload: payload)),
          );
        }
      }
    }
  );
  runApp(const HealthApp());
}


class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialPayload != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => MedicationConfirmationScreen(payload: initialPayload!)),
        );
        initialPayload = null; // Clear to avoid repeated navigation
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HealthCare',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', ''),
        Locale('en', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F4FB),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin': (context) => const AdminLoginScreen(),
      },
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

  /// Centralized elderly provider for all caregiver screens
  final ElderlyProvider _elderlyProvider = ElderlyProvider.instance;

  ElderlyProvider get elderlyProvider => _elderlyProvider;

  /// Notification polling for elderly role
  Timer? _notifPollingTimer;
  int _lastNotifId = 0;

  @override
  void initState() {
    super.initState();
    // Request notification permissions for all roles (Android 13+)
    AlarmService.requestPermissions();
    // Load elderly list once for caregiver role
    if (ApiService.currentRole == 'caregiver') {
      _elderlyProvider.loadElderlyList();
    }
    // Start notification polling for elderly role
    if (ApiService.currentRole == 'elderly') {
      _initNotificationPolling();
    }
  }

  /// Initialize polling: request permissions, set baseline, then poll every 15s
  Future<void> _initNotificationPolling() async {
    // Request notification permissions (required on Android 13+)
    await AlarmService.requestPermissions();

    // Get current max notification ID as baseline
    final existing = await ApiService.getNotifications();
    if (existing.isNotEmpty) {
      for (var n in existing) {
        final id = n['notificationid'] ?? n['notificationID'] ?? 0;
        if (id is int && id > _lastNotifId) _lastNotifId = id;
      }
    }
    debugPrint('📢 Notification polling started. Baseline ID: $_lastNotifId');
    // Start periodic polling
    _notifPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollForNewNotifications();
    });
  }

  Future<void> _pollForNewNotifications() async {
    if (!mounted) return;
    final newNotifs = await ApiService.getNewNotifications(sinceId: _lastNotifId);
    if (newNotifs.isNotEmpty) {
      debugPrint('📢 Found ${newNotifs.length} new notification(s)');
    }
    for (var n in newNotifs) {
      final nId = n['notificationid'] ?? n['notificationID'] ?? 0;
      final title = n['title'] ?? 'Thông báo';
      final message = n['message'] ?? '';
      final intId = nId is int ? nId : (int.tryParse(nId.toString()) ?? 0);

      debugPrint('📢 Showing push notification: $title');

      // Show system push notification with sound & vibration
      await AlarmService.showImmediateNotification(
        id: intId,
        title: '🔔 $title',
        body: message,
        payload: 'notification_$nId',
      );

      if (intId > _lastNotifId) _lastNotifId = intId;
    }
  }

  @override
  void dispose() {
    _notifPollingTimer?.cancel();
    super.dispose();
  }

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
      return Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeScreen(),
                MedicineManagementScreen(),
                HealthDashboardScreen(),
                DashboardScreen(),
                ProfileScreen(),
              ],
            ),
          ),
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
          icon: Icon(Icons.folder_shared_outlined),
          activeIcon: Icon(Icons.folder_shared_rounded),
          label: 'Hồ sơ',
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

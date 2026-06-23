import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'elderly/elderly_home_screen.dart';
import 'caregiver/caregiver_home_screen.dart';

/// HomeScreen — Chỉ chịu trách nhiệm routing theo role.
/// - Role "elderly"   → ElderlyHomeScreen
/// - Role "caregiver" → CaregiverHomeScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isElderly = ApiService.currentRole == 'elderly';
    if (isElderly) {
      return const ElderlyHomeScreen();
    } else {
      return const CaregiverHomeScreen();
    }
  }
}

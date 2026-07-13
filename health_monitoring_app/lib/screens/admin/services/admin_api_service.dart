import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_user_model.dart';
import '../../../utils/api_service.dart'; // To get the base URL

class AdminApiService {
  static String get _baseUrl => '${ApiService.baseUrl}/api/admin';

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/dashboard-stats/'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dashboard stats: $e');
    }
    // Fallback if error
    return {
      'totalUsers': 0,
      'totalElderly': 0,
      'totalCaregiver': 0,
      'totalAdmin': 0,
      'alertsToday': 0,
      'sosToday': 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getLatestAlerts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/latest-alerts/'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting latest alerts: $e');
    }
    return [];
  }

  static Future<List<AdminUser>> getUsers({int page = 1, String search = '', String role = 'All', String status = 'All'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/users/?search=$search&role=$role');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AdminUser.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting users: $e');
    }
    return [];
  }

  static Future<bool> addUser(AdminUser user) async {
    // Basic mock logic, full implementation requires registering via users API
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<bool> updateUser(AdminUser user) async {
    try {
      final response = await http.put(Uri.parse('$_baseUrl/users/${user.id}/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$id/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleUserStatus(String id, bool isActive) async {
    try {
      final response = await http.put(Uri.parse('$_baseUrl/users/$id/status/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getBackups() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/backups/'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {}
    return [];
  }

  static Future<bool> createBackup() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  static Future<bool> restoreBackup(String id) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/restore/$id/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

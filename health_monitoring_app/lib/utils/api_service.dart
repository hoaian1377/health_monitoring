import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.123.5:8000";

  // ================= REGISTER =================
  static Future<bool> register({
    required String username,
    required String password,
    required String fullname,
    required String phone,
    required String email,
    required String role,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/register/");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "fullname": fullname,
          "email": email,
          "phone": phone,
          "role": role
        }),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/login/");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          "success": true,
          "data": data,
        };
      } else {
        return {
          "success": false,
          "error": "Tên đăng nhập hoặc mật khẩu không chính xác.",
        };
      }
    } catch (e) {
      print("ERROR: $e");
      return {
        "success": false,
        "error": "Lỗi kết nối máy chủ.",
      };
    }
  }
}
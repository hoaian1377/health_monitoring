import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.123.5:8000";
  static int? currentAccountId;
  static String currentUsername = 'Người dùng';
  static String currentRole = 'caregiver';
  static String currentFullname = '';
  static String currentEmail = '';
  static String currentPhone = '';
  static String currentDob = '';
  static String currentGender = '';

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
          "phone": phone,
          "email": email,
          "role": role,
        }),
      );

      if (res.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
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
        if (data["user"] != null && data["user"]["id"] != null) {
          currentAccountId = data["user"]["id"];
          currentUsername = data["user"]["username"] ?? 'Người dùng';
          currentRole = data["user"]["role"] ?? 'caregiver';
          currentFullname = data["user"]["fullname"] ?? '';
          currentEmail = data["user"]["email"] ?? '';
          currentPhone = data["user"]["phone"] ?? '';
          currentDob = ''; // caregiver might not have this
          currentGender = '';
        }
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

  // ================= CREATE ELDERLY =================
  static Future<Map<String, dynamic>> createElderly({
    required String fullname,
    required String dob,
    required String gender,
    required String medicalNote,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/elderly/");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "caregiver_account_id": currentAccountId,
          "fullname": fullname,
          "date_of_birthday": dob,
          "gender": gender,
          "medical_note": medicalNote,
        }),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {
          "success": true,
          "qr_token": data["qr_token"],
        };
      } else {
        return {
          "success": false,
          "error": "Không thể tạo hồ sơ. Vui lòng thử lại.",
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

  // ================= LOGIN BY QR =================
  static Future<Map<String, dynamic>> loginByQr({
    required String qrToken,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/login-qr/");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"qr_token": qrToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["elderly"] != null) {
          currentAccountId = data["elderly"]["id"];
          currentRole = 'elderly';
          currentFullname = data["elderly"]["fullname"] ?? '';
          currentDob = data["elderly"]["dob"] ?? '';
          currentGender = data["elderly"]["gender"] ?? '';
          currentUsername = 'Người cao tuổi';
          currentEmail = '';
          currentPhone = '';
        }
        return {"success": true, "data": data};
      } else {
        return {"success": false, "error": "Mã QR không hợp lệ."};
      }
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= GET MEDICATION =================
  static Future<List<dynamic>> getMedication() async {
    final url = Uri.parse("$baseUrl/api/medication/");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print("ERROR: $e");
      return [];
    }
  }

  // ================= GET MEDICATION SCHEDULE =================
  static Future<List<dynamic>> getMedicationSchedule() async {
    final url = Uri.parse("$baseUrl/api/medication/schedule/");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print("ERROR: $e");
      return [];
    }
  }

  // ================= GET MEDICAL DOCUMENT =================
  static Future<List<dynamic>> getMedicalDocument() async {
    final url = Uri.parse("$baseUrl/api/medication/document/");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print("ERROR: $e");
      return [];
    }
  }
}
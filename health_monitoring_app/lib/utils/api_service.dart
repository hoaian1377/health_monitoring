import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.123.4:8000";
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
          "dob": dob,
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

  // ================= GET ELDERLY LIST =================
  static Future<Map<String, dynamic>> getElderlyList() async {
    final url = Uri.parse(
        "$baseUrl/api/users/elderly-list/?caregiver_account_id=$currentAccountId");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "elderly_list": data["elderly_list"] ?? []};
      }
      return {"success": false, "error": "Không thể tải danh sách."};
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= UPDATE ELDERLY =================
  static Future<Map<String, dynamic>> updateElderly({
    required int elderlyId,
    required String fullname,
    required String dob,
    required String gender,
    required String medicalNote,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/elderly/$elderlyId/update/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullname": fullname,
          "dob": dob,
          "gender": gender,
          "medical_note": medicalNote,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "elderly": data["elderly"]};
      }
      return {"success": false, "error": "Cập nhật thất bại."};
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
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

  // ================= GET ELDERLY MEDICATION SCHEDULE =================
  static Future<List<dynamic>> getElderlyMedicationSchedule(int elderlyId) async {
    final url = Uri.parse("$baseUrl/api/medication/elderly-schedule/?elderly_id=$elderlyId");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["schedules"] ?? [];
      }
      return [];
    } catch (e) {
      print("ERROR: $e");
      return [];
    }
  }

  // ================= ADD MEDICATION & SCHEDULE =================
  static Future<bool> addMedication({
    required int elderlyId,
    required String name,
    required String dosage,
    required String instruction,
    required String time,
    required String frequency,
  }) async {
    final url = Uri.parse("$baseUrl/api/medication/create/");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "elderly_id": elderlyId,
          "name": name,
          "dosage": dosage,
          "instruction": instruction,
          "time": time,
          "frequency": frequency,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ================= UPDATE MEDICATION & SCHEDULE =================
  static Future<bool> updateMedication({
    required int scheduleId,
    required String name,
    required String dosage,
    required String instruction,
    required String time,
    required String frequency,
  }) async {
    final url = Uri.parse("$baseUrl/api/medication/schedule/$scheduleId/update/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "dosage": dosage,
          "instruction": instruction,
          "time": time,
          "frequency": frequency,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= DELETE MEDICATION SCHEDULE =================
  static Future<bool> deleteMedication(int scheduleId) async {
    final url = Uri.parse("$baseUrl/api/medication/schedule/$scheduleId/delete/");
    try {
      final res = await http.delete(url);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= SCAN PRESCRIPTION (OCR Mock) =================
  static Future<Map<String, dynamic>> scanPrescription(String imagePath) async {
    final url = Uri.parse("$baseUrl/api/medication/scan-prescription/");
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      var streamedResponse = await request.send();
      var res = await http.Response.fromStream(streamedResponse);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {"error": "Lỗi quét ảnh (status ${res.statusCode})"};
    } catch (e) {
      return {"error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= CREATE APPOINTMENT =================
  static Future<bool> createAppointment({
    required int elderlyId,
    required String doctorName,
    required String location,
    required String appointmentDate,
    required String appointmentTime,
    String note = '',
  }) async {
    final url = Uri.parse("$baseUrl/api/medication/appointment/create/");
    try {
      final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'elderly_id': elderlyId,
          'doctor_name': doctorName,
          'location': location,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'note': note,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
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

  // ================= UC-6: SAO LƯU CSDL =================
  static Future<Map<String, dynamic>> backupDatabase() async {
    final url = Uri.parse("$baseUrl/api/users/backup/");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "data": data};
      }
      return {"success": false, "error": "Không thể sao lưu. Mã lỗi: ${res.statusCode}"};
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= UC-7: PHỤC HỒI CSDL =================
  static Future<Map<String, dynamic>> restoreDatabase({
    required Map<String, dynamic> backupData,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/restore/");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"backup_data": backupData}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {"success": true, "data": data};
      }
      final err = jsonDecode(res.body);
      return {"success": false, "error": err["error"] ?? "Phục hồi thất bại."};
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }
}

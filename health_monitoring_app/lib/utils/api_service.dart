import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://192.168.123.4:8000";
    }
    return "http://localhost:8000";
  }

  static int? currentAccountId;
  static int? currentElderlyId;
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
        body: jsonEncode({"username": username, "password": password}),
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
          currentDob = data["user"]["dob"] ?? '';
          currentGender = data["user"]["gender"] ?? '';
        }
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "error": "Tên đăng nhập hoặc mật khẩu không chính xác.",
        };
      }
    } catch (e) {
      print("ERROR: $e");
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
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
        return {"success": true, "qr_token": data["qr_token"]};
      } else {
        return {
          "success": false,
          "error": "Không thể tạo hồ sơ. Vui lòng thử lại.",
        };
      }
    } catch (e) {
      print("ERROR: $e");
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= GET ELDERLY LIST =================
  static Future<Map<String, dynamic>> getElderlyList() async {
    final url = Uri.parse(
      "$baseUrl/api/users/elderly-list/?caregiver_account_id=$currentAccountId",
    );
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
    String? bloodType,
    double? height,
    double? weight,
    String? allergies,
    String? underlyingConditions,
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
          "blood_type": bloodType,
          "height": height,
          "weight": weight,
          "allergies": allergies,
          "underlying_conditions": underlyingConditions,
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

  // ================= UPDATE CAREGIVER =================
  static Future<Map<String, dynamic>> updateCaregiverProfile({
    required String fullname,
    required String phone,
    required String email,
    String? gender,
    String? dob,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/caregiver/update/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "account_id": currentAccountId,
          "fullname": fullname,
          "phone": phone,
          "email": email,
          "gender": gender,
          "dob": dob,
        }),
      );
      if (res.statusCode == 200) {
        return {"success": true};
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

  // ================= CHANGE PASSWORD =================
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/change-password/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "account_id": currentAccountId,
          "old_password": oldPassword,
          "new_password": newPassword,
        }),
      );
      if (res.statusCode == 200) {
        return {"success": true, "message": "Đổi mật khẩu thành công."};
      } else {
        return {"success": false, "error": "Lỗi đổi mật khẩu."};
      }
    } catch (e) {
      return {"success": false, "error": "Lỗi kết nối máy chủ."};
    }
  }

  // ================= MEDICAL DOCUMENTS =================
  static Future<List<dynamic>> getMedicalDocument() async {
    if (currentElderlyId == null) return [];
    final url = Uri.parse("$baseUrl/api/medication/elderly-document/list/?elderly_id=$currentElderlyId");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      }
    } catch (e) {
      print("Error fetching medical documents: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> uploadMedicalDocument({
    required String filePath,
    required String documentType,
    int? elderlyId,
  }) async {
    final eId = elderlyId ?? currentElderlyId;
    if (eId == null) return {"success": false, "error": "Chưa chọn người cao tuổi"};
    
    final url = Uri.parse("$baseUrl/api/medication/elderly-document/upload/");
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['elderly_id'] = eId.toString();
      request.fields['document_type'] = documentType;
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var response = await request.send();
      if (response.statusCode == 201) {
        return {"success": true, "message": "Upload thành công"};
      } else {
        return {"success": false, "error": "Lỗi upload tài liệu"};
      }
    } catch (e) {
      print("Error uploading document: $e");
      return {"success": false, "error": "Lỗi kết nối máy chủ: $e"};
    }
  }


  // ================= FORGOT PASSWORD =================
  static Future<Map<String, dynamic>> forgotPassword({
    required String phone,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/forgot-password/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "new_password": newPassword,
        }),
      );
      if (res.statusCode == 200) {
        return {"success": true, "message": "Đặt lại mật khẩu thành công."};
      }
      final err = jsonDecode(res.body);
      return {"success": false, "error": err["error"] ?? "Đặt lại mật khẩu thất bại."};
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
  static Future<List<dynamic>> getElderlyMedicationSchedule(
    int elderlyId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/api/medication/elderly-schedule/?elderly_id=$elderlyId",
    );
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
    String description = '',
    String? startDate,
    String? endDate,
  }) async {
    final url = Uri.parse("$baseUrl/api/medication/create/");
    try {
      final body = <String, dynamic>{
        "elderly_id": elderlyId,
        "name": name,
        "dosage": dosage,
        "instruction": instruction,
        "time": time,
        "frequency": frequency,
        "description": description,
      };
      if (startDate != null && startDate.isNotEmpty)
        body["start_date"] = startDate;
      if (endDate != null && endDate.isNotEmpty) body["end_date"] = endDate;

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
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
    String description = '',
    String? startDate,
    String? endDate,
  }) async {
    final url = Uri.parse(
      "$baseUrl/api/medication/schedule/$scheduleId/update/",
    );
    try {
      final body = <String, dynamic>{
        "name": name,
        "dosage": dosage,
        "instruction": instruction,
        "time": time,
        "frequency": frequency,
        "description": description,
      };
      if (startDate != null && startDate.isNotEmpty)
        body["start_date"] = startDate;
      if (endDate != null && endDate.isNotEmpty) body["end_date"] = endDate;

      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= DELETE MEDICATION SCHEDULE =================
  static Future<bool> deleteMedication(int scheduleId) async {
    final url = Uri.parse(
      "$baseUrl/api/medication/schedule/$scheduleId/delete/",
    );
    try {
      final res = await http.delete(url);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= SCAN PRESCRIPTION (OCR Mock) =================
  static Future<Map<String, dynamic>> scanPrescription(XFile imageFile) async {
    final url = Uri.parse("$baseUrl/api/medication/scan-prescription/");
    try {
      final request = http.MultipartRequest('POST', url);
      if (kIsWeb) {
        final imageBytes = await imageFile.readAsBytes();
        final filename = imageFile.name.isNotEmpty
            ? imageFile.name
            : 'prescription.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      final payload = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (payload is Map<String, dynamic> && payload['error'] != null) {
        return {"error": payload['error']};
      }
      return {"error": "Lỗi quét ảnh (status ${res.statusCode})"};
    } catch (e) {
      return {"error": "Lỗi kết nối máy chủ: $e"};
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
      final res = await http.post(
        url,
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

  static Future<bool> updateAppointment(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/medication/appointment/$id/update/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAppointment(int id) async {
    final url = Uri.parse("$baseUrl/api/medication/appointment/$id/delete/");
    try {
      final res = await http.delete(url);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ================= GET APPOINTMENTS =================
  static Future<List<dynamic>> getAppointments(int elderlyId) async {
    final url = Uri.parse(
      "$baseUrl/api/medication/appointment/list/?elderly_id=$elderlyId",
    );
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
      return {
        "success": false,
        "error": "Không thể sao lưu. Mã lỗi: ${res.statusCode}",
      };
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

  // ================= GET NOTIFICATIONS =================
  static Future<List<dynamic>> getNotifications() async {
    final queryParam = currentRole == 'elderly'
        ? 'elderly_id=$currentAccountId'
        : 'caregiver_id=$currentAccountId';
    final url = Uri.parse(
      "$baseUrl/api/notification/notifications/?$queryParam",
    );
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

  // ================= GENERATE MOCK NOTIFICATIONS =================
  static Future<bool> generateMockNotifications() async {
    if (currentAccountId == null || currentRole == null) return false;
    try {
      final queryParam = currentRole == 'caregiver' ? 'caregiver_id=$currentAccountId' : 'elderly_id=$currentAccountId';
      final url = Uri.parse(
          "$baseUrl/api/notification/generate-mock/?$queryParam");
      final res = await http.post(url);
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ================= NOTIFY MISSED MEDICATION =================
  static Future<bool> notifyMissedMedication(int elderlyId, String medicationName) async {
    try {
      final url = Uri.parse("$baseUrl/api/notification/notify-missed/");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "elderly_id": elderlyId,
          "medication_name": medicationName,
        }),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= MARK NOTIFICATION READ =================
  static Future<bool> markNotificationRead(int detailId) async {
    final url = Uri.parse("$baseUrl/api/notification/notifications/$detailId/");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  // ================= ADD HEALTH METRIC =================
  static Future<bool> addHealthMetric({
    required int elderlyId,
    int? heartRate,
    String? bloodPressure,
    double? bloodSugar,
    double? temperature,
    double? weight,
  }) async {
    final url = Uri.parse("$baseUrl/api/healthmetrics/create/");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "elderlyid": elderlyId,
          "heart_rate": heartRate,
          "blood_pressure": bloodPressure,
          "blood_sugar": bloodSugar,
          "temperature": temperature,
          "weight": weight,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  // ================= GET HEALTH METRICS =================
  static Future<List<dynamic>> getHealthMetrics(int elderlyId) async {
    final url = Uri.parse(
      "$baseUrl/api/healthmetrics/list/?elderly_id=$elderlyId",
    );
    try {
      final res = await http.get(url);
      print("[HealthMetrics] Status: ${res.statusCode}, Body: ${res.body}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Hỗ trợ cả array thẳng và {"results": [...]}
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['results'] != null)
          return decoded['results'];
        return [];
      }
      return [];
    } catch (e) {
      print("[HealthMetrics] ERROR: $e");
      return [];
    }
  }

  // ================= CHECKLIST =================

  /// Lấy danh sách checklist theo elderly_id
  static Future<List<dynamic>> getChecklists(int elderlyId) async {
    final url = Uri.parse("$baseUrl/api/checklist/?elderly_id=$elderlyId");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['results'] != null) {
          return decoded['results'];
        }
        return [];
      }
      return [];
    } catch (e) {
      print("ERROR getChecklists: $e");
      return [];
    }
  }

  /// Lấy các items của một checklist
  static Future<List<dynamic>> getChecklistItems(int checklistId) async {
    final url = Uri.parse(
      "$baseUrl/api/checklist/item/?checklist_id=$checklistId",
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['results'] != null) {
          return decoded['results'];
        }
        return [];
      }
      return [];
    } catch (e) {
      print("ERROR getChecklistItems: $e");
      return [];
    }
  }

  /// Tạo checklist mới gắn với elderly
  static Future<Map<String, dynamic>> createChecklist({
    required int elderlyId,
    String title = '',
    int? appointmentId,
  }) async {
    final url = Uri.parse("$baseUrl/api/checklist/create/");
    try {
      final body = <String, dynamic>{'elderlyid': elderlyId, 'title': title};
      if (appointmentId != null) body['appointmentid'] = appointmentId;
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'error': 'Tạo checklist thất bại'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Thêm item vào checklist
  static Future<bool> createChecklistItem({
    required int checklistId,
    required String title,
    String? content,
    String itemType = 'task',
    String timeString = '',
    String details = '',
    String? hospital,
    String? doctor,
    String? appointmentDate,
  }) async {
    final url = Uri.parse("$baseUrl/api/checklist/item/create/");
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'checklistid': checklistId,
          'title': title,
          'item_type': itemType,
          'time_string': timeString,
          'details': details,
          'hospital': hospital,
          'doctor': doctor,
          'appointment_date': appointmentDate,
          'file_path': null,
          'is_complete': false,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print("ERROR createChecklistItem: $e");
      return false;
    }
  }

  /// Tạo nhiều items cùng lúc
  static Future<bool> bulkCreateChecklistItems({
    required int checklistId,
    required List<Map<String, String>> items,
  }) async {
    final url = Uri.parse("$baseUrl/api/checklist/$checklistId/items/bulk/");
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items}),
      );
      return res.statusCode == 201;
    } catch (e) {
      print("ERROR bulkCreate: $e");
      return false;
    }
  }

  /// Toggle hoàn thành / chưa hoàn thành một item
  static Future<Map<String, dynamic>> toggleChecklistItem(int itemId) async {
    final url = Uri.parse("$baseUrl/api/checklist/item/$itemId/toggle/");
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false};
    } catch (e) {
      print("ERROR toggleChecklistItem: $e");
      return {'success': false};
    }
  }

  /// Cập nhật checklist item
  static Future<bool> updateChecklistItem(
    int itemId, {
    String? content,
    bool? isComplete,
    String? note,
  }) async {
    final url = Uri.parse("$baseUrl/api/checklist/item/$itemId/");
    try {
      final body = <String, dynamic>{};
      if (content != null) body['content'] = content;
      if (isComplete != null) body['is_complete'] = isComplete;
      if (note != null) body['note'] = note;
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("ERROR updateChecklistItem: $e");
      return false;
    }
  }

  /// Xoá checklist item
  static Future<bool> deleteChecklistItem(int itemId) async {
    final url = Uri.parse("$baseUrl/api/checklist/item/$itemId/");
    try {
      final res = await http.delete(url);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      print("ERROR deleteChecklistItem: $e");
      return false;
    }
  }

  // ================= TREATMENT HISTORY =================

  /// Lấy danh sách lịch sử điều trị theo elderly_id
  static Future<List<dynamic>> getTreatmentHistory(
    int elderlyId, {
    String? status,
  }) async {
    String endpoint = "$baseUrl/api/treatmenthistory/?elderly_id=$elderlyId";
    if (status != null) endpoint += "&status=$status";
    final url = Uri.parse(endpoint);
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("ERROR getTreatmentHistory: $e");
      return [];
    }
  }

  /// Tạo mới kết quả khám bệnh (Lưu vào MedicalDocument)
  static Future<Map<String, dynamic>> createMedicalDocument({
    required int elderlyId,
    required String hospital,
    required String doctorName,
    required String diagnosis,
    required String result,
    required String documentType,
    String? filePath,
  }) async {
    final url = Uri.parse("$baseUrl/api/medication/elderly-document/upload/");
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['elderly_id'] = elderlyId.toString();
      request.fields['document_type'] = documentType;
      request.fields['hospital'] = hospital;
      request.fields['doctor_name'] = doctorName;
      request.fields['diagnosis'] = diagnosis;
      request.fields['result'] = result;
      
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {"success": true, "data": jsonDecode(utf8.decode(res.bodyBytes))};
      }
      return {"success": false, "error": "Lỗi thêm kết quả. Mã lỗi: ${res.statusCode}"};
    } catch (e) {
      print("ERROR createMedicalDocument: $e");
      return {"success": false, "error": "Không thể kết nối máy chủ."};
    }
  }

  /// Cập nhật lịch sử điều trị
  static Future<bool> updateTreatmentHistory(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$baseUrl/api/treatmenthistory/$id/update/");
    try {
      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("ERROR updateTreatmentHistory: $e");
      return false;
    }
  }

  /// Cập nhật nhanh trạng thái (ongoing / completed / cancelled)
  static Future<bool> updateTreatmentStatus(int id, String newStatus) async {
    final url = Uri.parse("$baseUrl/api/treatmenthistory/$id/status/");
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("ERROR updateTreatmentStatus: $e");
      return false;
    }
  }

  /// Xoá lịch sử điều trị
  static Future<bool> deleteTreatmentHistory(int id) async {
    final url = Uri.parse("$baseUrl/api/treatmenthistory/$id/delete/");
    try {
      final res = await http.delete(url);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("ERROR deleteTreatmentHistory: $e");
      return false;
    }
  }

  // ================= CHATBOT =================
  static Future<String> chatWithAssistant(int elderlyId, String message) async {
    final url = Uri.parse("$baseUrl/api/medication/chatbot/");
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'elderly_id': elderlyId,
          'message': message,
        }),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        return decoded['response'] ?? "Xin lỗi, tôi không thể trả lời lúc này.";
      }
      return "Xin lỗi, đã có lỗi kết nối máy chủ (Mã: ${res.statusCode}).";
    } catch (e) {
      return "Không thể kết nối với trợ lý ảo: $e";
    }
  }
}

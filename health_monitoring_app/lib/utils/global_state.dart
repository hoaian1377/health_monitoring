import 'package:flutter/material.dart';

class ElderlyProfile {
  String name;
  String dob;
  String gender;
  String phone;
  String address;
  String bloodType;
  String diseases;
  String allergies;
  String emergencyContact;
  bool isActive;

  ElderlyProfile({
    required this.name,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.address,
    required this.bloodType,
    required this.diseases,
    required this.allergies,
    required this.emergencyContact,
    this.isActive = false,
  });
}

class MedicationLog {
  final String id;
  final String taskId;
  final String taskTitle;
  final DateTime takenAt;
  final String status; // 'taken', 'missed'

  MedicationLog({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.takenAt,
    required this.status,
  });
}

class HealthThresholds {
  double sysBpMin, sysBpMax;
  double diaBpMin, diaBpMax;
  double bloodSugarMin, bloodSugarMax;
  double heartRateMin, heartRateMax;
  double weightMin, weightMax;

  HealthThresholds({
    this.sysBpMin = 90, this.sysBpMax = 140,
    this.diaBpMin = 60, this.diaBpMax = 90,
    this.bloodSugarMin = 3.9, this.bloodSugarMax = 7.8,
    this.heartRateMin = 60, this.heartRateMax = 100,
    this.weightMin = 50, this.weightMax = 80,
  });
}

class GlobalState {
  static final GlobalState _instance = GlobalState._internal();
  factory GlobalState() => _instance;
  GlobalState._internal();

  final ValueNotifier<List<ElderlyProfile>> profiles = ValueNotifier([
    ElderlyProfile(
      name: 'Nguyễn Văn An',
      dob: '12/03/1958',
      gender: 'Nam',
      phone: '0901 234 567',
      address: '123 Nguyễn Trãi, Q.1, TP.HCM',
      bloodType: 'O+',
      diseases: 'Huyết áp cao, Tiểu đường type 2',
      allergies: 'Penicillin',
      emergencyContact: 'Nguyễn Thị Bình - 0912 345 678',
      isActive: true,
    ),
    ElderlyProfile(
      name: 'Trần Thị Mai',
      dob: '05/07/1955',
      gender: 'Nữ',
      phone: '0903 456 789',
      address: '45 Lê Lợi, Q.3, TP.HCM',
      bloodType: 'A+',
      diseases: 'Loãng xương',
      allergies: 'Không có',
      emergencyContact: 'Trần Văn Hùng - 0934 567 890',
      isActive: false,
    ),
  ]);

  ElderlyProfile get activeProfile => profiles.value.firstWhere((p) => p.isActive, orElse: () => profiles.value.first);

  void switchActiveProfile(int index) {
    final newList = List<ElderlyProfile>.from(profiles.value);
    for (var p in newList) p.isActive = false;
    newList[index].isActive = true;
    profiles.value = List.from(newList); // Trigger update
  }

  void addProfile(ElderlyProfile profile) {
    final newList = List<ElderlyProfile>.from(profiles.value);
    newList.add(profile);
    profiles.value = newList;
  }

  void updateProfile(int index, ElderlyProfile profile) {
    final newList = List<ElderlyProfile>.from(profiles.value);
    newList[index] = profile;
    profiles.value = newList;
  }

  void deleteProfile(int index) {
    final newList = List<ElderlyProfile>.from(profiles.value);
    newList.removeAt(index);
    profiles.value = newList;
  }

  final ValueNotifier<List<MedicationLog>> medicationLogs = ValueNotifier([]);
  final ValueNotifier<HealthThresholds> thresholds = ValueNotifier(HealthThresholds());

  bool isOutOfRange(String metric, double value) {
    final t = thresholds.value;
    switch (metric) {
      case 'sysBp': return value < t.sysBpMin || value > t.sysBpMax;
      case 'diaBp': return value < t.diaBpMin || value > t.diaBpMax;
      case 'bloodSugar': return value < t.bloodSugarMin || value > t.bloodSugarMax;
      case 'heartRate': return value < t.heartRateMin || value > t.heartRateMax;
      case 'weight': return value < t.weightMin || value > t.weightMax;
      default: return false;
    }
  }

  void addMedicationLog(MedicationLog log) {
    final newList = List<MedicationLog>.from(medicationLogs.value);
    newList.add(log);
    medicationLogs.value = newList;
  }
  
  void updateThresholds(HealthThresholds newThresholds) {
    thresholds.value = newThresholds;
  }
}

final globalState = GlobalState();

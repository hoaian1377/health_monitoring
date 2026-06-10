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
}

final globalState = GlobalState();

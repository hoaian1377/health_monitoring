import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/medication_dialog_helper.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:qr_flutter/qr_flutter.dart';
import '../../main.dart';
import '../../utils/api_service.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  final GlobalKey _qrImageKey = GlobalKey();

  // Medication Management State
  List<Map<String, dynamic>> _elderlyList = [];
  int? _selectedElderlyId;
  List<dynamic> _medicationSchedules = [];
  bool _isLoadingMedications = false;
  String _selectedMedFilter = 'Tất cả';
  late final ScrollController _medListScrollController;

  // Chỉ số sức khoẻ
  String _bpSys = '--';
  String _bpDia = '--';
  String _heartRate = '--';
  String _bloodSugar = '--';
  String _temperature = '--';

  @override
  void initState() {
    super.initState();
    _medListScrollController = ScrollController();
    _loadElderlyList();
  }

  @override
  void dispose() {
    _medListScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadElderlyList() async {
    final result = await ApiService.getElderlyList();
    if (mounted && result['success'] == true) {
      final list = (result['elderly_list'] as List)
          .cast<Map<String, dynamic>>();
      setState(() {
        _elderlyList = list;
        if (list.isNotEmpty) {
          if (ApiService.currentElderlyId != null && list.any((e) => e['id'] == ApiService.currentElderlyId)) {
            _selectedElderlyId = ApiService.currentElderlyId;
          } else {
            _selectedElderlyId = list.first['id'] as int;
            ApiService.currentElderlyId = _selectedElderlyId;
          }
          _loadElderlyDetails();
        }
      });
    }
  }

  Future<void> _loadElderlyDetails() async {
    if (_selectedElderlyId == null) return;
    setState(() => _isLoadingMedications = true);

    final schedules = await ApiService.getElderlyMedicationSchedule(
      _selectedElderlyId!,
    );
    final data = await ApiService.getHealthMetrics(_selectedElderlyId!);

    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;

        // Reset metrics first
        _bpSys = '--';
        _bpDia = '--';
        _heartRate = '--';
        _bloodSugar = '--';
        _temperature = '--';

        if (data.isNotEmpty) {
          bool foundHr = false;
          bool foundBp = false;
          bool foundSugar = false;
          bool foundTemp = false;

          for (var item in data) {
            if (!foundHr && item['heart_rate'] != null) {
              _heartRate = item['heart_rate'].toString();
              foundHr = true;
            }
            if (!foundBp && item['blood_pressure'] != null) {
              final bp = item['blood_pressure'].toString().split('/');
              if (bp.length == 2) {
                _bpSys = bp[0];
                _bpDia = bp[1];
                foundBp = true;
              }
            }
            if (!foundSugar && item['blood_sugar'] != null) {
              _bloodSugar = item['blood_sugar'].toString();
              foundSugar = true;
            }
            if (!foundTemp && item['temperature'] != null) {
              _temperature = item['temperature'].toString();
              foundTemp = true;
            }
          }
        }
      });
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMedicalRecordCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileCard()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAddElderlyCard(),
                  const SizedBox(height: 16),
                  _buildMedicationManagementCard(),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(),
                  const SizedBox(height: 16),
                  _buildHealthTrackingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final name = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;

    final hour = DateTime.now().hour;
    String greeting = 'Chào buổi sáng,';
    if (hour >= 12 && hour < 18) {
      greeting = 'Chào buổi chiều,';
    } else if (hour >= 18) {
      greeting = 'Chào buổi tối,';
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào $name 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Chuông thông báo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _showNotificationsDialog,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lời khuyên sức khỏe hôm nay:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hãy uống đủ 2 lít nước và duy trì vận động nhẹ nhàng bác nhé!',
                        style: TextStyle(
                          color: Color(0xDDFFFFFF),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Hồ sơ khám bệnh ──────────────────────────────────────────────────
  Widget _buildMedicalRecordCard() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => MainNavigator.of(context)?.setTab(2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_shared_rounded,
                        color: Color(0xFF0EA5E9),
                        size: 20,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 12,
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Hồ sơ khám bệnh',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản lý hồ sơ, toa thuốc, X-Quang...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF0EA5E9),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Upload hồ sơ',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Thẻ Hồ sơ cá nhân ────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final name = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;
    final nameSplit = name.split(' ');
    final shortName = nameSplit.isNotEmpty ? nameSplit.last : name;

    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => MainNavigator.of(context)?.setTab(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 12,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  shortName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.bloodtype_outlined, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Nhóm máu: ',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      'O+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.orange,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Bệnh nền: ',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      'Huyết áp',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedFilterTabs(Map<String, List<dynamic>> groupedMeds) {
    final int allCount = _medicationSchedules.length;
    final int morningCount = groupedMeds['Buổi sáng']!.length;
    final int afternoonCount = groupedMeds['Buổi trưa/chiều']!.length;
    final int eveningCount = groupedMeds['Buổi tối']!.length;

    final filters = [
      {'label': 'Tất cả', 'count': allCount},
      {'label': 'Sáng', 'count': morningCount},
      {'label': 'Trưa/Chiều', 'count': afternoonCount},
      {'label': 'Tối', 'count': eveningCount},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _selectedMedFilter == label;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMedFilter = label;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0EA5E9)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Thẻ Quản lý lịch uống thuốc ──────────────────────────────────────────
  Widget _buildMedicationManagementCard() {
    // Group schedules by time
    final Map<String, List<dynamic>> groupedMeds = {
      'Buổi sáng': [],
      'Buổi trưa/chiều': [],
      'Buổi tối': [],
      'Khác': [],
    };

    for (var schedule in _medicationSchedules) {
      // Skip schedules without a medication name to avoid empty entries
      final med = schedule['medication'] ?? {};
      final medName = (med['name'] ?? '').toString().trim();
      if (medName.isEmpty) continue;
      final timeStr = schedule['time']?.toString() ?? '';
      String group = 'Khác';
      if (timeStr.isNotEmpty && timeStr != '--:--') {
        try {
          final hour = int.parse(timeStr.split(':')[0]);
          if (hour >= 5 && hour < 12) {
            group = 'Buổi sáng';
          } else if (hour >= 12 && hour < 18) {
            group = 'Buổi trưa/chiều';
          } else {
            group = 'Buổi tối';
          }
        } catch (_) {}
      }
      groupedMeds[group]!.add(schedule);
    }

    // Compact mode: medication counts will be derived from grouped lists when needed

    final filteredGroups = groupedMeds.entries.where((e) {
      if (e.value.isEmpty) return false;
      if (_selectedMedFilter == 'Tất cả') return true;
      if (_selectedMedFilter == 'Sáng') return e.key == 'Buổi sáng';
      if (_selectedMedFilter == 'Trưa/Chiều') return e.key == 'Buổi trưa/chiều';
      if (_selectedMedFilter == 'Tối') return e.key == 'Buổi tối';
      return false;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản lý Lịch uống thuốc',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Thiết lập & Theo dõi việc uống thuốc',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_elderlyList.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedElderlyId,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF475569),
                            size: 20,
                          ),
                          isDense: true,
                          isExpanded: true,
                          items: _elderlyList.map((e) {
                            return DropdownMenuItem<int>(
                              value: e['id'] as int,
                              child: Text(
                                e['fullname'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedElderlyId = val;
                                ApiService.currentElderlyId = val;
                              });
                              _loadElderlyDetails();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Compact view: hide full progress bar to save vertical space

            // Filter Tabs
            _buildMedFilterTabs(groupedMeds),
            const SizedBox(height: 16),

            // Medication List
            if (_elderlyList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Chưa có người cao tuổi nào.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_isLoadingMedications)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_medicationSchedules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Chưa có lịch uống thuốc.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (filteredGroups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Không có lịch uống thuốc trong buổi này.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _medListScrollController,
                  child: SingleChildScrollView(
                    controller: _medListScrollController,
                    primary: false,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: filteredGroups.map((entry) {
                          final groupName = entry.key;
                          final meds = entry.value;
                          IconData groupIcon;
                          Color groupColor;
                          if (groupName == 'Buổi sáng') {
                            groupIcon = Icons.wb_sunny_rounded;
                            groupColor = const Color(0xFFD97706);
                          } else if (groupName == 'Buổi trưa/chiều') {
                            groupIcon = Icons.wb_cloudy_rounded;
                            groupColor = const Color(0xFF0EA5E9);
                          } else if (groupName == 'Buổi tối') {
                            groupIcon = Icons.nights_stay_rounded;
                            groupColor = const Color(0xFF4F46E5);
                          } else {
                            groupIcon = Icons.access_time_rounded;
                            groupColor = const Color(0xFF64748B);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        groupIcon,
                                        color: groupColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        groupName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: groupColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: groupColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${meds.length} liều',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: groupColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final maxShow = 6;
                                      final chips = <Widget>[];
                                      for (
                                        var i = 0;
                                        i < meds.length && i < maxShow;
                                        i++
                                      ) {
                                        final schedule = meds[i];
                                        final med =
                                            schedule['medication'] ?? {};
                                        final name =
                                            (med['name'] ?? 'Không tên')
                                                .toString();
                                        final time =
                                            (schedule['time'] ?? '--:--')
                                                .toString();
                                        chips.add(
                                          Container(
                                            width: 160,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: groupColor
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    time,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: groupColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Delete icon
                                                GestureDetector(
                                                  onTap: () async {
                                                    final doDelete = await showDialog<bool>(
                                                      context: context,
                                                      builder: (c) => AlertDialog(
                                                        title: const Text(
                                                          'Xác nhận',
                                                        ),
                                                        content: const Text(
                                                          'Bạn có chắc muốn xóa lịch uống thuốc này?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  c,
                                                                ).pop(false),
                                                            child: const Text(
                                                              'Hủy',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  c,
                                                                ).pop(true),
                                                            child: const Text(
                                                              'Xóa',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFFD97706,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (doDelete == true) {
                                                      final scheduleId =
                                                          schedule['id'] ??
                                                          schedule['schedule_id'] ??
                                                          schedule['scheduleId'];
                                                      bool ok = false;
                                                      if (scheduleId != null) {
                                                        try {
                                                          ok = await ApiService.deleteMedication(
                                                            int.parse(
                                                              scheduleId
                                                                  .toString(),
                                                            ),
                                                          );
                                                        } catch (_) {
                                                          ok = false;
                                                        }
                                                      }
                                                      setState(() {
                                                        _medicationSchedules.removeWhere(
                                                          (s) =>
                                                              identical(
                                                                s,
                                                                schedule,
                                                              ) ||
                                                              (s['id'] !=
                                                                      null &&
                                                                  scheduleId !=
                                                                      null &&
                                                                  s['id']
                                                                          .toString() ==
                                                                      scheduleId
                                                                          .toString()),
                                                        );
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            ok
                                                                ? 'Đã xóa'
                                                                : 'Đã xóa (cục bộ)',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFF1F2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 16,
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (meds.length > maxShow) {
                                        chips.add(
                                          Container(
                                            width: 80,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '+${meds.length - maxShow} thêm',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(children: chips),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                    ),
                    onPressed: () => MainNavigator.of(context)?.setTab(1),
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 18,
                    ),
                    label: const Text(
                      'Lịch sử uống',
                      style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _elderlyList.isEmpty
                        ? null
                        : () => MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: _loadElderlyDetails),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Thêm lịch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Thẻ Lịch khám & giấy tờ ──────────────────────────────────────────────
  Widget _buildAppointmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LỊCH KHÁM TIẾP THEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bệnh viện Chợ Rẫy',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '08:30 ngày 12/06',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Còn 3 ngày',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  radius: 18,
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BS. Nguyễn Thị Lan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Khoa Tim mạch',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: Color(0xFF0EA5E9)),
              ),
              onPressed: () {
                MainNavigator.of(
                  context,
                )?.setTab(1); // Chuyển sang tab Checklist
              },
              icon: const Icon(
                Icons.add_task_rounded,
                color: Color(0xFF0EA5E9),
                size: 18,
              ),
              label: const Text(
                'Chuẩn bị giấy tờ đi khám',
                style: TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Theo dõi sức khỏe ────────────────────────────────────────────────
  Widget _buildHealthTrackingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.monitor_heart_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theo dõi sức khỏe người cao tuổi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chỉ số sinh hiệu hôm nay',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Nút nhập chỉ số
                GestureDetector(
                  onTap: _selectedElderlyId == null
                      ? null
                      : _showInputMetricsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Nhập',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút refresh
                GestureDetector(
                  onTap: _loadElderlyDetails,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onPressed: () => MainNavigator.of(context)?.setTab(3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.heart_broken_rounded,
                    iconColor: Colors.red,
                    label: 'Huyết áp',
                    value: '$_bpSys/$_bpDia',
                    unit: ' mmHg',
                    status: _bpSys == '--'
                        ? 'Chưa đo'
                        : (int.tryParse(_bpSys) != null &&
                                  int.parse(_bpSys) > 130
                              ? 'Hơi cao'
                              : 'Bình thường'),
                    statusColor: _bpSys == '--'
                        ? Colors.grey
                        : (int.tryParse(_bpSys) != null &&
                                  int.parse(_bpSys) > 130
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A)),
                    statusBg: _bpSys == '--'
                        ? Colors.grey.shade200
                        : (int.tryParse(_bpSys) != null &&
                                  int.parse(_bpSys) > 130
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blue,
                    label: 'Đường huyết',
                    value: _bloodSugar,
                    unit: ' mmol/L',
                    status: _bloodSugar == '--' ? 'Chưa đo' : 'Ổn định',
                    statusColor: _bloodSugar == '--'
                        ? Colors.grey
                        : const Color(0xFF16A34A),
                    statusBg: _bloodSugar == '--'
                        ? Colors.grey.shade200
                        : const Color(0xFFDCFCE7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.favorite_rounded,
                    iconColor: Colors.pinkAccent,
                    label: 'Nhịp tim',
                    value: _heartRate,
                    unit: ' bpm',
                    status: _heartRate == '--' ? 'Chưa đo' : 'Bình thường',
                    statusColor: _heartRate == '--'
                        ? Colors.grey
                        : const Color(0xFF16A34A),
                    statusBg: _heartRate == '--'
                        ? Colors.grey.shade200
                        : const Color(0xFFDCFCE7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.thermostat_rounded,
                    iconColor: Colors.orange,
                    label: 'Nhiệt độ',
                    value: _temperature,
                    unit: ' °C',
                    status: _temperature == '--' ? 'Chưa đo' : 'Bình thường',
                    statusColor: _temperature == '--'
                        ? Colors.grey
                        : const Color(0xFF16A34A),
                    statusBg: _temperature == '--'
                        ? Colors.grey.shade200
                        : const Color(0xFFDCFCE7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => MainNavigator.of(context)?.setTab(3),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem phân tích chi tiết chỉ số',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.trending_up_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet nhập chỉ số sức khỏe cho elderly ────────────────────────
  void _showInputMetricsSheet() {
    if (_selectedElderlyId == null) return;

    final bpSysCtrl = TextEditingController(text: _bpSys == '--' ? '' : _bpSys);
    final bpDiaCtrl = TextEditingController(text: _bpDia == '--' ? '' : _bpDia);
    final heartCtrl = TextEditingController(
      text: _heartRate == '--' ? '' : _heartRate,
    );
    final sugarCtrl = TextEditingController(
      text: _bloodSugar == '--' ? '' : _bloodSugar,
    );
    final tempCtrl = TextEditingController(
      text: _temperature == '--' ? '' : _temperature,
    );

    final elderlyName =
        _elderlyList.firstWhere(
          (e) => e['id'] == _selectedElderlyId,
          orElse: () => {'fullname': 'người cao tuổi'},
        )['fullname'] ??
        'người cao tuổi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom +
              24 +
              MediaQuery.of(ctx).padding.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nhập chỉ số sức khỏe',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Cho: $elderlyName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Huyết áp
              const _FieldLabel(label: 'Huyết áp (mmHg)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _metricsInputField(
                      'Tâm thu',
                      bpSysCtrl,
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _metricsInputField(
                      'Tâm trương',
                      bpDiaCtrl,
                      Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FieldLabel(label: 'Nhịp tim (bpm)'),
              const SizedBox(height: 8),
              _metricsInputField(
                'Nhịp tim',
                heartCtrl,
                Icons.favorite_border_rounded,
              ),
              const SizedBox(height: 14),
              const _FieldLabel(label: 'Đường huyết (mmol/L)'),
              const SizedBox(height: 8),
              _metricsInputField(
                'Đường huyết',
                sugarCtrl,
                Icons.water_drop_outlined,
              ),
              const SizedBox(height: 14),
              const _FieldLabel(label: 'Nhiệt độ (°C)'),
              const SizedBox(height: 8),
              _metricsInputField(
                'Nhiệt độ',
                tempCtrl,
                Icons.thermostat_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final bpSys = bpSysCtrl.text.trim();
                    final bpDia = bpDiaCtrl.text.trim();
                    final heart = heartCtrl.text.trim();
                    final sugar = sugarCtrl.text.trim();
                    final temperature = tempCtrl.text.trim();

                    if (bpSys.isEmpty &&
                        heart.isEmpty &&
                        sugar.isEmpty &&
                        temperature.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập ít nhất một chỉ số'),
                        ),
                      );
                      return;
                    }

                    final ok = await ApiService.addHealthMetric(
                      elderlyId: _selectedElderlyId!,
                      heartRate: int.tryParse(heart),
                      bloodPressure: (bpSys.isNotEmpty && bpDia.isNotEmpty)
                          ? '$bpSys/$bpDia'
                          : null,
                      bloodSugar: double.tryParse(sugar),
                      temperature: double.tryParse(temperature),
                    );

                    if (context.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (ok) {
                      // Reload data
                      _loadElderlyDetails();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('✓ Đã lưu chỉ số sức khỏe!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lưu chỉ số thất bại, vui lòng thử lại',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Lưu chỉ số',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricsInputField(
    String hint,
    TextEditingController ctrl,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
        filled: true,
        fillColor: const Color(0xFFF0F9FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Thêm người cao tuổi ─────────────────────────────────────────────
  Widget _buildAddElderlyCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _showAddElderlyDialog,
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thêm người cao tuổi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tạo hồ sơ & sinh mã QR đăng nhập',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog Thêm người cao tuổi ────────────────────────────────────────────
  void _showAddElderlyDialog() {
    final fullnameCtrl = TextEditingController();
    final medicalNoteCtrl = TextEditingController();
    String? selectedGender;
    DateTime? selectedDob;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: DateTime(now.year - 65),
              firstDate: DateTime(1920),
              lastDate: DateTime(now.year - 40),
              helpText: 'Chọn ngày sinh',
              locale: const Locale('vi'),
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDialogState(() => selectedDob = picked);
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF7C3AED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm người cao tuổi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Điền thông tin để tạo hồ sơ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Họ và tên
                  const _FieldLabel(label: 'Họ và tên *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fullnameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: Nguyễn Văn An',
                      icon: Icons.badge_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ngày sinh
                  const _FieldLabel(label: 'Ngày sinh *'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_rounded,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDob != null
                                ? '${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}'
                                : 'Chọn ngày sinh',
                            style: TextStyle(
                              fontSize: 15,
                              color: selectedDob != null
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Giới tính
                  const _FieldLabel(label: 'Giới tính *'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderButton(
                          label: 'Nam',
                          icon: Icons.male_rounded,
                          isSelected: selectedGender == 'Nam',
                          onTap: () =>
                              setDialogState(() => selectedGender = 'Nam'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GenderButton(
                          label: 'Nữ',
                          icon: Icons.female_rounded,
                          isSelected: selectedGender == 'Nữ',
                          onTap: () =>
                              setDialogState(() => selectedGender = 'Nữ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ghi chú y tế
                  const _FieldLabel(label: 'Ghi chú y tế (tùy chọn)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: medicalNoteCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: Tiểu đường, huyết áp cao, dị ứng...',
                      icon: Icons.medical_information_rounded,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final name = fullnameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng nhập họ và tên'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (selectedDob == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng chọn ngày sinh'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (selectedGender == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng chọn giới tính'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setDialogState(() => isLoading = true);
                              final dob =
                                  '${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}';
                              final result = await ApiService.createElderly(
                                fullname: name,
                                dob: dob,
                                gender: selectedGender!,
                                medicalNote: medicalNoteCtrl.text.trim(),
                              );
                              setDialogState(() => isLoading = false);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (result['success'] == true) {
                                final qrToken =
                                    result['qr_token'] as String? ?? '';
                                _showQrCodeDialog(
                                  elderlyName: name,
                                  qrToken: qrToken,
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['error'] ??
                                          'Có lỗi xảy ra. Vui lòng thử lại.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tạo hồ sơ & Sinh mã QR',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dialog hiển thị QR code ────────────────────────────────────────────────
  void _showQrCodeDialog({
    required String elderlyName,
    required String qrToken,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tạo hồ sơ thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                elderlyName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cho người cao tuổi quét mã QR bên dưới để đăng nhập vào ứng dụng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrImageKey,
                      child: QrImageView(
                        data: qrToken,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF7C3AED),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_rounded,
                            size: 14,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            qrToken.length > 18
                                ? '${qrToken.substring(0, 18)}...'
                                : qrToken,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7C3AED),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Save QR image button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _saveQrAsImage(qrToken),
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: const Text(
                  'Lưu ảnh QR về máy',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // Tự động lưu ảnh QR vào máy sau khi tạo hồ sơ
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (mounted) await _saveQrAsImage(qrToken);
                  },
                  child: const Text(
                    'Hoàn tất & Lưu QR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQrAsImage(String qrToken) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tính năng lưu ảnh QR chỉ hỗ trợ trên thiết bị di động.',
          ),
        ),
      );
      return;
    }

    // Request platform-appropriate permissions
    if (Platform.isAndroid) {
      final statuses = await [Permission.storage, Permission.photos].request();
      final storageGranted = (statuses[Permission.storage]?.isGranted ?? false);
      final photosGranted = (statuses[Permission.photos]?.isGranted ?? false);
      if (!storageGranted && !photosGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền lưu ảnh bị từ chối. Vui lòng cho phép quyền bộ nhớ.',
            ),
          ),
        );
        return;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền lưu ảnh bị từ chối. Vui lòng cho phép quyền ảnh.',
            ),
          ),
        );
        return;
      }
    }

    try {
      final boundary = _qrImageKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw Exception('Không thể tạo ảnh từ QR');
      }
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Không lấy được dữ liệu ảnh');
      }

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(byteData.buffer.asUint8List()),
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );
      if (result['isSuccess'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Đã lưu ảnh QR về thư viện.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu ảnh QR không thành công.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu ảnh QR: $e')));
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ════════════════════════════════════════════════════════════════════════════

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    _buildNotifItem(
                      icon: Icons.calendar_today_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Lịch tái khám sắp tới',
                      body:
                          'Ngày 12/06 lúc 08:30 — BV Chợ Rẫy, BS. Nguyễn Thị Lan (Tim mạch). Còn 3 ngày nữa.',
                      time: '2 giờ trước',
                    ),
                    _buildNotifItem(
                      icon: Icons.medication_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Đã uống thuốc buổi sáng',
                      body:
                          'Bác đã xác nhận uống Amlodipine 5mg và Atorvastatin 20mg lúc 07:15.',
                      time: '5 giờ trước',
                    ),
                    _buildNotifItem(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Bỏ lỡ thuốc buổi trưa',
                      body:
                          'Bác chưa xác nhận uống Metformin 500mg lúc 12:00. Hệ thống đã gửi nhắc nhở.',
                      time: 'Hôm qua',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicationChoiceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thêm lịch uống thuốc mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7)),
              ),
              title: const Text(
                'Quét từ đơn thuốc (OCR)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tự động nhận diện qua ảnh chụp'),
              onTap: () {
                Navigator.pop(ctx);
                MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: _loadElderlyDetails);
              },
            ),
            const Divider(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.edit_note_rounded, color: Color(0xFFD97706)),
              ),
              title: const Text(
                'Nhập thủ công',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tự nhập thông tin thuốc'),
              onTap: () {
                Navigator.pop(ctx);
                MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: _loadElderlyDetails);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showScanPrescriptionDialog() async {
    final bool isWeb = kIsWeb;
    final ImageSource? imageSource = isWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn ảnh đơn thuốc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF0284C7),
                    ),
                    title: const Text(
                      'Chụp ảnh mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Sử dụng camera để chụp đơn thuốc'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFF10B981),
                    ),
                    title: const Text(
                      'Chọn từ thư viện',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Chọn ảnh đã có trong điện thoại'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );

    if (imageSource == null) return;
    if (isWeb && imageSource == ImageSource.camera) {
      _showScanErrorDialog(
        'Không thể chụp ảnh trực tiếp trên Web. Vui lòng chọn ảnh từ thư viện.',
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: imageSource,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Color(0xFF0284C7),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Đang quét đơn thuốc...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vui lòng giữ máy ổn định và chờ trong giây lát",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(color: Color(0xFF0F605A)),
          ],
        ),
      ),
    );

    final res = await ApiService.scanPrescription(image);
    if (!mounted) return;
    Navigator.pop(context);

    if (res['error'] != null) {
      _showScanErrorDialog(res['error'] as String);
      return;
    }

    final medications = (res['medications'] ?? res['results']) as List?;
    final appointment = res['appointment'] as Map<String, dynamic>?;

    if ((medications != null && medications.isNotEmpty) ||
        appointment != null) {
      _showScannedResultsDialog(medications ?? [], appointment: appointment);
    } else {
      _showScanErrorDialog(
        'Không tìm thấy thông tin trong ảnh. Vui lòng thử chụp lại hoặc nhập thủ công.',
      );
    }
  }

  void _showScanErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quét đơn thuốc không thành công',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F605A),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: _loadElderlyDetails);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  String _sessionLabelForTime(String time) {
    if (time.startsWith('07') ||
        time.startsWith('08') ||
        time.startsWith('09') ||
        time.startsWith('10') ||
        time.startsWith('11')) {
      return 'Sáng';
    }
    if (time.startsWith('12') ||
        time.startsWith('13') ||
        time.startsWith('14') ||
        time.startsWith('15') ||
        time.startsWith('16')) {
      return 'Trưa';
    }
    if (time.startsWith('17') ||
        time.startsWith('18') ||
        time.startsWith('19') ||
        time.startsWith('20')) {
      return 'Chiều';
    }
    return 'Tối';
  }

  String _defaultTimeForSession(String session) {
    switch (session) {
      case 'Sáng':
        return '08:00';
      case 'Trưa':
        return '12:00';
      case 'Chiều':
        return '18:00';
      case 'Tối':
      default:
        return '20:00';
    }
  }

  void _showScannedResultsDialog(
    List results, {
    Map<String, dynamic>? appointment,
  }) {
    final List<Map<String, dynamic>> editableResults = results
        .map<Map<String, dynamic>>((item) {
          final originalTime = item['time']?.toString() ?? '';
          final session = _sessionLabelForTime(originalTime);
          return {
            'nameController': TextEditingController(text: item['name'] ?? ''),
            'dosageController': TextEditingController(
              text: item['dosage'] ?? '',
            ),
            'frequencyController': TextEditingController(
              text:
                  item['frequency']?.toString() ??
                  item['times_per_day']?.toString() ??
                  '',
            ),
            'time': originalTime.isNotEmpty
                ? originalTime
                : _defaultTimeForSession(session),
            'session': session,
            'daysController': TextEditingController(
              text: item['days']?.toString() ?? '',
            ),
            'noteController': TextEditingController(
              text: item['note'] ?? item['instruction'] ?? '',
            ),
          };
        })
        .toList();

    final Map<String, TextEditingController>? appointmentFields =
        appointment != null
        ? <String, TextEditingController>{
            'clinicController': TextEditingController(
              text: appointment['clinic'] ?? '',
            ),
            'doctorController': TextEditingController(
              text: appointment['doctor_name'] ?? '',
            ),
            'addressController': TextEditingController(
              text: appointment['address'] ?? '',
            ),
            'phoneController': TextEditingController(
              text: appointment['phone'] ?? '',
            ),
            'dateController': TextEditingController(
              text: appointment['appointment_date'] ?? '',
            ),
            'timeController': TextEditingController(
              text: appointment['appointment_time'] ?? '',
            ),
            'noteController': TextEditingController(
              text: appointment['note'] ?? '',
            ),
          }
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Widget buildSessionChips(int index) {
              final sessionOptions = ['Sáng', 'Trưa', 'Chiều', 'Tối'];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sessionOptions.map((option) {
                  final isSelected =
                      editableResults[index]['session'] == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDCFCE7),
                    backgroundColor: const Color(0xFFF8FAFC),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF047857)
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setStateModal(() {
                          editableResults[index]['session'] = option;
                          editableResults[index]['time'] =
                              _defaultTimeForSession(option);
                        });
                      }
                    },
                  );
                }).toList(),
              );
            }

            Widget buildMedicationCard(int index) {
              final item = editableResults[index];
              return Card(
                elevation: 0,
                color: const Color(0xFFEFF6FF),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFBFDBFE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: item['nameController'],
                              decoration: const InputDecoration(
                                labelText: 'Tên thuốc',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item['dosageController'],
                              decoration: const InputDecoration(
                                labelText: 'Liều lượng mỗi lần',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: item['frequencyController'],
                              decoration: const InputDecoration(
                                labelText: 'Số lần/ngày',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: item['daysController'],
                        decoration: const InputDecoration(
                          labelText: 'Số ngày dùng thuốc',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: item['noteController'],
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú cách dùng',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Buổi uống',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildSessionChips(index),
                    ],
                  ),
                ),
              );
            }

            Widget buildAppointmentCard() {
              if (appointmentFields == null) {
                return Card(
                  elevation: 0,
                  color: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Lịch tái khám',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Không phát hiện lịch tái khám trong đơn. Bạn có thể thêm sau.',
                          style: TextStyle(color: Color(0xFF7C2D12)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                elevation: 0,
                color: const Color(0xFFFFF7ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch tái khám',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: appointmentFields['clinicController'],
                        decoration: const InputDecoration(
                          labelText: 'Phòng khám / Bệnh viện',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: appointmentFields['doctorController'],
                        decoration: const InputDecoration(
                          labelText: 'Bác sĩ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: appointmentFields['dateController'],
                        decoration: const InputDecoration(
                          labelText: 'Ngày tái khám',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: appointmentFields['timeController'],
                        decoration: const InputDecoration(
                          labelText: 'Giờ tái khám',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: appointmentFields['noteController'],
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú lịch khám',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: Row(
                children: [
                  const Icon(
                    Icons.document_scanner_rounded,
                    color: Color(0xFF0F605A),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Kết quả quét đơn thuốc',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF0F605A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 520,
                child: isSaving
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF0F605A)),
                            SizedBox(height: 16),
                            Text(
                              'Đang lưu thông tin...',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          if (editableResults.isNotEmpty)
                            ...editableResults.asMap().entries.map((entry) {
                              final idx = entry.key;
                              return buildMedicationCard(idx);
                            }),
                          const SizedBox(height: 8),
                          buildAppointmentCard(),
                        ],
                      ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isSaving)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F605A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      if (_selectedElderlyId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn người cao tuổi trước'),
                          ),
                        );
                        return;
                      }

                      setStateModal(() => isSaving = true);

                      int successCount = 0;
                      for (var item in editableResults) {
                        final name = item['nameController']?.text.trim() ?? '';
                        if (name.isEmpty) continue;
                        final dosage =
                            item['dosageController']?.text.trim() ?? '';
                        final instruction =
                            item['noteController']?.text.trim() ?? '';
                        final time = item['time']?.toString() ?? '08:00';
                        final frequency =
                            item['frequencyController']?.text.trim() ?? '';

                        final success = await ApiService.addMedication(
                          elderlyId: _selectedElderlyId!,
                          name: name,
                          dosage: dosage,
                          instruction: instruction,
                          time: time,
                          frequency: frequency.isNotEmpty
                              ? frequency
                              : 'Hàng ngày',
                        );
                        if (success) successCount++;
                      }

                      bool appointmentSaved = false;
                      if (appointmentFields != null) {
                        appointmentSaved = await ApiService.createAppointment(
                          elderlyId: _selectedElderlyId!,
                          doctorName:
                              appointmentFields['doctorController']?.text
                                  .trim() ??
                              '',
                          location:
                              appointmentFields['clinicController']?.text
                                  .trim() ??
                              '',
                          appointmentDate:
                              appointmentFields['dateController']?.text
                                  .trim() ??
                              '',
                          appointmentTime:
                              appointmentFields['timeController']?.text
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? appointmentFields['timeController']?.text
                                        .trim() ??
                                    '08:00'
                              : '08:00',
                          note:
                              appointmentFields['noteController']?.text
                                  .trim() ??
                              '',
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (successCount == 0 && !appointmentSaved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không có dữ liệu hợp lệ để lưu.'),
                          ),
                        );
                      } else {
                        final apptMsg = appointmentSaved
                            ? ' + Lịch tái khám'
                            : '';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text(
                              '✓ Đã lưu $successCount thuốc$apptMsg!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                      _loadElderlyDetails();
                    },
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(
                      'Lưu tất cả',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF92400E)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF92400E),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
          ),
        ),
      ],
    );
  }

  


  void _showEditDeleteMedicationDialog(dynamic schedule) {
    final med = schedule['medication'] ?? {};

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${med['name'] ?? 'Thuốc'} — ${schedule['time']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${med['instruction'] ?? ''} · ${med['dosage'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              title: const Text(
                'Chỉnh sửa lịch uống',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final scheduleId = schedule['schedule_id'] ?? schedule['id'];
                MedicationDialogHelper.showAddMedicationDialog(
                  context: context,
                  elderlyId: _selectedElderlyId!,
                  onSuccess: _loadElderlyDetails,
                  initialName: med['name'],
                  initialDosage: med['dosage'],
                  initialInstruction: med['instruction'],
                  initialTime: schedule['time'],
                  initialDescription: med['description'],
                  editScheduleId: scheduleId != null
                      ? int.tryParse(scheduleId.toString())
                      : null,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              title: const Text(
                'Xóa lịch uống thuốc',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              onTap: () async {
                final ok = await ApiService.deleteMedication(
                  schedule['schedule_id'],
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa thành công.')),
                    );
                    _loadElderlyDetails();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi xóa.')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


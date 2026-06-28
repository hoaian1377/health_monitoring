import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../utils/api_service.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  bool _showMissedMedsAlert = true;

  // Medication Management State
  List<Map<String, dynamic>> _elderlyList = [];
  int? _selectedElderlyId;
  List<dynamic> _medicationSchedules = [];
  bool _isLoadingMedications = false;

  @override
  void initState() {
    super.initState();
    _loadElderlyData();
  }

  Future<void> _loadElderlyData() async {
    final result = await ApiService.getElderlyList();
    if (mounted && result['success'] == true) {
      final list = (result['elderly_list'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _elderlyList = list;
        if (list.isNotEmpty) {
          _selectedElderlyId = list.first['id'] as int;
          _loadMedicationSchedule();
        }
      });
    }
  }

  Future<void> _loadMedicationSchedule() async {
    if (_selectedElderlyId == null) return;
    setState(() => _isLoadingMedications = true);
    final schedules = await ApiService.getElderlyMedicationSchedule(_selectedElderlyId!);
    if (mounted) {
      setState(() {
        _medicationSchedules = schedules;
        _isLoadingMedications = false;
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
                  if (_showMissedMedsAlert) ...[
                    _buildMissedMedsAlert(),
                    const SizedBox(height: 16),
                  ],
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

  // ── Cảnh báo bỏ lỡ thuốc (xem từ góc caregiver) ──────────────────────────
  Widget _buildMissedMedsAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bỏ lỡ giờ uống thuốc — Đã báo người thân',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thuốc huyết áp Amlodipine lúc 07:00 chưa được xác nhận. Hệ thống đã tự động gửi tin nhắn.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _showMissedMedsAlert = false;
                  }),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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

    final int totalMeds = _medicationSchedules.length;
    // Mock progress for UI demonstration (e.g., assuming morning meds are taken)
    final int takenMeds = groupedMeds['Buổi sáng']!.length;
    final double progress = totalMeds > 0 ? (takenMeds / totalMeds) : 0;
    final bool allDone = totalMeds > 0 && takenMeds >= totalMeds;

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
                      child: Icon(Icons.medication_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quản lý Lịch uống thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Thiết lập & Theo dõi việc uống thuốc', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (_elderlyList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedElderlyId,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
                      underline: const SizedBox(),
                      isDense: true,
                      items: _elderlyList.map((e) {
                        return DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(e['fullname'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedElderlyId = val);
                          _loadMedicationSchedule();
                        }
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (totalMeds > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tiến trình hôm nay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  Text('$takenMeds/$totalMeds liều', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: allDone ? Color(0xFF059669) : Color(0xFF0284C7))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone ? const Color(0xFF059669) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Medication List
            if (_elderlyList.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("Chưa có người cao tuổi nào.", style: TextStyle(color: Colors.grey))))
            else if (_isLoadingMedications)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_medicationSchedules.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có lịch uống thuốc.", style: TextStyle(color: Colors.grey))))
            else
              ...groupedMeds.entries.where((e) => e.value.isNotEmpty).map((entry) {
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(groupIcon, color: groupColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          groupName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: groupColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Divider(color: groupColor.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...meds.map((schedule) {
                      final med = schedule['medication'] ?? {};
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                schedule['time'] ?? '--:--',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med['name'] ?? 'Không tên', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text('${med['instruction'] ?? ''} · ${med['dosage'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => _showEditDeleteMedicationDialog(schedule),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                    ),
                    onPressed: () => MainNavigator.of(context)?.setTab(1),
                    icon: const Icon(Icons.history_rounded, color: Color(0xFF0EA5E9), size: 18),
                    label: const Text('Lịch sử uống', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _elderlyList.isEmpty ? null : _showMedicationChoiceDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm lịch', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        const Text(
                          '08:30 ngày 12/06',
                          style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Còn 3 ngày', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
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
                  child: Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BS. Nguyễn Thị Lan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      Text('Khoa Tim mạch', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
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
                MainNavigator.of(context)?.setTab(1); // Chuyển sang tab Checklist
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
                    value: '128/82',
                    unit: ' mmHg',
                    status: 'Hơi cao',
                    statusColor: const Color(0xFFD97706),
                    statusBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blue,
                    label: 'Đường huyết',
                    value: '5.8',
                    unit: ' mmol/L',
                    status: 'Ổn định',
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
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
                    value: '76',
                    unit: ' bpm',
                    status: 'Bình thường',
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.thermostat_rounded,
                    iconColor: Colors.orange,
                    label: 'Nhiệt độ',
                    value: '36.5',
                    unit: ' °C',
                    status: 'Bình thường',
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
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
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                        ),
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
                    QrImageView(
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
              // Copy token button
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
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrToken));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Đã sao chép mã QR vào clipboard'),
                      backgroundColor: Color(0xFF7C3AED),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(
                  'Sao chép mã token',
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
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        borderSide:
            const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              title: const Text('Quét từ đơn thuốc (OCR)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tự động nhận diện qua ảnh chụp'),
              onTap: () {
                Navigator.pop(ctx);
                _showScanPrescriptionDialog();
              },
            ),
            const Divider(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.edit_note_rounded, color: Color(0xFFD97706)),
              ),
              title: const Text('Nhập thủ công', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tự nhập thông tin thuốc'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMedicationDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showScanPrescriptionDialog() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!mounted) return;

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
              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
              child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF0284C7), size: 40),
            ),
            const SizedBox(height: 20),
            const Text("Đang phân tích đơn thuốc...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("AI đang đọc thông tin thuốc và lịch khám", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            const LinearProgressIndicator(color: Color(0xFF0F605A)),
          ],
        ),
      ),
    );

    final res = await ApiService.scanPrescription(image.path);
    if (!mounted) return;
    Navigator.pop(context);

    // Support both old key 'results' and new key 'medications'
    final medications = (res['medications'] ?? res['results']) as List?;
    final appointment = res['appointment'] as Map<String, dynamic>?;

    if ((medications != null && medications.isNotEmpty) || appointment != null) {
      _showScannedResultsDialog(medications ?? [], appointment: appointment);
    } else if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Lỗi quét ảnh, vui lòng nhập thủ công.')),
      );
      _showAddMedicationDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin trong ảnh.')),
      );
    }
  }

  void _showScannedResultsDialog(List results, {Map<String, dynamic>? appointment}) {
    // Group medications by time (Buổi)
    final Map<String, List<dynamic>> groupedResults = {};
    for (var item in results) {
      final t = item['time'] ?? '08:00';
      if (!groupedResults.containsKey(t)) groupedResults[t] = [];
      groupedResults[t]!.add(item);
    }
    
    // Sort times
    final sortedTimes = groupedResults.keys.toList()..sort();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateModal) {

            Widget buildMedicationCard(dynamic item) => Card(
              elevation: 0,
              color: const Color(0xFFEFF6FF),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFBFDBFE), shape: BoxShape.circle),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFF1D4ED8), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F))),
                          const SizedBox(height: 3),
                          Text('${item['dosage'] ?? ''} · ${item['instruction'] ?? ''}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            Widget buildAppointmentCard() {
              if (appointment == null) return const SizedBox.shrink();
              return Card(
                elevation: 0,
                color: const Color(0xFFFFF7ED),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFED7AA), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFFEA580C), size: 20),
                        const SizedBox(width: 8),
                        const Text('Lịch tái khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFEA580C))),
                      ]),
                      const Divider(height: 16, color: Color(0xFFFED7AA)),
                      _infoRow(Icons.local_hospital_rounded, 'Phòng khám', appointment['clinic'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.person_rounded, 'Bác sĩ', appointment['doctor_name'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.location_on_rounded, 'Địa chỉ', appointment['address'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.phone_rounded, 'SĐT', appointment['phone'] ?? ''),
                      const SizedBox(height: 6),
                      _infoRow(Icons.event_rounded, 'Ngày', '${appointment['appointment_date'] ?? ''} lúc ${appointment['appointment_time'] ?? ''}'),
                      if ((appointment['note'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _infoRow(Icons.info_outline_rounded, 'Lưu ý', appointment['note'] ?? ''),
                      ],
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: Row(children: [
                const Icon(Icons.document_scanner_rounded, color: Color(0xFF0F605A)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Kết quả nhận diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F605A)))),
              ]),
              content: SizedBox(
                width: double.maxFinite,
                height: 480,
                child: isSaving
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF0F605A)),
                            SizedBox(height: 16),
                            Text('Đang lưu thuốc và lịch khám...', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          if (results.isNotEmpty)
                            ...sortedTimes.map((t) {
                              String sessionName = t == '08:00' ? 'Buổi sáng' : (t == '12:00' ? 'Buổi trưa' : (t == '19:00' ? 'Buổi chiều' : 'Khác'));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 16, color: Color(0xFF059669)),
                                        const SizedBox(width: 6),
                                        Text('$sessionName ($t)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF059669))),
                                      ],
                                    ),
                                  ),
                                  ...groupedResults[t]!.map((item) => buildMedicationCard(item)),
                                ],
                              );
                            }),
                          if (appointment != null) ...[
                            const SizedBox(height: 12),
                            buildAppointmentCard(),
                          ],
                        ],
                      ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                if (!isSaving)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F605A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      if (_selectedElderlyId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn người cao tuổi trước')));
                        return;
                      }

                      setStateModal(() => isSaving = true);

                      int successCount = 0;
                      for (var item in results) {
                        final success = await ApiService.addMedication(
                          elderlyId: _selectedElderlyId!,
                          name: item['name'] ?? '',
                          dosage: item['dosage'] ?? '',
                          instruction: item['instruction'] ?? '',
                          time: item['time'] ?? '08:00',
                          frequency: 'Hàng ngày', // Unified frequency for the session
                        );
                        if (success) successCount++;
                      }

                      bool appointmentSaved = false;
                      if (appointment != null) {
                        final loc = '${appointment['clinic'] ?? ''} - ${appointment['address'] ?? ''}';
                        appointmentSaved = await ApiService.createAppointment(
                          elderlyId: _selectedElderlyId!,
                          doctorName: appointment['doctor_name'] ?? '',
                          location: loc,
                          appointmentDate: appointment['appointment_date'] ?? '',
                          appointmentTime: appointment['appointment_time'] ?? '08:00',
                          note: appointment['note'] ?? '',
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      final apptMsg = appointmentSaved ? ' + Lịch tái khám' : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('✓ Đã lưu $successCount thuốc$apptMsg!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );

                      _loadMedicationSchedule();
                    },
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Lưu tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)))),
      ],
    );
  }
  void _showAddMedicationDialog({
    String? initialName,
    String? initialDosage,
    String? initialInstruction,
    String? initialTime,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final doseCtrl = TextEditingController(text: initialDosage);
    final instructionCtrl = TextEditingController(text: initialInstruction);
    String selectedTime = initialTime ?? '07:00';
    
    final timeOptions = ['07:00', '12:00', '20:00', '22:00'];
    if (!timeOptions.contains(selectedTime)) {
      timeOptions.add(selectedTime);
    }

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_circle_rounded, color: Color(0xFF0EA5E9), size: 24),
              SizedBox(width: 10),
              Text('Thêm thuốc', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên thuốc',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doseCtrl,
                  decoration: InputDecoration(
                    labelText: 'Liều dùng',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cách dùng (vd: Uống sau ăn)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: InputDecoration(
                    labelText: 'Thời gian uống',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF0EA5E9)),
                  ),
                  items: timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedTime = v ?? selectedTime),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSubmitting ? null : () async {
                setDialogState(() => isSubmitting = true);
                final ok = await ApiService.addMedication(
                  elderlyId: _selectedElderlyId!,
                  name: nameCtrl.text,
                  dosage: doseCtrl.text,
                  instruction: instructionCtrl.text,
                  time: selectedTime,
                  frequency: 'Hàng ngày'
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('Đã thêm thuốc thành công!')));
                    _loadMedicationSchedule();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi thêm thuốc.')));
                  }
                }
              },
              child: isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              title: const Text('Chỉnh sửa lịch uống', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMedicationDialog(
                  initialName: med['name'],
                  initialDosage: med['dosage'],
                  initialInstruction: med['instruction'],
                  initialTime: schedule['time'],
                );
                // In a full implementation, this should call an Update API rather than Add API.
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: const Text('Xóa lịch uống thuốc', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              onTap: () async {
                final ok = await ApiService.deleteMedication(schedule['schedule_id']);
                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công.')));
                    _loadMedicationSchedule();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi xóa.')));
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
          color: isSelected
              ? const Color(0xFF7C3AED)
              : const Color(0xFFF8FAFC),
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

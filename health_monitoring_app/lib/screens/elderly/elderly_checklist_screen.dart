import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/api_service.dart';


class ElderlyTaskItem {
  final String id;
  String title;
  String type; // 'medication' | 'measurement' | 'habit' | 'symptom' | 'document'
  String time;
  String details;
  bool isCompleted;

  // Thuộc tính chi tiết cho thuốc
  String? medCode;
  String? dosage;
  int? dosesPerDay;
  String? startDate;
  String? endDate;
  String? frequency;
  String? instruction;
  String? description;

  // Thuộc tính tái khám
  String? hospital;
  String? doctor;
  String? appointmentDate;

  ElderlyTaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.details,
    this.isCompleted = false,
    this.medCode,
    this.dosage,
    this.dosesPerDay,
    this.startDate,
    this.endDate,
    this.frequency,
    this.instruction,
    this.description,
    this.hospital,
    this.doctor,
    this.appointmentDate,
  });
}

class ElderlyChecklistScreen extends StatefulWidget {
  const ElderlyChecklistScreen({super.key});

  @override
  State<ElderlyChecklistScreen> createState() =>
      _ElderlyChecklistScreenState();
}

class _ElderlyChecklistScreenState extends State<ElderlyChecklistScreen> {
  final List<ElderlyTaskItem> _tasks = [];
  List<dynamic> _medicationSchedules = [];
  bool _isLoading = false;

  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      if (dateStr.length >= 10) dateStr = dateStr.substring(0, 10);
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      // ignore
    }
    return dateStr ?? '';
  }

  bool _isMedicationTaken(int scheduleId, DateTime date) {
    final s = _medicationSchedules.firstWhere((item) => item['schedule_id'] == scheduleId, orElse: () => null);
    if (s == null) return false;
    final med = s['medication'] ?? {};
    final description = med['description']?.toString() ?? '';
    if (description.contains('· dose_history:')) {
      final parts = description.split('· dose_history:');
      final jsonStr = parts[1].trim();
      try {
        final list = jsonDecode(jsonStr) as List;
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final timeStr = s['time']?.toString() ?? '';
        return list.any((item) =>
          item['date'].toString().startsWith(dateStr) &&
          item['time'] == timeStr &&
          item['taken'] == true
        );
      } catch (e) {
        debugPrint("Error parsing dose history: $e");
      }
    }
    return false;
  }

  Future<void> _toggleMedicationTaken(int scheduleId, DateTime date, String medName) async {
    final s = _medicationSchedules.firstWhere((item) => item['schedule_id'] == scheduleId, orElse: () => null);
    if (s == null) return;
    final med = s['medication'] ?? {};
    final String description = med['description']?.toString() ?? '';
    
    // Extract existing dose history
    List<dynamic> historyList = [];
    String baseDesc = description;
    if (description.contains('· dose_history:')) {
      final parts = description.split('· dose_history:');
      baseDesc = parts[0].trim();
      try {
        historyList = jsonDecode(parts[1].trim()) as List;
      } catch (_) {}
    } else if (description.isEmpty) {
      baseDesc = 'Nhóm: Khác · Tổng số viên thuốc: 30';
    }
    
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = s['time']?.toString() ?? '';
    
    // Find if already recorded
    final idx = historyList.indexWhere((item) =>
      item['date'].toString().startsWith(dateStr) &&
      item['time'] == timeStr
    );
    
    bool isTaken = true;
    if (idx >= 0) {
      final currentlyTaken = historyList[idx]['taken'] ?? false;
      isTaken = !currentlyTaken;
      historyList[idx]['taken'] = isTaken;
      historyList[idx]['takenAt'] = isTaken ? DateTime.now().toIso8601String() : null;
    } else {
      historyList.add({
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'time': timeStr,
        'taken': true,
        'takenAt': DateTime.now().toIso8601String(),
      });
    }
    
    // Construct new description
    final newDescription = '$baseDesc · dose_history: ${jsonEncode(historyList)}';
    
    // Save to backend
    final ok = await ApiService.updateMedication(
      scheduleId: scheduleId,
      name: med['name'] ?? '',
      dosage: med['dosage'] ?? '',
      instruction: med['instruction'] ?? '',
      time: s['time'] ?? '',
      frequency: s['frequency'] ?? '',
      description: newDescription,
      startDate: s['start_date'] ?? '',
      endDate: s['end_date'] ?? '',
    );
    
    if (ok) {
      _fetchMedications();
    }
  }

  Future<void> _toggleTaskCompletion(ElderlyTaskItem task) async {
    if (task.type == 'medication') {
      final scheduleId = int.tryParse(task.id);
      if (scheduleId != null) {
        await _toggleMedicationTaken(scheduleId, DateTime.now(), task.title);
      }
    } else {
      final newStatus = !task.isCompleted;
      setState(() {
        task.isCompleted = newStatus;
      });
      if (task.id.startsWith('chk_')) {
        final itemId = int.parse(task.id.replaceFirst('chk_', ''));
        await ApiService.updateChecklistItem(itemId, isComplete: newStatus);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('mock_doc_completed_${task.id}', newStatus);
      }
      _fetchMedications();
    }
  }

  Future<void> _fetchMedications() async {
    final targetElderlyId = ApiService.currentAccountId;
    if (targetElderlyId == null) return;

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    
    // Fetch checklists for this elderly (matching Caregiver's logic)
    final checklistsRes = await ApiService.getChecklists(targetElderlyId);
    List<dynamic> checklistItems = [];
    if (checklistsRes.isNotEmpty) {
      final defaultChecklist = checklistsRes.firstWhere(
          (c) => c['title'] == 'Nhiệm vụ hàng ngày',
          orElse: () => checklistsRes.first);
      final dailyChecklistId =
          defaultChecklist['checklistID'] ?? defaultChecklist['id'] ?? defaultChecklist['checklistid'];
      if (dailyChecklistId != null) {
        checklistItems = await ApiService.getChecklistItems(dailyChecklistId);
      }
    }

    if (mounted) {
      setState(() {
        _tasks.clear();

        // Add database checklist items
        for (var item in checklistItems) {
          String type = item['item_type'] ?? 'task';
          String time = item['time_string'] ?? 'Tùy lúc';
          String details = item['details'] ?? '';
          String id = 'chk_${item['checklist_itemid'] ?? item['checklist_itemID'] ?? item['id']}';

          // Skip if it's already medication (shouldn't happen, but just in case)
          if (type == 'medication') continue;

          _tasks.add(ElderlyTaskItem(
            id: id,
            title: item['title'] ?? '',
            type: type,
            time: time,
            details: details,
            isCompleted: item['is_complete'] ?? false,
            hospital: item['hospital'],
            doctor: item['doctor'],
            appointmentDate: item['appointment_date'],
          ));
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) {
      return _selectedCategory == 'all' || task.type == _selectedCategory;
    }).toList();

    // Sắp xếp các nhiệm vụ tăng dần theo mốc thời gian hiển thị
    int compareTime(ElderlyTaskItem a, ElderlyTaskItem b) {
      if (a.time == b.time) return 0;
      if (a.time == 'Trước khám' || a.time == 'Tùy lúc' || a.time == 'Cả ngày') return 1;
      if (b.time == 'Trước khám' || b.time == 'Tùy lúc' || b.time == 'Cả ngày') return -1;
      return a.time.compareTo(b.time);
    }
    filteredTasks.sort(compareTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            title: const Text(
              'Việc Cần Làm Hôm Nay',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1E293B)),
            ),
            centerTitle: false,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF475569)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text(
                        'Việc cần làm hôm nay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Danh sách giúp bác theo dõi việc uống thuốc và chuẩn bị các giấy tờ cần thiết cho buổi khám bệnh tiếp theo.',
                        style: TextStyle(
                            fontSize: 15, height: 1.4, color: Colors.black87),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đã hiểu',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildElderlyCategoryFilters(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          filteredTasks.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildElderlyChecklistItemCard(filteredTasks[index]);
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildElderlyCategoryFilters() {
    final categories = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.list_rounded},
      {'key': 'task', 'label': 'Công việc', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'document', 'label': 'Hồ sơ mang theo', 'icon': Icons.assignment_rounded},
      {'key': 'appointment', 'label': 'Tái khám', 'icon': Icons.local_hospital_rounded},
    ];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];

          Color typeColor;
          Color typeBg;

          if (cat['key'] == 'document') {
            typeColor = const Color(0xFFD97706);
            typeBg = const Color(0xFFFEF3C7);
          } else if (cat['key'] == 'appointment') {
            typeColor = const Color(0xFFE11D48);
            typeBg = const Color(0xFFFFE4E6);
          } else if (cat['key'] == 'task') {
            typeColor = const Color(0xFF059669);
            typeBg = const Color(0xFFD1FAE5);
          } else {
            typeColor = const Color(0xFF475569);
            typeBg = const Color(0xFFF1F5F9);
          }

          int count = cat['key'] == 'all' ? _tasks.length : _tasks.where((t) => t.type == cat['key']).length;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['key'] as String;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? typeColor : typeBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                  ],
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : typeColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : typeColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : typeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white24
                            : typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : typeColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Mở BottomSheet thông tin thuốc và hướng dẫn uống chi tiết
  void _showTaskDetails(ElderlyTaskItem task) {
    Color themeColor;
    IconData typeIcon;
    String typeLabel;

    if (task.type == 'medication') {
      themeColor = _getMedicationColor(task.title);
      typeIcon = _getMedicationIcon(task.title);
      typeLabel = 'Thông tin thuốc';
    } else if (task.type == 'appointment') {
      themeColor = const Color(0xFFE11D48);
      typeIcon = Icons.local_hospital_rounded;
      typeLabel = 'Thông tin tái khám';
    } else if (task.type == 'task') {
      themeColor = const Color(0xFF059669);
      typeIcon = Icons.check_circle_outline_rounded;
      typeLabel = 'Thông tin công việc';
    } else {
      themeColor = const Color(0xFFD97706);
      typeIcon = Icons.assignment_rounded;
      typeLabel = 'Thông tin hồ sơ/chuẩn bị';
    }

    final int? scheduleId = task.type == 'medication' ? int.tryParse(task.id) : null;
    final bool isTaken = task.type == 'medication'
        ? (scheduleId != null && _isMedicationTaken(scheduleId, DateTime.now()))
        : task.isCompleted;

    bool canComplete = true;
    if (task.type == 'appointment' && task.appointmentDate != null && task.appointmentDate!.isNotEmpty && !isTaken) {
      try {
        String cleanDate = task.appointmentDate!;
        if (cleanDate.length >= 10) cleanDate = cleanDate.substring(0, 10);
        final dateParts = cleanDate.split('-');
        if (dateParts.length == 3) {
          int year = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int day = int.parse(dateParts[2]);
          int hour = 0;
          int minute = 0;
          if (task.time.contains(':')) {
            final timeParts = task.time.split(':');
            if (timeParts.length >= 2) {
              hour = int.parse(timeParts[0]);
              minute = int.parse(timeParts[1]);
            }
          }
          final aptTime = DateTime(year, month, day, hour, minute);
          if (DateTime.now().isBefore(aptTime)) {
            canComplete = false;
          }
        }
      } catch (e) {
        // ignore
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Tránh bị che bởi thanh điều hướng hệ thống (system navigation bar)
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding > 0 ? bottomPadding + 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo nhỏ trên đầu modal
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Hàng tiêu đề có icon tròn bên trái như caregiver
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(typeIcon, color: themeColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9), thickness: 1),
              const SizedBox(height: 16),

              if (task.type == 'medication') ...[
                _detailRow(Icons.medical_services_rounded, 'Liều lượng', task.dosage ?? 'Không rõ', themeColor),
                _detailRow(
                  Icons.repeat_rounded,
                  'Tần suất',
                  task.frequency ?? (task.dosesPerDay != null ? '${task.dosesPerDay} lần/ngày' : 'Chưa rõ'),
                  themeColor,
                ),
                _detailRow(Icons.access_time_rounded, 'Giờ uống', task.time, themeColor),
                _detailRow(Icons.restaurant_rounded, 'Cách uống', task.instruction ?? 'Không rõ', themeColor),
                if (task.startDate != null && task.startDate!.isNotEmpty)
                  _detailRow(
                    Icons.calendar_today_rounded,
                    'Thời gian',
                    '${task.startDate} - ${task.endDate}',
                    themeColor,
                  ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                  const SizedBox(height: 8),
                  _noteBox(Icons.sticky_note_2_rounded, 'Ghi chú', task.description!, themeColor),
                ],
              ] else if (task.type == 'appointment') ...[
                if (task.appointmentDate != null && task.appointmentDate!.isNotEmpty)
                  _detailRow(Icons.calendar_today_rounded, 'Ngày khám', _formatDate(task.appointmentDate!), themeColor),
                _detailRow(Icons.access_time_rounded, 'Giờ khám', task.time, themeColor),
                if (task.hospital != null && task.hospital!.isNotEmpty)
                  _detailRow(Icons.local_hospital_rounded, 'Bệnh viện/Cơ sở', task.hospital!, themeColor),
                if (task.doctor != null && task.doctor!.isNotEmpty)
                  _detailRow(Icons.person_rounded, 'Bác sĩ', task.doctor!, themeColor),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 8),
                _noteBox(Icons.info_outline_rounded, 'Ghi chú', task.details.isNotEmpty ? task.details : 'Không có ghi chú', themeColor),
              ] else ...[
                _detailRow(Icons.access_time_rounded, 'Thời gian', task.time, themeColor),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 8),
                _noteBox(Icons.info_outline_rounded, 'Hướng dẫn chuẩn bị', task.details, themeColor),
              ],
              const SizedBox(height: 28),
              // Nút Đóng & Hoàn thành/Hủy hoàn thành
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Đóng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !canComplete ? Colors.grey.shade400 : (isTaken ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: !canComplete ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chưa tới thời gian tái khám, chưa thể xác nhận!'),
                              backgroundColor: Color(0xFFF59E0B),
                            ),
                          );
                        } : () async {
                          Navigator.pop(context);
                          await _toggleTaskCompletion(task);
                        },
                        child: Text(
                          !canComplete ? 'Chưa tới giờ' : (isTaken ? 'Hủy xác nhận' : 'Đã làm xong'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _noteBox(IconData icon, String label, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Phân loại tự động biểu tượng theo tên thuốc
  IconData _getMedicationIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('siro') || lower.contains('nước') || lower.contains('dầu') || lower.contains('giọt') || lower.contains('dung dịch')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('sữa') || lower.contains('bột') || lower.contains('gói') || lower.contains('pha')) {
      return Icons.science_outlined;
    }
    if (lower.contains('tiêm') || lower.contains('insulin') || lower.contains('chích')) {
      return Icons.vaccines_rounded;
    }
    return Icons.medication_rounded;
  }

  // Phân loại tự động tông màu sắc theo tên thuốc
  Color _getMedicationColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('siro') || lower.contains('nước') || lower.contains('dầu') || lower.contains('giọt') || lower.contains('dung dịch')) {
      return const Color(0xFF0EA5E9);
    }
    if (lower.contains('sữa') || lower.contains('bột') || lower.contains('gói') || lower.contains('pha')) {
      return const Color(0xFFD97706);
    }
    if (lower.contains('tiêm') || lower.contains('insulin') || lower.contains('chích')) {
      return const Color(0xFFEC4899);
    }
    return const Color(0xFF2563EB);
  }

  // Dựng thẻ nhiệm vụ phẳng tối giản, sạch sẽ
  Widget _buildElderlyChecklistItemCard(ElderlyTaskItem task) {
    Color typeColor;
    switch (task.type) {
      case 'medication':
        typeColor = const Color(0xFF0284C7);
        break;
      case 'document':
        typeColor = const Color(0xFFD97706);
        break;
      default:
        typeColor = const Color(0xFF475569);
        break;
    }

    final Color itemColor = task.type == 'medication'
        ? _getMedicationColor(task.title)
        : typeColor;

    final IconData itemIcon = task.type == 'medication'
        ? _getMedicationIcon(task.title)
        : Icons.assignment_rounded;

    // Đọc trạng thái đã tích uống từ Trang chủ / Database
    final int? scheduleId = task.type == 'medication' ? int.tryParse(task.id) : null;
    final bool isTaken = task.type == 'medication'
        ? (scheduleId != null && _isMedicationTaken(scheduleId, DateTime.now()))
        : task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isTaken ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isTaken
              ? Colors.grey.shade200
              : itemColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showTaskDetails(task);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon tròn bên trái như Home Screen
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isTaken
                          ? const Color(0xFFE8F5E9)
                          : itemColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTaken ? Icons.check_circle_rounded : itemIcon,
                      color: isTaken ? const Color(0xFF10B981) : itemColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nội dung công việc (Đạt cấu trúc chống lỗi tràn viền ngang)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng nhãn mốc thời gian và hướng dẫn
                        Row(
                          children: [
                            Text(
                              task.time == 'Trước khám' ? 'Trước khám' : task.time,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isTaken ? Colors.grey : itemColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.type == 'medication'
                                    ? (isTaken ? '• Đã hoàn thành' : '• Bấm xem hướng dẫn dùng')
                                    : '• Bấm xem chuẩn bị',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isTaken ? Colors.grey.shade400 : Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Tiêu đề/Tên thuốc
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                            color: isTaken ? Colors.grey.shade400 : const Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.playlist_add_check_rounded,
              size: 64,
              color: Color(0xFFBAE6FD),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Không tìm thấy nhiệm vụ nào!',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bác đã hoàn thành hết công việc của danh mục này.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

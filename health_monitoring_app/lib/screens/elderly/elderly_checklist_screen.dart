import 'package:flutter/material.dart';
import '../../utils/api_service.dart';


class ElderlyTaskItem {
  final String id;
  String title;
  String type; // 'medication' | 'measurement' | 'habit' | 'symptom' | 'document'
  String time;
  String details;

  // Thuộc tính chi tiết cho thuốc
  String? medCode;
  String? dosage;
  int? dosesPerDay;
  String? startDate;
  String? endDate;
  String? frequency;
  String? instruction;
  String? description;

  ElderlyTaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.details,
    this.medCode,
    this.dosage,
    this.dosesPerDay,
    this.startDate,
    this.endDate,
    this.frequency,
    this.instruction,
    this.description,
  });
}

class ElderlyChecklistScreen extends StatefulWidget {
  const ElderlyChecklistScreen({super.key});

  @override
  State<ElderlyChecklistScreen> createState() =>
      _ElderlyChecklistScreenState();
}

class _ElderlyChecklistScreenState extends State<ElderlyChecklistScreen> {
  final List<ElderlyTaskItem> _tasks = [
    ElderlyTaskItem(
      id: '1',
      title: 'Uống thuốc huyết áp Amlodipine 5mg',
      type: 'medication',
      time: '07:00',
      details: '1 viên sau ăn sáng · Huyết áp',
      medCode: 'AML-05',
      dosage: '1 viên',
      dosesPerDay: 1,
      startDate: '01/06/2026',
      endDate: '30/06/2026',
    ),
    ElderlyTaskItem(
      id: '4',
      title: 'Uống thuốc tiểu đường Metformin 500mg',
      type: 'medication',
      time: '12:00',
      details: '1 viên uống ngay trong bữa ăn trưa',
      medCode: 'MET-500',
      dosage: '1 viên',
      dosesPerDay: 2,
      startDate: '01/06/2026',
      endDate: '30/06/2026',
    ),
    ElderlyTaskItem(
      id: '6',
      title: 'Uống thuốc mỡ máu Atorvastatin 20mg',
      type: 'medication',
      time: '20:00',
      details: '1 viên uống trước khi đi ngủ',
      medCode: 'ATO-20',
      dosage: '1 viên',
      dosesPerDay: 1,
      startDate: '01/06/2026',
      endDate: '15/06/2026',
    ),
    ElderlyTaskItem(
      id: 'doc_1',
      title: 'Chuẩn bị CCCD/CMND',
      type: 'document',
      time: 'Trước khám',
      details: 'Cần thiết để làm thủ tục tại Bệnh viện Chợ Rẫy',
    ),
    ElderlyTaskItem(
      id: 'doc_2',
      title: 'Chuẩn bị Thẻ Bảo hiểm Y tế (BHYT)',
      type: 'document',
      time: 'Trước khám',
      details: 'Để nhận hỗ trợ chi phí khám chữa bệnh',
    ),
    ElderlyTaskItem(
      id: 'doc_3',
      title: 'Chuẩn bị Sổ khám bệnh',
      type: 'document',
      time: 'Trước khám',
      details: 'Sổ khám bệnh cũ ghi nhận lịch sử điều trị',
    ),
    ElderlyTaskItem(
      id: 'doc_4',
      title: 'Chuẩn bị Đơn thuốc đang sử dụng',
      type: 'document',
      time: 'Trước khám',
      details: 'Mang theo các loại thuốc đang uống để bác sĩ đối chiếu',
    ),
    ElderlyTaskItem(
      id: 'doc_5',
      title: 'Chuẩn bị Kết quả xét nghiệm liên quan',
      type: 'document',
      time: 'Trước khám',
      details: 'Phim X-quang, kết quả xét nghiệm máu gần đây',
    ),
  ];

  String _selectedCategory = 'medication';

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      // ignore
    }
    return dateStr;
  }

  Future<void> _fetchMedications() async {
    final targetElderlyId = ApiService.currentAccountId;
    if (targetElderlyId == null) return;

    final schedules =
        await ApiService.getElderlyMedicationSchedule(targetElderlyId);
    if (schedules.isNotEmpty) {
      if (mounted) {
        setState(() {
          _tasks.removeWhere((t) => t.type == 'medication');
          for (var s in schedules) {
            final med = s['medication'] ?? {};
            _tasks.add(ElderlyTaskItem(
              id: s['schedule_id'].toString(),
              title: med['name'] ?? 'Thuốc',
              type: 'medication',
              time: s['time']?.isNotEmpty == true ? s['time'] : '08:00',
              details: '${med['dosage'] ?? ''} - ${med['instruction'] ?? ''}',
              medCode: 'MED-${s['schedule_id']}',
              dosage: med['dosage'],
              startDate: _formatDate(s['start_date']),
              endDate: _formatDate(s['end_date']),
              frequency: s['frequency'],
              instruction: med['instruction'],
              description: med['description'],
            ));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) {
      return task.type == _selectedCategory;
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
      {
        'key': 'medication',
        'label': 'Uống thuốc',
        'icon': Icons.medication_rounded
      },
      {
        'key': 'document',
        'label': 'Giấy tờ khám',
        'icon': Icons.assignment_rounded
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['key'];

          Color typeColor;
          Color typeBg;

          if (cat['key'] == 'medication') {
            typeColor = const Color(0xFF0284C7);
            typeBg = const Color(0xFFE0F2FE);
          } else if (cat['key'] == 'document') {
            typeColor = const Color(0xFFD97706);
            typeBg = const Color(0xFFFEF3C7);
          } else {
            typeColor = const Color(0xFF475569);
            typeBg = const Color(0xFFF1F5F9);
          }

          int count = _tasks.where((t) => t.type == cat['key']).length;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat['key'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ),
          );
        }).toList(),
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
    } else {
      themeColor = const Color(0xFFD97706);
      typeIcon = Icons.assignment_rounded;
      typeLabel = 'Thông tin chuẩn bị';
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
                      color: themeColor.withOpacity(0.1),
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
              ] else ...[
                _detailRow(Icons.access_time_rounded, 'Thời gian', task.time, themeColor),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 8),
                _noteBox(Icons.info_outline_rounded, 'Hướng dẫn chuẩn bị', task.details, themeColor),
              ],
              const SizedBox(height: 28),
              // Nút Đóng
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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
              color: color.withOpacity(0.08),
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
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
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

    // Đọc trạng thái đã tích uống từ Trang chủ (thông qua GlobalState dùng chung)
    final int? scheduleId = task.type == 'medication' ? int.tryParse(task.id) : null;
    final bool isTaken = scheduleId != null && false;

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
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

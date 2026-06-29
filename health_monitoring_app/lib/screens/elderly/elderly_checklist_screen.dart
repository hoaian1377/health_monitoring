import 'package:flutter/material.dart';
import '../../utils/global_state.dart';
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
  });
}

enum TimeSlot { morning, afternoon, evening, flexible }

class TimeSlotGroup {
  final TimeSlot slot;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<ElderlyTaskItem> tasks;

  TimeSlotGroup({
    required this.slot,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tasks,
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
      isCompleted: true,
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
      isCompleted: false,
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
      isCompleted: false,
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
      isCompleted: false,
    ),
    ElderlyTaskItem(
      id: 'doc_2',
      title: 'Chuẩn bị Thẻ Bảo hiểm Y tế (BHYT)',
      type: 'document',
      time: 'Trước khám',
      details: 'Để nhận hỗ trợ chi phí khám chữa bệnh',
      isCompleted: false,
    ),
    ElderlyTaskItem(
      id: 'doc_3',
      title: 'Chuẩn bị Sổ khám bệnh',
      type: 'document',
      time: 'Trước khám',
      details: 'Sổ khám bệnh cũ ghi nhận lịch sử điều trị',
      isCompleted: false,
    ),
    ElderlyTaskItem(
      id: 'doc_4',
      title: 'Chuẩn bị Đơn thuốc đang sử dụng',
      type: 'document',
      time: 'Trước khám',
      details: 'Mang theo các loại thuốc đang uống để bác sĩ đối chiếu',
      isCompleted: false,
    ),
    ElderlyTaskItem(
      id: 'doc_5',
      title: 'Chuẩn bị Kết quả xét nghiệm liên quan',
      type: 'document',
      time: 'Trước khám',
      details: 'Phim X-quang, kết quả xét nghiệm máu gần đây',
      isCompleted: false,
    ),
  ];

  String _selectedCategory = 'medication';

  @override
  void initState() {
    super.initState();
    _fetchMedications();
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
              isCompleted: false,
              medCode: 'MED-${s['schedule_id']}',
              dosage: med['dosage'],
            ));
          }
        });
      }
    }
  }

  TimeSlot _getTimeSlot(ElderlyTaskItem task) {
    if (task.time == 'Tùy lúc' || task.time == 'Trước khám' || task.time == 'Cả ngày') {
      return TimeSlot.flexible;
    }
    try {
      final parts = task.time.split(':');
      if (parts.isNotEmpty) {
        final hour = int.parse(parts[0]);
        if (hour >= 5 && hour < 11) {
          return TimeSlot.morning;
        } else if (hour >= 11 && hour < 17) {
          return TimeSlot.afternoon;
        } else {
          return TimeSlot.evening;
        }
      }
    } catch (_) {}
    return TimeSlot.flexible;
  }

  List<TimeSlotGroup> _groupTasks(List<ElderlyTaskItem> tasks) {
    final morningTasks = <ElderlyTaskItem>[];
    final afternoonTasks = <ElderlyTaskItem>[];
    final eveningTasks = <ElderlyTaskItem>[];
    final flexibleTasks = <ElderlyTaskItem>[];

    for (var task in tasks) {
      switch (_getTimeSlot(task)) {
        case TimeSlot.morning:
          morningTasks.add(task);
          break;
        case TimeSlot.afternoon:
          afternoonTasks.add(task);
          break;
        case TimeSlot.evening:
          eveningTasks.add(task);
          break;
        case TimeSlot.flexible:
          flexibleTasks.add(task);
          break;
      }
    }

    int compareTime(ElderlyTaskItem a, ElderlyTaskItem b) {
      if (a.time == b.time) return 0;
      if (a.time == 'Tùy lúc' || a.time == 'Trước khám' || a.time == 'Cả ngày') return 1;
      if (b.time == 'Tùy lúc' || b.time == 'Trước khám' || b.time == 'Cả ngày') return -1;
      return a.time.compareTo(b.time);
    }

    morningTasks.sort(compareTime);
    afternoonTasks.sort(compareTime);
    eveningTasks.sort(compareTime);
    flexibleTasks.sort(compareTime);

    final groups = <TimeSlotGroup>[];
    if (morningTasks.isNotEmpty) {
      groups.add(TimeSlotGroup(
        slot: TimeSlot.morning,
        title: 'Buổi Sáng',
        icon: Icons.light_mode_rounded,
        color: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
        tasks: morningTasks,
      ));
    }
    if (afternoonTasks.isNotEmpty) {
      groups.add(TimeSlotGroup(
        slot: TimeSlot.afternoon,
        title: 'Buổi Trưa & Chiều',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFF0F9FF),
        tasks: afternoonTasks,
      ));
    }
    if (eveningTasks.isNotEmpty) {
      groups.add(TimeSlotGroup(
        slot: TimeSlot.evening,
        title: 'Buổi Tối',
        icon: Icons.dark_mode_rounded,
        color: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
        tasks: eveningTasks,
      ));
    }
    if (flexibleTasks.isNotEmpty) {
      groups.add(TimeSlotGroup(
        slot: TimeSlot.flexible,
        title: 'Linh hoạt & Giấy tờ',
        icon: Icons.assignment_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
        tasks: flexibleTasks,
      ));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) {
      return task.type == _selectedCategory;
    }).toList();

    final totalCount = filteredTasks.length;
    final completedCount = filteredTasks.where((t) => t.isCompleted).length;
    final completionRate =
        totalCount == 0 ? 0.0 : completedCount / totalCount;

    final groups = _groupTasks(filteredTasks);

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
                _buildElderlySummaryProgressCard(
                    completedCount, totalCount, completionRate),
                const SizedBox(height: 8),
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
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: List.generate(groups.length, (index) {
                        return _buildTimelineGroup(
                          groups[index],
                          index == groups.length - 1,
                        );
                      }),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildElderlySummaryProgressCard(
      int completed, int total, double rate) {
    String encouragingText;
    if (rate == 1.0) {
      encouragingText = 'Tuyệt vời! Bác đã hoàn thành xuất sắc tất cả việc.';
    } else if (rate >= 0.5) {
      encouragingText = 'Rất tốt! Bác đã làm được hơn nửa chặng đường rồi.';
    } else if (rate > 0) {
      encouragingText =
          'Khởi đầu tốt! Hãy tiếp tục hoàn thành các việc còn lại nhé.';
    } else {
      encouragingText =
          'Chúc bác một ngày mới ngập tràn năng lượng và sức khỏe!';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến trình ngày hôm nay',
                  style: TextStyle(
                    fontSize: 15.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed / $total việc xong',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  encouragingText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          )
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

  Widget _buildTimelineGroup(TimeSlotGroup group, bool isLast) {
    final completedCount = group.tasks.where((t) => t.isCompleted).length;
    final totalCount = group.tasks.length;
    final isAllDone = completedCount == totalCount;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cột bên trái: Timeline (Icon + Đường nối)
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Icon tròn biểu thị buổi
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAllDone ? const Color(0xFFD1FAE5) : group.bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAllDone ? const Color(0xFF059669) : group.color,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isAllDone ? const Color(0xFF059669) : group.color)
                            .withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    isAllDone ? Icons.check_rounded : group.icon,
                    color: isAllDone ? const Color(0xFF059669) : group.color,
                    size: 20,
                  ),
                ),
                // Đường kết nối đi xuống
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isAllDone
                                ? const Color(0xFF34D399)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cột bên phải: Tiêu đề buổi + Danh sách card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nhãn buổi (ví dụ: Buổi Sáng)
                  Row(
                    children: [
                      Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAllDone
                              ? const Color(0xFF065F46)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAllDone
                              ? const Color(0xFFD1FAE5)
                              : group.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$completedCount/$totalCount xong',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isAllDone
                                ? const Color(0xFF059669)
                                : group.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Render các checklist item card trong buổi này
                  Column(
                    children: group.tasks
                        .map((task) => _buildElderlyChecklistItemCard(task))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElderlyChecklistItemCard(ElderlyTaskItem task) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (task.type) {
      case 'medication':
        typeColor = const Color(0xFF0284C7);
        typeIcon = Icons.medication_rounded;
        typeLabel = 'Uống thuốc';
        break;
      case 'measurement':
        typeColor = const Color(0xFFE11D48);
        typeIcon = Icons.favorite_rounded;
        typeLabel = 'Đo chỉ số';
        break;
      case 'habit':
        typeColor = const Color(0xFF059669);
        typeIcon = Icons.directions_run_rounded;
        typeLabel = 'Thói quen';
        break;
      case 'symptom':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.sick_rounded;
        typeLabel = 'Triệu chứng';
        break;
      case 'document':
        typeColor = const Color(0xFFD97706);
        typeIcon = Icons.assignment_rounded;
        typeLabel = 'Giấy tờ khám';
        break;
      default:
        typeColor = const Color(0xFF475569);
        typeIcon = Icons.check_circle_outline_rounded;
        typeLabel = 'Khác';
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: task.isCompleted ? 0.65 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: task.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: task.isCompleted
                ? Colors.grey.shade200
                : typeColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  task.isCompleted = !task.isCompleted;
                });

                if (task.isCompleted && task.type == 'medication') {
                  globalState.addMedicationLog(MedicationLog(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    taskId: task.id,
                    taskTitle: task.title,
                    takenAt: DateTime.now(),
                    status: 'taken',
                  ));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: task.isCompleted
                        ? const Color(0xFF059669)
                        : const Color(0xFF475569),
                    content: Text(
                      task.isCompleted
                          ? '✓ Đã hoàn thành: ${task.title}'
                          : 'Đã hủy hoàn thành: ${task.title}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.5),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: task.isCompleted ? typeColor : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.isCompleted
                                ? Colors.transparent
                                : const Color(0xFFCBD5E1),
                            width: 2.2,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: task.isCompleted
                                      ? const Color(0xFFE2E8F0)
                                      : typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon,
                                        size: 12.5,
                                        color: task.isCompleted
                                            ? Colors.grey
                                            : typeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: task.isCompleted
                                            ? Colors.grey
                                            : typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                task.time == 'Trước khám'
                                    ? 'Trước khám'
                                    : '⏰ ${task.time}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: task.isCompleted
                                      ? Colors.grey
                                      : const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? Colors.grey.shade400
                                  : const Color(0xFF1E293B),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.details,
                            style: TextStyle(
                              fontSize: 15,
                              color: task.isCompleted
                                  ? Colors.grey.shade300
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (task.type == 'medication' &&
                              task.medCode != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? const Color(0xFFF1F5F9)
                                    : typeColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildElderlyMedInfoTag(
                                      '💊 ${task.dosage}', task.isCompleted),
                                  _buildElderlyMedInfoTag(
                                      '🔁 ${task.dosesPerDay} lần/ngày',
                                      task.isCompleted),
                                  if (task.startDate != null)
                                    _buildElderlyMedInfoTag(
                                        '📅 ${task.startDate} - ${task.endDate}',
                                        task.isCompleted),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElderlyMedInfoTag(String text, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isCompleted ? Colors.grey.shade200 : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: isCompleted ? Colors.grey : const Color(0xFF0369A1),
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

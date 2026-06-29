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
      id: '2',
      title: 'Đo huyết áp buổi sáng',
      type: 'measurement',
      time: '08:00',
      details: 'Nghỉ ngơi 5p trước khi đo',
      isCompleted: true,
    ),
    ElderlyTaskItem(
      id: '3',
      title: 'Uống nước ấm',
      type: 'habit',
      time: '10:00',
      details: 'Ly nước ấm thứ 2 trong ngày (250ml)',
      isCompleted: true,
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
      id: '5',
      title: 'Đi bộ công viên',
      type: 'habit',
      time: '17:00',
      details: 'Vận động nhẹ nhàng 30 phút',
      isCompleted: false,
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
      id: '7',
      title: 'Ghi lại triệu chứng chóng mặt',
      type: 'symptom',
      time: 'Tùy lúc',
      details: 'Ghi chú cho bác sĩ lần khám tới',
      isCompleted: false,
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

  String _selectedCategory = 'all';

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

  @override
  Widget build(BuildContext context) {
    final totalCount = _tasks.length;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final completionRate =
        totalCount == 0 ? 0.0 : completedCount / totalCount;

    final filteredTasks = _tasks.where((task) {
      if (_selectedCategory == 'all') return true;
      return task.type == _selectedCategory;
    }).toList();

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
                        'Danh sách giúp bác theo dõi việc uống thuốc, đo chỉ số sức khỏe và duy trì các thói quen tốt mỗi ngày để cơ thể luôn khỏe mạnh.',
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
              children: [
                _buildElderlySummaryProgressCard(
                    completedCount, totalCount, completionRate),
                _buildElderlyCategoryFilters(),
                const SizedBox(height: 4),
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
                        return _buildElderlyChecklistItemCard(
                            filteredTasks[index]);
                      },
                      childCount: filteredTasks.length,
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
          colors: [Color(0xFF0F605A), Color(0xFF1B8E85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F605A).withValues(alpha: 0.15),
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
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.list_rounded},
      {
        'key': 'medication',
        'label': 'Uống thuốc',
        'icon': Icons.medication_rounded
      },
      {
        'key': 'measurement',
        'label': 'Đo chỉ số',
        'icon': Icons.favorite_rounded
      },
      {
        'key': 'habit',
        'label': 'Thói quen',
        'icon': Icons.directions_run_rounded
      },
      {'key': 'symptom', 'label': 'Triệu chứng', 'icon': Icons.sick_rounded},
      {
        'key': 'document',
        'label': 'Giấy tờ khám',
        'icon': Icons.assignment_rounded
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];

          Color typeColor;
          Color typeBg;

          if (cat['key'] == 'medication') {
            typeColor = const Color(0xFF0284C7);
            typeBg = const Color(0xFFE0F2FE);
          } else if (cat['key'] == 'measurement') {
            typeColor = const Color(0xFFE11D48);
            typeBg = const Color(0xFFFFE4E6);
          } else if (cat['key'] == 'habit') {
            typeColor = const Color(0xFF059669);
            typeBg = const Color(0xFFD1FAE5);
          } else if (cat['key'] == 'symptom') {
            typeColor = const Color(0xFF8B5CF6);
            typeBg = const Color(0xFFF3E8FF);
          } else if (cat['key'] == 'document') {
            typeColor = const Color(0xFFD97706);
            typeBg = const Color(0xFFFEF3C7);
          } else {
            typeColor = const Color(0xFF475569);
            typeBg = const Color(0xFFF1F5F9);
          }

          int count = cat['key'] == 'all'
              ? _tasks.length
              : _tasks.where((t) => t.type == cat['key']).length;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat['key'] as String;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? typeColor : typeBg,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 20,
                    color: isSelected ? Colors.white : typeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : typeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white24
                          : typeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : typeColor,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                              const SizedBox(width: 10),
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

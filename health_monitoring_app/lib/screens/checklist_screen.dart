import 'package:flutter/material.dart';

class TaskItem {
  final String id;
  final String title;
  final String type; // 'medication' | 'measurement' | 'habit' | 'symptom'
  final String time;
  final String details;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.details,
    this.isCompleted = false,
  });
}

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<TaskItem> _tasks = [
    TaskItem(
      id: '1',
      title: 'Uống thuốc huyết áp Amlodipine 5mg',
      type: 'medication',
      time: '07:00',
      details: '1 viên sau ăn sáng · Huyết áp',
      isCompleted: true,
    ),
    TaskItem(
      id: '2',
      title: 'Đo huyết áp buổi sáng',
      type: 'measurement',
      time: '08:00',
      details: 'Nghỉ ngơi 5p trước khi đo',
      isCompleted: true,
    ),
    TaskItem(
      id: '3',
      title: 'Uống nước ấm',
      type: 'habit',
      time: '10:00',
      details: 'Ly nước ấm thứ 2 trong ngày (250ml)',
      isCompleted: true,
    ),
    TaskItem(
      id: '4',
      title: 'Uống thuốc tiểu đường Metformin 500mg',
      type: 'medication',
      time: '12:00',
      details: '1 viên uống ngay trong bữa ăn trưa',
      isCompleted: false,
    ),
    TaskItem(
      id: '5',
      title: 'Đi bộ công viên',
      type: 'habit',
      time: '17:00',
      details: 'Vận động nhẹ nhàng 30 phút',
      isCompleted: false,
    ),
    TaskItem(
      id: '6',
      title: 'Uống thuốc mỡ máu Atorvastatin 20mg',
      type: 'medication',
      time: '20:00',
      details: '1 viên uống trước khi đi ngủ',
      isCompleted: false,
    ),
    TaskItem(
      id: '7',
      title: 'Ghi lại triệu chứng chóng mặt',
      type: 'symptom',
      time: 'Tùy lúc',
      details: 'Ghi chú cho bác sĩ lần khám tới',
      isCompleted: false,
    ),
  ];

  String _selectedCategory = 'all'; // 'all', 'medication', 'measurement', 'habit', 'symptom'

  // Form State for Adding Task
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  String _newTaskType = 'medication';
  TimeOfDay _newTaskTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _addNewTask() {
    if (_titleController.text.trim().isEmpty) return;

    final formattedTime = '${_newTaskTime.hour.toString().padLeft(2, '0')}:${_newTaskTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      _tasks.add(
        TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          type: _newTaskType,
          time: formattedTime,
          details: _detailsController.text.trim().isEmpty 
              ? 'Nhiệm vụ tự lên lịch' 
              : _detailsController.text.trim(),
          isCompleted: false,
        ),
      );
      // Sort tasks by time after adding
      _tasks.sort((a, b) => a.time.compareTo(b.time));
    });

    _titleController.clear();
    _detailsController.clear();
    _newTaskType = 'medication';
    _newTaskTime = const TimeOfDay(hour: 8, minute: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Đã thêm nhiệm vụ mới thành công!'),
      ),
    );
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Thêm Nhiệm Vụ Mới',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),

                    // Title TextField
                    const Text(
                      'Tên nhiệm vụ / Tên thuốc',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên nhiệm vụ hoặc tên thuốc...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Category Card Selector
                    const Text(
                      'Phân loại nhiệm vụ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'medication',
                            Icons.medication_rounded,
                            'Uống thuốc',
                            const Color(0xFF0EA5E9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'measurement',
                            Icons.heart_broken_rounded,
                            'Đo chỉ số',
                            const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'habit',
                            Icons.directions_run_rounded,
                            'Thói quen',
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'symptom',
                            Icons.sick_rounded,
                            'Triệu chứng',
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Time Picker & Details Row
                    Row(
                      children: [
                        // Time Selection Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thời gian',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: _newTaskTime,
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      _newTaskTime = time;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_newTaskTime.hour.toString().padLeft(2, '0')}:${_newTaskTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const Icon(Icons.access_time_rounded, color: Color(0xFF0EA5E9), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Instruction details
                    const Text(
                      'Ghi chú / Hướng dẫn thêm',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        hintText: 'VD: Uống sau ăn, đo lúc nghỉ ngơi...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Add Button
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
                        onPressed: () {
                          _addNewTask();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Tạo nhiệm vụ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeCard(StateSetter setModalState, String type, IconData icon, String label, Color color) {
    final isSelected = _newTaskType == type;
    return InkWell(
      onTap: () {
        setModalState(() {
          _newTaskType = type;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : const Color(0xFF64748B), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final totalCount = _tasks.length;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final completionRate = totalCount == 0 ? 0.0 : completedCount / totalCount;

    // Filter tasks based on category tab
    final filteredTasks = _tasks.where((task) {
      if (_selectedCategory == 'all') return true;
      return task.type == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      appBar: AppBar(
        title: const Text(
          'Checklist Sức Khỏe',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF475569)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Checklist sức khỏe'),
                  content: const Text(
                    'Được thiết kế riêng để bác có thể dễ dàng quản lý việc uống thuốc đúng giờ, đo chỉ số huyết áp/đường huyết và duy trì thói quen sống lành mạnh mỗi ngày.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đã hiểu'),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Beautiful Progress Summary Card ──
          _buildSummaryProgressCard(completedCount, totalCount, completionRate),

          // ── Inline Add Task Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              onPressed: _showAddTaskSheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Thêm nhiệm vụ mới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),

          // ── Category Filters Row ──
          _buildCategoryFilters(),

          // ── Scrollable List of Checklist Items ──
          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildChecklistItemCard(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // A premium summary card displaying an animated circular progress indicator
  Widget _buildSummaryProgressCard(int completed, int total, double rate) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Widget
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Progress details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến trình của bác hôm nay',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed / $total Đã hoàn thành',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rate == 1.0 
                      ? 'Tuyệt vời! Bác đã hoàn thành mọi thứ.' 
                      : 'Cố lên bác nhé! Còn một số nhiệm vụ chờ bác.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xDDFFFFFF),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Beautiful Tab Filters Row
  Widget _buildCategoryFilters() {
    final categories = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.list_rounded},
      {'key': 'medication', 'label': 'Uống thuốc', 'icon': Icons.medication_rounded},
      {'key': 'measurement', 'label': 'Đo chỉ số', 'icon': Icons.heart_broken_rounded},
      {'key': 'habit', 'label': 'Thói quen', 'icon': Icons.directions_run_rounded},
      {'key': 'symptom', 'label': 'Triệu chứng', 'icon': Icons.sick_rounded},
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          Color themeColor;
          if (cat['key'] == 'medication') {
            themeColor = const Color(0xFF0EA5E9);
          } else if (cat['key'] == 'measurement') {
            themeColor = const Color(0xFFEF4444);
          } else if (cat['key'] == 'habit') {
            themeColor = const Color(0xFF10B981);
          } else if (cat['key'] == 'symptom') {
            themeColor = const Color(0xFF8B5CF6);
          } else {
            themeColor = const Color(0xFF475569);
          }

          // Count matching tasks
          int count = cat['key'] == 'all' 
              ? _tasks.length 
              : _tasks.where((t) => t.type == cat['key']).length;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['key'] as String;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: themeColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : themeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white24 : themeColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : themeColor,
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

  // Task list item card
  Widget _buildChecklistItemCard(TaskItem task) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (task.type) {
      case 'medication':
        typeColor = const Color(0xFF0EA5E9); // Blue
        typeIcon = Icons.medication_rounded;
        typeLabel = 'Uống thuốc';
        break;
      case 'measurement':
        typeColor = const Color(0xFFEF4444); // Red
        typeIcon = Icons.heart_broken_rounded;
        typeLabel = 'Đo chỉ số';
        break;
      case 'habit':
        typeColor = const Color(0xFF10B981); // Green
        typeIcon = Icons.directions_run_rounded;
        typeLabel = 'Thói quen';
        break;
      case 'symptom':
        typeColor = const Color(0xFF8B5CF6); // Purple
        typeIcon = Icons.sick_rounded;
        typeLabel = 'Triệu chứng';
        break;
      default:
        typeColor = const Color(0xFF64748B); // Grey
        typeIcon = Icons.check_circle_outline_rounded;
        typeLabel = 'Khác';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(
          color: task.isCompleted ? const Color(0xFFE2E8F0) : typeColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                task.isCompleted = !task.isCompleted;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 800),
                  backgroundColor: task.isCompleted ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  content: Text(
                    task.isCompleted
                        ? 'Đã hoàn thành: ${task.title}'
                        : 'Đã hủy hoàn thành: ${task.title}',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Animated Check Circle Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? typeColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? Colors.transparent : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.done_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Task details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category Tag Label inside Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.isCompleted 
                                    ? const Color(0xFFF1F5F9) 
                                    : typeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    typeIcon,
                                    size: 10,
                                    color: task.isCompleted ? Colors.grey : typeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    typeLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: task.isCompleted ? Colors.grey : typeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Scheduled Time text
                            Text(
                              task.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: task.isCompleted ? Colors.grey : const Color(0xFF0EA5E9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.details,
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isCompleted ? Colors.grey.shade300 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                    onPressed: () {
                      setState(() {
                        _tasks.removeWhere((t) => t.id == task.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: Text('Đã xóa nhiệm vụ: ${task.title}'),
                        ),
                      );
                    },
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
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.playlist_add_check_rounded,
              size: 64,
              color: Colors.blue.shade200,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Không tìm thấy nhiệm vụ nào!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bác hãy thêm nhiệm vụ mới bằng cách bấm nút dưới đây.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

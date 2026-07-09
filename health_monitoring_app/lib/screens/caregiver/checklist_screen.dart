import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:docx_to_text/docx_to_text.dart';
import 'dart:io';
import '../../utils/api_service.dart';

class TaskItem {
  final String id;
  String title;
  String type; // 'task' | 'document' | 'appointment'
  String time;
  String details;
  bool isCompleted;

  // Appointment specific
  String? hospital;
  String? doctor;
  String? appointmentDate;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.details,
    this.isCompleted = false,
    this.hospital,
    this.doctor,
    this.appointmentDate,
  });
}

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen>
    with SingleTickerProviderStateMixin {
  final List<TaskItem> _tasks = [];
  String _selectedCategory = 'all'; // 'all' | 'task' | 'document' | 'appointment'
  bool _isLoading = true;

  int? _currentElderlyId;
  int? _dailyChecklistId;

  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchTasks();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);

    final res = await ApiService.getElderlyList();
    if (res['success'] == true) {
      final list = res['elderly_list'] as List;
      if (list.isNotEmpty) {
        _currentElderlyId = list.first['id'] as int;
      }
    }

    if (_currentElderlyId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final checklistsRes = await ApiService.getChecklists(_currentElderlyId!);
    List<dynamic> checklistItems = [];
    if (checklistsRes.isNotEmpty) {
      final defaultChecklist = checklistsRes.firstWhere(
          (c) => c['title'] == 'Nhiệm vụ hàng ngày',
          orElse: () => checklistsRes.first);
      _dailyChecklistId =
          defaultChecklist['checklistID'] ?? defaultChecklist['id'];
      if (_dailyChecklistId != null) {
        checklistItems = await ApiService.getChecklistItems(_dailyChecklistId!);
      }
    }

    if (mounted) {
      setState(() {
        _tasks.clear();

        for (var item in checklistItems) {
          String type = item['item_type'] ?? 'task';
          String time = item['time_string'] ?? 'Tùy lúc';
          String details = item['details'] ?? '';
          String? hospital = item['hospital'];
          String? doctor = item['doctor'];
          String? appointmentDate = item['appointment_date'];

          // Fallback map old types just in case
          if (type == 'habit' || type == 'measurement' || type == 'symptom') {
            type = 'task';
          }

          _tasks.add(TaskItem(
            id:
                'chk_${item['checklist_itemID'] ?? item['id'] ?? item['checklist_itemid']}',
            title: item['title'] ?? '',
            type: type,
            time: time,
            details: details,
            isCompleted: item['is_complete'] ?? false,
            hospital: hospital,
            doctor: doctor,
            appointmentDate: appointmentDate,
          ));
        }

        _tasks.sort((a, b) => a.time.compareTo(b.time));
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    final newStatus = !task.isCompleted;
    setState(() => task.isCompleted = newStatus);

    if (task.id.startsWith('chk_')) {
      final itemId = int.parse(task.id.replaceFirst('chk_', ''));
      await ApiService.updateChecklistItem(itemId, isComplete: newStatus);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        backgroundColor:
            newStatus ? const Color(0xFF10B981) : const Color(0xFF64748B),
        content: Row(children: [
          Icon(newStatus ? Icons.check_circle_rounded : Icons.undo_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            newStatus
                ? 'Hoàn thành: ${task.title}'
                : 'Đã huỷ: ${task.title}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          )),
        ]),
      ));
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    if (task.id.startsWith('chk_')) {
      final itemId = int.parse(task.id.replaceFirst('chk_', ''));
      await ApiService.deleteChecklistItem(itemId);
    }
    setState(() => _tasks.remove(task));
  }

  Future<void> _addTasksToBackend(List<String> titles, String type) async {
    if (_currentElderlyId == null) return;

    if (_dailyChecklistId == null) {
      final res = await ApiService.createChecklist(
          elderlyId: _currentElderlyId!, title: 'Nhiệm vụ hàng ngày');
      if (res['success'] == true) {
        _dailyChecklistId = res['data']['checklistID'] ??
            res['data']['id'] ??
            res['data']['checklistid'];
      }
    }

    if (_dailyChecklistId == null) return;

    for (final title in titles) {
      if (title.trim().isEmpty) continue;
      await ApiService.createChecklistItem(
        checklistId: _dailyChecklistId!,
        title: title.trim(),
        itemType: type,
        timeString: 'Tùy lúc',
        details: '',
      );
    }
    await _fetchTasks();
  }

  // ─── Open Add Task Sheet ───────────────────────────────────────────────────
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        onAddManual: (title, type, time, details, hospital, doctor,
            appointmentDate) async {
          if (_currentElderlyId == null) return;

          if (type == 'appointment') {
            await ApiService.createAppointment(
              elderlyId: _currentElderlyId!,
              doctorName: doctor ?? '',
              location: hospital ?? '',
              appointmentDate: appointmentDate ?? '',
              appointmentTime: time,
              note: details,
            );
          }

          if (_dailyChecklistId == null) {
            final res = await ApiService.createChecklist(
                elderlyId: _currentElderlyId!,
                title: 'Nhiệm vụ hàng ngày');
            if (res['success'] == true) {
              _dailyChecklistId = res['data']['checklistID'] ??
                  res['data']['id'] ??
                  res['data']['checklistid'];
            }
          }

          if (_dailyChecklistId != null) {
            await ApiService.createChecklistItem(
              checklistId: _dailyChecklistId!,
              title: title,
              itemType: type,
              timeString: time,
              details: details,
              hospital: hospital,
              doctor: doctor,
              appointmentDate: appointmentDate,
            );
          }

          await _fetchTasks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: const Color(0xFF0EA5E9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              content:
                  const Text('✓ Đã thêm nhiệm vụ mới!', style: TextStyle(fontWeight: FontWeight.w600)),
            ));
          }
        },
        onImportFile: (titles, type) async {
          await _addTasksToBackend(titles, type);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              content: Text(
                  '✓ Đã nhập ${titles.length} nhiệm vụ từ file!',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ));
          }
        },
      ),
    );
  }

  // ─── Colors ───────────────────────────────────────────────────────────────
  Color _typeColor(String type) {
    switch (type) {
      case 'document':
        return const Color(0xFFF59E0B);
      case 'appointment':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'document':
        return Icons.assignment_rounded;
      case 'appointment':
        return Icons.local_hospital_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'document':
        return 'Hồ sơ mang theo';
      case 'appointment':
        return 'Tái khám';
      default:
        return 'Công việc';
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
      backgroundColor: const Color(0xFFF0F4FB),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ───────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B), size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text('Checklist Công Việc',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Color(0xFF1E293B))),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _openAddSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0EA5E9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          // ─── Progress Card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildProgressCard(completedCount, totalCount, completionRate),
            ),
          ),

          // ─── Category Chips ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildCategoryChips(),
          ),

          // ─── Task List / Empty ─────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                    SizedBox(height: 16),
                    Text('Đang tải danh sách...', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            )
          else if (filteredTasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildTaskCard(filteredTasks[index]),
                  childCount: filteredTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Progress Card ─────────────────────────────────────────────────────────
  Widget _buildProgressCard(int done, int total, double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rate == 1.0 && total > 0
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (rate == 1.0 && total > 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFF0EA5E9))
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: rate,
                strokeWidth: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${(rate * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiến trình hôm nay',
                    style:
                        TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$done / $total nhiệm vụ',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Chưa có nhiệm vụ nào'
                      : rate == 1.0
                          ? '🎉 Xuất sắc! Hoàn thành tất cả!'
                          : 'Cố lên! Còn ${total - done} việc chưa xong',
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xDDFFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final cats = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.list_rounded},
      {'key': 'task', 'label': 'Công việc', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'document', 'label': 'Hồ sơ mang theo', 'icon': Icons.assignment_rounded},
      {'key': 'appointment', 'label': 'Tái khám', 'icon': Icons.local_hospital_rounded},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final key = cat['key'] as String;
          final isSelected = _selectedCategory == key;
          final color = key == 'document'
              ? const Color(0xFFF59E0B)
              : key == 'appointment'
                  ? const Color(0xFFE11D48)
                  : const Color(0xFF0EA5E9);
          final count = key == 'all'
              ? _tasks.length
              : _tasks.where((t) => t.type == key).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Row(children: [
                Icon(cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : color),
                const SizedBox(width: 5),
                Text(cat['label'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF475569))),
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white24
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── Task Card ─────────────────────────────────────────────────────────────
  Widget _buildTaskCard(TaskItem task) {
    final color = _typeColor(task.type);
    final icon = _typeIcon(task.type);
    final label = _typeLabel(task.type);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTask(task),
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _toggleTask(task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: task.isCompleted
                  ? const Color(0xFFF1F5F9)
                  : color.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: task.isCompleted
                    ? Colors.black.withValues(alpha: 0.02)
                    : color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.transparent
                          : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                    boxShadow: task.isCompleted
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.done_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 14),

                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge + time
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? const Color(0xFFF1F5F9)
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 11,
                                  color: task.isCompleted
                                      ? Colors.grey
                                      : color),
                              const SizedBox(width: 4),
                              Text(label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: task.isCompleted
                                          ? Colors.grey
                                          : color)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (task.time.isNotEmpty && task.time != 'Tùy lúc')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 11,
                                    color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(task.time,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                      ]),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: task.isCompleted
                              ? Colors.grey.shade400
                              : const Color(0xFF1E293B),
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      // Details
                      if (task.details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.details,
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isCompleted
                                ? Colors.grey.shade300
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],

                      // Appointment info
                      if (task.type == 'appointment' &&
                          (task.hospital?.isNotEmpty == true ||
                              task.doctor?.isNotEmpty == true)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13,
                                color: Color(0xFFE11D48)),
                            const SizedBox(width: 5),
                            Flexible(
                                child: Text(
                              [task.hospital, task.doctor]
                                  .where((e) => e?.isNotEmpty == true)
                                  .join(' · '),
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFE11D48),
                                  fontWeight: FontWeight.w600),
                            )),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Delete ──
                IconButton(
                  onPressed: () => _deleteTask(task),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFCBD5E1)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checklist_rtl_rounded,
                  size: 56, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 20),
            const Text('Chưa có nhiệm vụ nào',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text(
              'Nhấn nút "Thêm" phía trên để tạo nhiệm vụ mới\nhoặc nhập từ file Word/Excel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8), height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm nhiệm vụ mới',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD TASK SHEET — with Manual + Import tabs
// ══════════════════════════════════════════════════════════════════════════════
class _AddTaskSheet extends StatefulWidget {
  final Future<void> Function(String title, String type, String time,
      String details, String? hospital, String? doctor, String? appointmentDate) onAddManual;
  final Future<void> Function(List<String> titles, String type) onImportFile;

  const _AddTaskSheet(
      {required this.onAddManual, required this.onImportFile});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual fields
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  String _type = 'task';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  // Import fields
  List<String> _importedTitles = [];
  String _importType = 'task';
  bool _isImporting = false;
  String? _importedFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _detailsController.dispose();
    _hospitalController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Color _color(String type) {
    switch (type) {
      case 'document': return const Color(0xFFF59E0B);
      case 'appointment': return const Color(0xFFE11D48);
      default: return const Color(0xFF0EA5E9);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'docx'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = result.files.first;
      final path = file.path;
      if (path == null) {
        setState(() => _isImporting = false);
        return;
      }

      final List<String> titles = [];
      final ext = file.extension?.toLowerCase();

      if (ext == 'xlsx' || ext == 'xls') {
        final bytes = File(path).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        for (final table in excel.tables.values) {
          for (final row in table.rows) {
            final cell = row.isNotEmpty ? row[0] : null;
            final val = cell?.value?.toString().trim() ?? '';
            if (val.isNotEmpty) titles.add(val);
          }
        }
      } else if (ext == 'docx') {
        final bytes = File(path).readAsBytesSync();
        final text = docxToText(bytes);
        final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        titles.addAll(lines);
      }

      setState(() {
        _importedTitles = titles;
        _importedFileName = file.name;
        _isImporting = false;
      });
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Lỗi đọc file: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.playlist_add_rounded,
                        color: Color(0xFF0EA5E9), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Thêm nhiệm vụ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF0EA5E9),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Tạo thủ công'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Nhập từ file'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildManualTab(controller),
                  _buildImportTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manual Tab ────────────────────────────────────────────────────────────
  Widget _buildManualTab(ScrollController scrollController) {
    final accent = _color(_type);
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      children: [
        // Type Selector
        const Text('Loại nhiệm vụ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Row(children: [
          _typeChip('task', Icons.check_circle_outline_rounded, 'Công việc',
              const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          _typeChip('document', Icons.assignment_rounded, 'Hồ sơ mang theo',
              const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _typeChip('appointment', Icons.local_hospital_rounded, 'Tái khám',
              const Color(0xFFE11D48)),
        ]),
        const SizedBox(height: 20),

        // Title
        _label('Tên nhiệm vụ'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: _inputDecoration('Nhập tiêu đề...', Icons.title_rounded),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Appointment-specific: hospital + doctor
        if (_type == 'appointment') ...[
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Bệnh viện / Cơ sở'),
                const SizedBox(height: 8),
                TextField(
                  controller: _hospitalController,
                  decoration: _inputDecoration(
                      'VD: BV Chợ Rẫy', Icons.local_hospital_outlined),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Bác sĩ'),
                const SizedBox(height: 8),
                TextField(
                  controller: _doctorController,
                  decoration: _inputDecoration('Tên bác sĩ', Icons.person_outline_rounded),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          // Date for appointment
          _label('Ngày khám'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: Color(0xFFE11D48)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: accent),
                const SizedBox(width: 10),
                Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Time (not for document)
        if (_type != 'document') ...[
          _label(_type == 'appointment' ? 'Giờ khám' : 'Thời gian'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.light(primary: accent),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _time = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                Icon(Icons.access_time_rounded, size: 18, color: accent),
                const SizedBox(width: 10),
                Text(
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Details
        _label('Ghi chú (tùy chọn)'),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 3,
          decoration:
              _inputDecoration('Thêm ghi chú, hướng dẫn...', Icons.notes_rounded),
        ),
        const SizedBox(height: 28),

        // Submit button
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên nhiệm vụ')),
                      );
                      return;
                    }
                    setState(() => _isSubmitting = true);
                    final time = _type == 'document'
                        ? 'Trước khám'
                        : '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
                    final date = _type == 'appointment'
                        ? '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'
                        : null;
                    await widget.onAddManual(
                      _titleController.text.trim(),
                      _type,
                      time,
                      _detailsController.text.trim(),
                      _hospitalController.text.trim().isEmpty
                          ? null
                          : _hospitalController.text.trim(),
                      _doctorController.text.trim().isEmpty
                          ? null
                          : _doctorController.text.trim(),
                      date,
                    );
                    if (mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Tạo nhiệm vụ',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ─── Import Tab ────────────────────────────────────────────────────────────
  Widget _buildImportTab(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // How-to banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Hướng dẫn nhập file',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(height: 6),
                  Text(
                    '• File Excel (.xlsx): Mỗi dòng trong cột đầu tiên là 1 nhiệm vụ\n• File Word (.docx): Mỗi dòng văn bản là 1 nhiệm vụ',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12.5, height: 1.5),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Import type selector
        const Text('Loại nhiệm vụ khi nhập',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Row(children: [
          _importTypeChip('task', Icons.check_circle_outline_rounded, 'Công việc',
              const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          _importTypeChip('document', Icons.assignment_rounded, 'Hồ sơ mang theo',
              const Color(0xFFF59E0B)),
        ]),
        const SizedBox(height: 20),

        // Pick file button
        GestureDetector(
          onTap: _isImporting ? null : _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _importedTitles.isEmpty
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF10B981).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _importedTitles.isEmpty
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _importedTitles.isEmpty
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.08)
                      : const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isImporting
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0EA5E9)),
                      )
                    : Icon(
                        _importedTitles.isEmpty
                            ? Icons.upload_file_rounded
                            : Icons.check_circle_rounded,
                        size: 30,
                        color: _importedTitles.isEmpty
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFF10B981),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                _isImporting
                    ? 'Đang đọc file...'
                    : _importedFileName != null
                        ? _importedFileName!
                        : 'Nhấn để chọn file',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _importedTitles.isEmpty
                      ? const Color(0xFF475569)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _importedTitles.isEmpty
                    ? 'Hỗ trợ: .xlsx, .xls, .docx'
                    : 'Đọc được ${_importedTitles.length} nhiệm vụ',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ]),
          ),
        ),

        // Preview list
        if (_importedTitles.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text('Xem trước (${_importedTitles.length} mục)',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B))),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _importedTitles = [];
                _importedFileName = null;
              }),
              child: const Text('Chọn lại',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0EA5E9))),
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: _importedTitles.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0EA5E9))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_importedTitles[i],
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1E293B))),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isImporting
                  ? null
                  : () async {
                      setState(() => _isImporting = true);
                      await widget.onImportFile(_importedTitles, _importType);
                      if (mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.cloud_upload_rounded, size: 20),
              label: Text('Nhập ${_importedTitles.length} nhiệm vụ',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _typeChip(
      String type, IconData icon, String label, Color color) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(children: [
            Icon(icon, size: 22, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : const Color(0xFF94A3B8))),
          ]),
        ),
      ),
    );
  }

  Widget _importTypeChip(
      String type, IconData icon, String label, Color color) {
    final isSelected = _importType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _importType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(children: [
            Icon(icon, size: 22, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : const Color(0xFF94A3B8))),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569)));

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5),
        prefixIcon:
            Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      );
}

import 'package:flutter/material.dart';
import '../utils/global_state.dart';
import '../utils/api_service.dart';

class TaskItem {
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

  TaskItem({
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
      medCode: 'AML-05',
      dosage: '1 viên',
      dosesPerDay: 1,
      startDate: '01/06/2026',
      endDate: '30/06/2026',
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
      medCode: 'MET-500',
      dosage: '1 viên',
      dosesPerDay: 2,
      startDate: '01/06/2026',
      endDate: '30/06/2026',
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
      medCode: 'ATO-20',
      dosage: '1 viên',
      dosesPerDay: 1,
      startDate: '01/06/2026',
      endDate: '15/06/2026',
    ),
    TaskItem(
      id: '7',
      title: 'Ghi lại triệu chứng chóng mặt',
      type: 'symptom',
      time: 'Tùy lúc',
      details: 'Ghi chú cho bác sĩ lần khám tới',
      isCompleted: false,
    ),
    // Checklist chuẩn bị giấy tờ đi khám
    TaskItem(
      id: 'doc_1',
      title: 'Chuẩn bị CCCD/CMND',
      type: 'document',
      time: 'Trước khám',
      details: 'Cần thiết để làm thủ tục tại Bệnh viện Chợ Rẫy',
      isCompleted: false,
    ),
    TaskItem(
      id: 'doc_2',
      title: 'Chuẩn bị Thẻ Bảo hiểm Y tế (BHYT)',
      type: 'document',
      time: 'Trước khám',
      details: 'Để nhận hỗ trợ chi phí khám chữa bệnh',
      isCompleted: false,
    ),
    TaskItem(
      id: 'doc_3',
      title: 'Chuẩn bị Sổ khám bệnh',
      type: 'document',
      time: 'Trước khám',
      details: 'Sổ khám bệnh cũ ghi nhận lịch sử điều trị',
      isCompleted: false,
    ),
    TaskItem(
      id: 'doc_4',
      title: 'Chuẩn bị Đơn thuốc đang sử dụng',
      type: 'document',
      time: 'Trước khám',
      details: 'Mang theo các loại thuốc đang uống để bác sĩ đối chiếu',
      isCompleted: false,
    ),
    TaskItem(
      id: 'doc_5',
      title: 'Chuẩn bị Kết quả xét nghiệm liên quan',
      type: 'document',
      time: 'Trước khám',
      details: 'Phim X-quang, kết quả xét nghiệm máu gần đây',
      isCompleted: false,
    ),
  ];

  String _selectedCategory = 'all'; // 'all', 'medication', 'measurement', 'habit', 'symptom', 'document'

  // Form State for Adding Task
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _medCodeController = TextEditingController();
  final _dosageController = TextEditingController();
  final _dosesPerDayController = TextEditingController(text: '1');
  
  String _newTaskType = 'medication';
  TimeOfDay _newTaskTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    final meds = await ApiService.getMedication();
    if (meds.isNotEmpty) {
      setState(() {
        _tasks.removeWhere((t) => t.type == 'medication');
        for (var med in meds) {
          _tasks.add(TaskItem(
            id: med['medicationid'].toString(),
            title: med['name'] ?? 'Thuốc',
            type: 'medication',
            time: '08:00',
            details: '${med['dosage'] ?? ''} - ${med['instruction'] ?? ''}',
            isCompleted: false,
            medCode: 'MED-${med['medicationid']}',
            dosage: med['dosage'],
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _medCodeController.dispose();
    _dosageController.dispose();
    _dosesPerDayController.dispose();
    super.dispose();
  }

  void _addNewTask() {
    if (_titleController.text.trim().isEmpty) return;

    final formattedTime = '${_newTaskTime.hour.toString().padLeft(2, '0')}:${_newTaskTime.minute.toString().padLeft(2, '0')}';
    final isMed = _newTaskType == 'medication';

    setState(() {
      _tasks.add(
        TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          type: _newTaskType,
          time: _newTaskType == 'document' ? 'Trước khám' : formattedTime,
          details: _detailsController.text.trim().isEmpty 
              ? 'Nhiệm vụ tự lên lịch' 
              : _detailsController.text.trim(),
          isCompleted: false,
          medCode: isMed ? (_medCodeController.text.trim().isEmpty ? 'MED-${DateTime.now().millisecond}' : _medCodeController.text.trim()) : null,
          dosage: isMed ? (_dosageController.text.trim().isEmpty ? '1 viên' : _dosageController.text.trim()) : null,
          dosesPerDay: isMed ? (int.tryParse(_dosesPerDayController.text) ?? 1) : null,
          startDate: isMed ? '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}' : null,
          endDate: isMed ? '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}' : null,
        ),
      );
      _tasks.sort((a, b) => a.time.compareTo(b.time));
    });

    _titleController.clear();
    _detailsController.clear();
    _medCodeController.clear();
    _dosageController.clear();
    _dosesPerDayController.text = '1';
    _newTaskType = 'medication';
    _newTaskTime = const TimeOfDay(hour: 8, minute: 0);
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0EA5E9),
        content: Text('Đã thêm nhiệm vụ mới thành công!'),
      ),
    );
  }

  void _showEditTaskSheet(TaskItem task) {
    _titleController.text = task.title;
    _detailsController.text = task.details;
    _newTaskType = task.type;
    if (task.time != 'Trước khám') {
      try {
        final parts = task.time.split(':');
        _newTaskTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
    if (task.type == 'medication') {
      _medCodeController.text = task.medCode ?? '';
      _dosageController.text = task.dosage ?? '';
      _dosesPerDayController.text = task.dosesPerDay?.toString() ?? '1';
    } else {
      _medCodeController.clear();
      _dosageController.clear();
      _dosesPerDayController.clear();
    }

    _showTaskSheet(isEdit: true, taskToEdit: task);
  }

  void _showAddTaskSheet() {
    _titleController.clear();
    _detailsController.clear();
    _medCodeController.clear();
    _dosageController.clear();
    _dosesPerDayController.text = '1';
    _newTaskType = 'medication';
    _newTaskTime = const TimeOfDay(hour: 8, minute: 0);

    _showTaskSheet(isEdit: false);
  }

  void _showTaskSheet({required bool isEdit, TaskItem? taskToEdit}) {
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 24 + MediaQuery.of(context).padding.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      isEdit ? 'Cập nhật nhiệm vụ' : 'Thêm nhiệm vụ mới',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'symptom',
                            Icons.sick_rounded,
                            'Triệu chứng',
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeCard(
                            setModalState,
                            'document',
                            Icons.assignment_rounded,
                            'Giấy tờ khám',
                            const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Additional Medication form fields
                    if (_newTaskType == 'medication') ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mã thuốc',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _medCodeController,
                                  decoration: InputDecoration(
                                    hintText: 'VD: AML-05',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Liều lượng',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _dosageController,
                                  decoration: InputDecoration(
                                    hintText: 'VD: 1 viên, 10ml',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số lần uống / ngày',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _dosesPerDayController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'VD: 1, 2, 3',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngày bắt đầu',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        _startDate = picked;
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
                                          '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF0EA5E9), size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngày kết thúc',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        _endDate = picked;
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
                                          '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF0EA5E9), size: 16),
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
                    ],

                    // Time Picker
                    if (_newTaskType != 'document') ...[
                      Row(
                        children: [
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
                    ],

                    // Instruction details
                    const Text(
                      'Ghi chú / Hướng dẫn thêm',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        hintText: _newTaskType == 'document'
                            ? 'VD: Mang theo bản gốc và photo...'
                            : 'VD: Uống sau ăn, đo lúc nghỉ ngơi...',
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

                    // Add/Edit Button
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
                          if (isEdit && taskToEdit != null) {
                            setState(() {
                              taskToEdit.title = _titleController.text.trim();
                              taskToEdit.details = _detailsController.text.trim();
                              taskToEdit.type = _newTaskType;
                              taskToEdit.time = _newTaskType == 'document' 
                                  ? 'Trước khám' 
                                  : '${_newTaskTime.hour.toString().padLeft(2, '0')}:${_newTaskTime.minute.toString().padLeft(2, '0')}';
                              if (_newTaskType == 'medication') {
                                taskToEdit.medCode = _medCodeController.text.trim();
                                taskToEdit.dosage = _dosageController.text.trim();
                                taskToEdit.dosesPerDay = int.tryParse(_dosesPerDayController.text);
                              }
                            });
                            Navigator.pop(context);
                          } else {
                            _addNewTask();
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          isEdit ? 'Cập nhật nhiệm vụ' : 'Tạo nhiệm vụ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
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
    final isElderly = ApiService.currentRole == 'elderly';

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
      backgroundColor: isElderly ? const Color(0xFFF3F7FA) : const Color(0xFFF0F4FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            title: Text(
              isElderly ? 'Việc Cần Làm Hôm Nay' : 'Checklist Sức Khỏe',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        isElderly ? 'Việc cần làm hôm nay' : 'Checklist sức khỏe',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        isElderly
                            ? 'Danh sách giúp bác theo dõi việc uống thuốc, đo chỉ số sức khỏe và duy trì các thói quen tốt mỗi ngày để cơ thể luôn khỏe mạnh.'
                            : 'Được thiết kế riêng để bác có thể dễ dàng quản lý việc uống thuốc đúng giờ, đo chỉ số huyết áp/đường huyết và duy trì thói quen sống lành mạnh mỗi ngày.',
                        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                // ── Dynamic Summary Progress Card ──
                if (isElderly)
                  _buildElderlySummaryProgressCard(completedCount, totalCount, completionRate)
                else
                  _buildCaregiverSummaryProgressCard(completedCount, totalCount, completionRate),

                // ── Inline Add Task Button (Only shown for caregiver) ──
                if (ApiService.currentRole != 'elderly')
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

                // ── Category Filters (Elderly Grid vs Caregiver List) ──
                if (isElderly)
                  _buildElderlyCategoryFilters()
                else
                  _buildCaregiverCategoryFilters(),

                if (isElderly) const SizedBox(height: 4),
              ],
            ),
          ),
          filteredTasks.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, isElderly ? 4 : 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
                        if (isElderly) {
                          return _buildElderlyChecklistItemCard(task);
                        } else {
                          return _buildCaregiverChecklistItemCard(task);
                        }
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ==========================================
  // CAREGIVER VERSION WIDGETS (Fully restored)
  // ==========================================

  Widget _buildCaregiverSummaryProgressCard(int completed, int total, double rate) {
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
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
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
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
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

  Widget _buildCaregiverCategoryFilters() {
    final categories = [
      {'key': 'all', 'label': 'Tất cả', 'icon': Icons.list_rounded},
      {'key': 'medication', 'label': 'Uống thuốc', 'icon': Icons.medication_rounded},
      {'key': 'measurement', 'label': 'Đo chỉ số', 'icon': Icons.heart_broken_rounded},
      {'key': 'habit', 'label': 'Thói quen', 'icon': Icons.directions_run_rounded},
      {'key': 'symptom', 'label': 'Triệu chứng', 'icon': Icons.sick_rounded},
      {'key': 'document', 'label': 'Giấy tờ khám', 'icon': Icons.assignment_rounded},
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
          } else if (cat['key'] == 'document') {
            themeColor = const Color(0xFFF59E0B);
          } else {
            themeColor = const Color(0xFF475569);
          }

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
                        color: themeColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
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
                        color: isSelected ? Colors.white24 : themeColor.withValues(alpha: 0.08),
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

  Widget _buildCaregiverChecklistItemCard(TaskItem task) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (task.type) {
      case 'medication':
        typeColor = const Color(0xFF0EA5E9);
        typeIcon = Icons.medication_rounded;
        typeLabel = 'Uống thuốc';
        break;
      case 'measurement':
        typeColor = const Color(0xFFEF4444);
        typeIcon = Icons.heart_broken_rounded;
        typeLabel = 'Đo chỉ số';
        break;
      case 'habit':
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.directions_run_rounded;
        typeLabel = 'Thói quen';
        break;
      case 'symptom':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.sick_rounded;
        typeLabel = 'Triệu chứng';
        break;
      case 'document':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.assignment_rounded;
        typeLabel = 'Giấy tờ khám';
        break;
      default:
        typeColor = const Color(0xFF64748B);
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(
          color: task.isCompleted ? const Color(0xFFE2E8F0) : typeColor.withValues(alpha: 0.12),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.isCompleted 
                                    ? const Color(0xFFF1F5F9) 
                                    : typeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                            Text(
                              task.time,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: task.isCompleted ? Colors.grey : const Color(0xFF0EA5E9)),
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
                        if (task.type == 'medication' && task.medCode != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildCaregiverMedInfoTag('Mã: ${task.medCode}', task.isCompleted),
                                _buildCaregiverMedInfoTag('Liều: ${task.dosage}', task.isCompleted),
                                _buildCaregiverMedInfoTag('Uống: ${task.dosesPerDay} lần/ngày', task.isCompleted),
                                if (task.startDate != null)
                                  _buildCaregiverMedInfoTag('${task.startDate} - ${task.endDate}', task.isCompleted),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blue.shade400, size: 20),
                    onPressed: () => _showEditTaskSheet(task),
                  ),
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

  Widget _buildCaregiverMedInfoTag(String text, bool isCompleted) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isCompleted ? Colors.grey : const Color(0xFF0369A1),
      ),
    );
  }

  // ==========================================
  // ELDERLY VERSION WIDGETS (Senior friendly)
  // ==========================================

  Widget _buildElderlySummaryProgressCard(int completed, int total, double rate) {
    String encouragingText;
    if (rate == 1.0) {
      encouragingText = 'Tuyệt vời! Bác đã hoàn thành xuất sắc tất cả việc.';
    } else if (rate >= 0.5) {
      encouragingText = 'Rất tốt! Bác đã làm được hơn nửa chặng đường rồi.';
    } else if (rate > 0) {
      encouragingText = 'Khởi đầu tốt! Hãy tiếp tục hoàn thành các việc còn lại nhé.';
    } else {
      encouragingText = 'Chúc bác một ngày mới ngập tràn năng lượng và sức khỏe!';
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
      {'key': 'medication', 'label': 'Uống thuốc', 'icon': Icons.medication_rounded},
      {'key': 'measurement', 'label': 'Đo chỉ số', 'icon': Icons.favorite_rounded},
      {'key': 'habit', 'label': 'Thói quen', 'icon': Icons.directions_run_rounded},
      {'key': 'symptom', 'label': 'Triệu chứng', 'icon': Icons.sick_rounded},
      {'key': 'document', 'label': 'Giấy tờ khám', 'icon': Icons.assignment_rounded},
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
                  color: isSelected ? Colors.transparent : typeColor.withValues(alpha: 0.15),
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : typeColor.withValues(alpha: 0.12),
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

  Widget _buildElderlyChecklistItemCard(TaskItem task) {
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
            color: task.isCompleted ? Colors.grey.shade200 : typeColor.withValues(alpha: 0.15),
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
                    backgroundColor: task.isCompleted ? const Color(0xFF059669) : const Color(0xFF475569),
                    content: Text(
                      task.isCompleted
                          ? '✓ Đã hoàn thành: ${task.title}'
                          : 'Đã hủy hoàn thành: ${task.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
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
                            color: task.isCompleted ? Colors.transparent : const Color(0xFFCBD5E1),
                            width: 2.2,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: task.isCompleted 
                                      ? const Color(0xFFE2E8F0) 
                                      : typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      typeIcon,
                                      size: 12.5,
                                      color: task.isCompleted ? Colors.grey : typeColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: task.isCompleted ? Colors.grey : typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                task.time == 'Trước khám' ? 'Trước khám' : '⏰ ${task.time}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: task.isCompleted ? Colors.grey : const Color(0xFF0284C7),
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
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.grey.shade400 : const Color(0xFF1E293B),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.details,
                            style: TextStyle(
                              fontSize: 15,
                              color: task.isCompleted ? Colors.grey.shade300 : const Color(0xFF64748B),
                            ),
                          ),
                          if (task.type == 'medication' && task.medCode != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.isCompleted ? const Color(0xFFF1F5F9) : typeColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildElderlyMedInfoTag('💊 ${task.dosage}', task.isCompleted),
                                  _buildElderlyMedInfoTag('🔁 ${task.dosesPerDay} lần/ngày', task.isCompleted),
                                  if (task.startDate != null)
                                    _buildElderlyMedInfoTag('📅 ${task.startDate} - ${task.endDate}', task.isCompleted),
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
        color: isCompleted ? Colors.grey.shade200 : const Color(0xFFE0F2FE),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF1E293B)),
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

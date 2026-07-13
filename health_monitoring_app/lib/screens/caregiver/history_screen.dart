import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';

import '../../utils/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0EA5E9);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color dangerColor = const Color(0xFFEF4444);

  String selectedFilter = 'Tuần này';
  DateTime? selectedDateFilter;
  String _selectedChartMetric = 'Huyết áp';
  final List<String> _chartMetrics = [
    'Huyết áp',
    'Nhịp tim',
    'Đường huyết',
    'Nhiệt độ',
  ];

  List<dynamic> _treatmentHistory = [];
  List<dynamic> _medicationSchedules = [];
  List<dynamic> _medicalDocuments = [];
  List<dynamic> _appointments = [];
  List<dynamic> _healthMetrics = [];
  int? _currentElderlyId;
  DateTime? _filterDate;

  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _resultController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ApiService.dataRefreshTrigger.addListener(_onDataChanged);
    _fetchTreatmentHistory();
  }

  void _onDataChanged() {
    if (mounted) {
      _fetchTreatmentHistory();
    }
  }

  Future<void> _fetchTreatmentHistory() async {
    final res = await ApiService.getElderlyList();
    if (res['success'] == true) {
      final list = res['elderly_list'] as List;
      if (list.isNotEmpty) {
        _currentElderlyId = list.first['id'] as int;
      }
    }

    if (_currentElderlyId != null) {
      final history = await ApiService.getTreatmentHistory(_currentElderlyId!);
      final meds = await ApiService.getElderlyMedicationSchedule(
        _currentElderlyId!,
      );
      final docs = await ApiService.getMedicalDocument(
        elderlyId: _currentElderlyId!,
      );
      final appts = await ApiService.getAppointments(_currentElderlyId!);
      final metrics = await ApiService.getHealthMetrics(_currentElderlyId!);
      if (mounted) {
        setState(() {
          _treatmentHistory = history;
          _medicationSchedules = meds;
          _medicalDocuments = docs;
          _appointments = appts;
          _healthMetrics = metrics;
        });
      }
    }
  }

  @override
  void dispose() {
    ApiService.dataRefreshTrigger.removeListener(_onDataChanged);
    _tabController.dispose();
    _hospitalController.dispose();
    _doctorController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [SliverToBoxAdapter(child: _buildHeader())];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMedicineTab(),
            _buildMetricsTab(),
            _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: Color(0x330EA5E9),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch Sử Theo Dõi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Xem lại toàn bộ hoạt động',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Thuốc'),
              Tab(text: 'Chỉ Số'),
              Tab(text: 'Khám Bệnh'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Thuốc ──
  Widget _buildMedicineTab() {
    int totalTaken = 0;
    int totalMissed = 0;

    // Group records by date (yyyy-MM-dd)
    final Map<String, List<Map<String, dynamic>>> recordsByDate = {};

    final now = DateTime.now();
    DateTime? filterStartDate;
    if (selectedFilter == 'Tuần này') {
      filterStartDate = now.subtract(const Duration(days: 7));
    } else if (selectedFilter == 'Tháng này') {
      filterStartDate = now.subtract(const Duration(days: 30));
    }

    for (var schedule in _medicationSchedules) {
      final med = schedule['medication'] ?? {};
      final name = med['name']?.toString() ?? 'Không rõ';
      final description = med['description']?.toString() ?? '';
      if (description.contains('· dose_history:')) {
        final parts = description.split('· dose_history:');
        try {
          final list = jsonDecode(parts[1].trim()) as List;
          for (final item in list) {
            final dateStr = item['date'].toString();
            final dateObj = DateTime.tryParse(dateStr);

            if (dateObj != null) {
              if (selectedDateFilter != null) {
                if (dateObj.year != selectedDateFilter!.year ||
                    dateObj.month != selectedDateFilter!.month ||
                    dateObj.day != selectedDateFilter!.day) {
                  continue;
                }
              } else if (filterStartDate != null) {
                final filterDateOnly = DateTime(
                  filterStartDate.year,
                  filterStartDate.month,
                  filterStartDate.day,
                );
                if (dateObj.isBefore(filterDateOnly)) {
                  continue;
                }
              }
            }

            final taken = item['taken'] == true;
            if (taken) {
              totalTaken++;
            } else {
              totalMissed++;
            }
            if (!recordsByDate.containsKey(dateStr)) {
              recordsByDate[dateStr] = [];
            }
            recordsByDate[dateStr]!.add({
              'time': item['time'].toString().substring(0, 5),
              'name': name,
              'status': taken ? 'Đã uống' : 'Bỏ lỡ',
              'isCompleted': taken,
            });
          }
        } catch (e) {
          print("Error parsing dose history: $e");
        }
      }
    }

    int total = totalTaken + totalMissed;
    String percentage = total > 0
        ? '${(totalTaken / total * 100).round()}%'
        : '0%';

    // Sort dates descending
    final sortedDates = recordsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int uniqueDays = sortedDates.length;
    String averagePerDay = '0 lần/ngày';
    if (uniqueDays > 0) {
      double avg = totalTaken / uniqueDays;
      averagePerDay = '${avg.toStringAsFixed(1)} lần/ngày';
      if (averagePerDay.endsWith('.0 lần/ngày')) {
        averagePerDay = '${avg.toInt()} lần/ngày';
      }
    }

    final List<Widget> historyWidgets = [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    for (String dateStr in sortedDates) {
      final dateRecords = recordsByDate[dateStr]!;
      // Sort records by time ascending
      dateRecords.sort((a, b) => a['time'].compareTo(b['time']));

      String label = dateStr;
      if (dateStr == todayStr) {
        label =
            'Hôm nay - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))}';
      } else if (dateStr == yesterdayStr) {
        label =
            'Hôm qua - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))}';
      } else {
        label = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
      }

      historyWidgets.add(_sectionLabel(label));
      historyWidgets.add(const SizedBox(height: 12));

      for (var record in dateRecords) {
        historyWidgets.add(
          _buildHistoryItem(
            time: record['time'],
            name: record['name'],
            status: record['status'],
            isCompleted: record['isCompleted'] == true,
            isUpcoming: false,
          ),
        );
      }
      historyWidgets.add(const SizedBox(height: 20));
    }

    if (historyWidgets.isEmpty) {
      historyWidgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Chưa có dữ liệu uống thuốc',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterChip('Tuần này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tháng này')),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Tất cả')),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: selectedDateFilter != null
                      ? const Color(0xFF0EA5E9)
                      : Colors.white,
                  border: Border.all(
                    color: selectedDateFilter != null
                        ? Colors.transparent
                        : const Color(0xFFBAE6FD),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    if (selectedDateFilter != null) {
                      setState(() {
                        selectedDateFilter = null;
                        selectedFilter = 'Tuần này';
                      });
                      return;
                    }
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDateFilter = date;
                        selectedFilter = '';
                      });
                    }
                  },
                  icon: Icon(
                    selectedDateFilter != null
                        ? Icons.clear_rounded
                        : Icons.calendar_month_rounded,
                    color: selectedDateFilter != null
                        ? Colors.white
                        : const Color(0xFF0EA5E9),
                    size: 20,
                  ),
                  tooltip: selectedDateFilter != null
                      ? 'Bỏ lọc ngày'
                      : 'Lọc theo ngày',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildMetricCard(
                      'Đã uống',
                      '$totalTaken lần',
                      const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard('Bỏ lỡ', '$totalMissed lần', dangerColor),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildMetricCard('Tỉ lệ', percentage, primaryColor),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Trung bình',
                      averagePerDay,
                      const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel('LỊCH SỬ DÙNG THUỐC'),
          const SizedBox(height: 12),
          ...historyWidgets,
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Tab 2: Chỉ Số ──
  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BIỂU ĐỒ THEO DÕI CHỈ SỐ'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _chartMetrics.map((metric) {
                final isSelected = _selectedChartMetric == metric;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChartMetric = metric),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0EA5E9)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFFBAE6FD),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      metric,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthChart(),
          const SizedBox(height: 24),
          _sectionLabel('LỊCH SỬ GẦN ĐÂY'),
          const SizedBox(height: 12),
          if (_healthMetrics.isEmpty)
            const Center(
              child: Text(
                'Chưa có lịch sử',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._healthMetrics.take(5).map((item) {
              String valStr = '';
              IconData ic = Icons.monitor_heart_rounded;
              Color icC = const Color(0xFF16A34A);
              Color bgC = const Color(0xFFDCFCE7);

              if (_selectedChartMetric == 'Nhịp tim') {
                valStr = '${item['heart_rate'] ?? '--'} bpm';
                ic = Icons.monitor_heart_rounded;
                icC = const Color(0xFFE11D48);
                bgC = const Color(0xFFFFEBEB);
              } else if (_selectedChartMetric == 'Huyết áp') {
                valStr = '${item['blood_pressure'] ?? '--'} mmHg';
                ic = Icons.favorite_border_rounded;
                icC = const Color(0xFFDC2626);
                bgC = const Color(0xFFFFEBEB);
              } else if (_selectedChartMetric == 'Đường huyết') {
                valStr = '${item['blood_sugar'] ?? '--'} mmol/L';
                ic = Icons.water_drop_rounded;
                icC = const Color(0xFF0284C7);
                bgC = const Color(0xFFE0F2FE);
              } else if (_selectedChartMetric == 'Nhiệt độ') {
                valStr = '${item['temperature'] ?? '--'} °C';
                ic = Icons.thermostat_rounded;
                icC = const Color(0xFFEA580C);
                bgC = const Color(0xFFFFEDD5);
              }

              String dateStr = item['recorded_at']?.toString() ?? '';
              if (dateStr.isNotEmpty) {
                try {
                  final d = DateTime.parse(dateStr).toLocal();
                  dateStr = DateFormat('dd/MM/yyyy, HH:mm').format(d);
                } catch (_) {}
              }

              return _buildMetricHistoryItem(
                date: dateStr,
                value: valStr,
                icon: ic,
                iconColor: icC,
                bgColor: bgC,
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Tab 3: Khám Bệnh ──
  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bệnh viện, bác sĩ...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Tổng số lần khám',
                  '${_appointments.length} lần',
                  const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Bác sĩ theo dõi',
                  '${_appointments.map((a) => a['doctor_name']).where((n) => n != null && n.toString().isNotEmpty).toSet().length} bác sĩ',
                  const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showAddTreatmentHistorySheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withOpacity(0.4),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF0EA5E9),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thêm kết quả điều trị',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('CÁC LẦN KHÁM GẦN NHẤT'),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filterDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _filterDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _filterDate == null
                        ? Colors.grey.shade100
                        : const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: _filterDate == null
                            ? Colors.grey.shade600
                            : const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _filterDate == null
                            ? 'Lọc theo ngày'
                            : DateFormat('dd/MM/yyyy').format(_filterDate!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _filterDate == null
                              ? Colors.grey.shade600
                              : const Color(0xFF0EA5E9),
                        ),
                      ),
                      if (_filterDate != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _filterDate = null);
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              var filteredAppts = _appointments;

              if (_filterDate != null) {
                String filterStr = DateFormat(
                  'yyyy-MM-dd',
                ).format(_filterDate!);
                filteredAppts = _appointments.where((appt) {
                  return appt['appointment_date']?.toString().startsWith(
                        filterStr,
                      ) ==
                      true;
                }).toList();
              }

              if (filteredAppts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Không có lịch sử khám bệnh nào.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }

              return Column(
                children: filteredAppts.map((appt) {
                  final dateStr = appt['appointment_date']?.toString();
                  final timeStr = appt['appointment_time']
                      ?.toString()
                      ?.substring(0, 5);
                  String formattedDate = 'Không rõ';

                  if (dateStr != null && dateStr.length >= 10) {
                    try {
                      formattedDate = DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(dateStr));
                    } catch (_) {}
                  }

                  if (timeStr != null &&
                      timeStr.isNotEmpty &&
                      timeStr != "null") {
                    formattedDate = '$timeStr $formattedDate';
                  }

                  final hospital =
                      appt['location']?.toString().isNotEmpty == true
                      ? appt['location']
                      : 'Phòng khám / Bệnh viện';
                  final doctor =
                      appt['doctor_name']?.toString().isNotEmpty == true
                      ? appt['doctor_name']
                      : 'Bác sĩ';

                  String resultText =
                      appt['note']?.toString() ?? 'Không có ghi chú';

                  List<dynamic> docs = appt['documents'] ?? [];

                  String diagnosis = appt['diagnosis']?.toString() ?? '';
                  int? appointmentId =
                      appt['appointment_id'] ?? appt['appointmentid'];

                  return _buildAppointmentHistoryItem(
                    date: formattedDate,
                    hospital: hospital,
                    doctor: doctor,
                    diagnosis: diagnosis,
                    result: resultText,
                    documents: docs,
                    appointmentId: appointmentId,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showAddTreatmentHistorySheet() {
    _hospitalController.clear();
    _doctorController.clear();
    _diagnosisController.clear();
    _resultController.clear();
    List<Map<String, String>> selectedFiles = [];
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

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
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    24 +
                    MediaQuery.of(context).padding.bottom,
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
                    const Text(
                      'Thêm hồ sơ khám bệnh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setModalState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDate),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setModalState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(selectedTime.format(context)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Bệnh viện / Cơ sở y tế',
                      _hospitalController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Bác sĩ điều trị', _doctorController),
                    const SizedBox(height: 16),
                    _buildTextField('Chẩn đoán bệnh', _diagnosisController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Kết quả / Ghi chú thêm',
                      _resultController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tài liệu đính kèm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                    'pdf',
                                    'jpg',
                                    'jpeg',
                                    'png',
                                  ],
                                  allowMultiple: true,
                                );
                            if (result != null) {
                              setModalState(() {
                                for (var file in result.files) {
                                  if (file.path != null) {
                                    selectedFiles.add({
                                      'path': file.path!,
                                      'name': file.name,
                                      'type': 'Kết quả khám bệnh',
                                    });
                                  }
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm file'),
                        ),
                      ],
                    ),
                    if (selectedFiles.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: file['type'],
                                          isDense: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0EA5E9),
                                          ),
                                          items:
                                              [
                                                    'Kết quả khám bệnh',
                                                    'Toa thuốc',
                                                    'Xét nghiệm máu',
                                                    'Siêu âm',
                                                    'Khác',
                                                  ]
                                                  .map(
                                                    (t) => DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                selectedFiles[index]['type'] =
                                                    val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 28),
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
                          if (_currentElderlyId == null) return;

                          // Hiển thị dialog đang tải
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          String formattedDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDate);
                          String formattedTime =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                          final res = await ApiService.createMedicalVisit(
                            elderlyId: _currentElderlyId!,
                            date: formattedDate,
                            time: formattedTime,
                            hospital: _hospitalController.text,
                            doctorName: _doctorController.text,
                            diagnosis: _diagnosisController.text,
                            result: _resultController.text,
                            files: selectedFiles,
                          );

                          // Đóng dialog loading
                          Navigator.pop(context);
                          // Đóng bottom sheet
                          Navigator.pop(context);

                          if (res['success'] == true) {
                            _fetchTreatmentHistory();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF0EA5E9),
                                content: Text(
                                  'Đã lưu kết quả điều trị thành công!',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(res['error'] ?? 'Thêm thất bại'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Lưu thông tin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0EA5E9),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label && selectedDateFilter == null;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          selectedDateFilter = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFBAE6FD),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHistoryItem({
    required String time,
    required String name,
    required String status,
    bool isCompleted = false,
    bool isUpcoming = false,
  }) {
    Color statusColor;
    Color iconBg;
    IconData icon;

    if (isUpcoming) {
      statusColor = const Color(0xFF94A3B8);
      iconBg = const Color(0xFFF1F5F9);
      icon = Icons.access_time_rounded;
    } else if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      iconBg = const Color(0xFFDCFCE7);
      icon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626);
      iconBg = const Color(0xFFFFEBEB);
      icon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
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
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricHistoryItem({
    required String date,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
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
    );
  }

  Widget _buildAppointmentHistoryItem({
    required String date,
    required String hospital,
    required String doctor,
    required String result,
    required String diagnosis,
    required int? appointmentId,
    List<dynamic> documents = const [],
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDetailsSheet(
            date,
            hospital,
            doctor,
            diagnosis,
            result,
            documents,
            appointmentId,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (documents.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${documents.length} File',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetailsSheet(
    String date,
    String hospital,
    String doctor,
    String diagnosis,
    String result,
    List<dynamic> documents,
    int? appointmentId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết hồ sơ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Ngày khám',
                        date,
                        icon: Icons.calendar_today_rounded,
                      ),
                      _buildDetailRow(
                        'Bệnh viện / Cơ sở',
                        hospital,
                        icon: Icons.local_hospital_rounded,
                      ),
                      _buildDetailRow(
                        'Bác sĩ điều trị',
                        doctor,
                        icon: Icons.person_rounded,
                      ),
                      if (diagnosis.isNotEmpty)
                        _buildDetailRow(
                          'Chẩn đoán bệnh',
                          diagnosis,
                          icon: Icons.healing_rounded,
                        ),
                      if (result.isNotEmpty)
                        _buildDetailRow(
                          'Kết quả / Ghi chú',
                          result,
                          icon: Icons.description_rounded,
                        ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tài liệu đính kèm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (appointmentId != null)
                            TextButton.icon(
                              onPressed: () =>
                                  _addDocumentToAppointment(appointmentId),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF0F9FF),
                                foregroundColor: const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              label: const Text(
                                'Thêm tài liệu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (documents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Chưa có tài liệu đính kèm.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        ...documents.map((doc) {
                          final String fileName =
                              doc['file_url']?.split('/').last ??
                              'Tài liệu không tên';
                          final String type = doc['document_type'] ?? 'Khác';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    type == 'Toa thuốc'
                                        ? Icons.receipt_long_rounded
                                        : Icons.science_rounded,
                                    color: const Color(0xFF0EA5E9),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.file_download_outlined,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
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
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDocumentToAppointment(int appointmentId) async {
    final List<String> docTypes = [
      'Kết quả khám bệnh',
      'Toa thuốc',
      'Xét nghiệm máu',
      'Siêu âm',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        String selectedType = docTypes.first;
        List<Map<String, String>> pickedFiles = [];
        bool isUploading = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.upload_file_rounded,
                          color: Color(0xFF0EA5E9), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Thêm tài liệu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF334155),
                        ),
                        items: docTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Icon(
                                        t == 'Kết quả khám bệnh'
                                            ? Icons.description_rounded
                                            : t == 'Toa thuốc'
                                                ? Icons.medication_rounded
                                                : t == 'Xét nghiệm máu'
                                                    ? Icons.science_rounded
                                                    : t == 'Siêu âm'
                                                        ? Icons.monitor_heart_rounded
                                                        : Icons.folder_rounded,
                                        size: 18,
                                        color: const Color(0xFF0EA5E9),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Color(0xFF0EA5E9), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.attach_file_rounded,
                          color: Color(0xFF0EA5E9)),
                      label: Text(
                        pickedFiles.isEmpty
                            ? 'Chọn file (PDF, JPG, PNG)'
                            : 'Thêm file khác',
                        style: const TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setSheetState(() {
                            for (var f in result.files) {
                              if (f.path != null) {
                                pickedFiles.add({
                                  'path': f.path!,
                                  'name': f.name,
                                  'type': selectedType,
                                });
                              }
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pickedFiles.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pickedFiles.length,
                        itemBuilder: (_, idx) {
                          final file = pickedFiles[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  file['name']!
                                          .toLowerCase()
                                          .endsWith('.pdf')
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  color: file['name']!
                                          .toLowerCase()
                                          .endsWith('.pdf')
                                      ? Colors.red.shade400
                                      : const Color(0xFF0EA5E9),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: file['type'],
                                          isDense: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0EA5E9),
                                          ),
                                          items: docTypes
                                              .map((t) => DropdownMenuItem(
                                                  value: t,
                                                  child: Text(t)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setSheetState(() =>
                                                  pickedFiles[idx]['type'] =
                                                      val);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 18, color: Colors.red.shade400),
                                  onPressed: () => setSheetState(
                                      () => pickedFiles.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pickedFiles.isEmpty || isUploading
                            ? Colors.grey.shade300
                            : const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        isUploading
                            ? 'Đang tải lên...'
                            : 'Tải lên ${pickedFiles.length} file',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: pickedFiles.isEmpty || isUploading
                          ? null
                          : () async {
                              setSheetState(() => isUploading = true);
                              int successCount = 0;
                              for (var file in pickedFiles) {
                                try {
                                  final uploadUrl = Uri.parse(
                                      "${ApiService.baseUrl}/api/medication/elderly-document/upload/");
                                  var request = http.MultipartRequest(
                                      'POST', uploadUrl);
                                  request.fields['elderly_id'] =
                                      _currentElderlyId.toString();
                                  request.fields['appointment_id'] =
                                      appointmentId.toString();
                                  request.fields['document_type'] =
                                      file['type'] ?? 'Kết quả khám bệnh';
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'file', file['path']!));
                                  final res = await request.send();
                                  if (res.statusCode == 200 ||
                                      res.statusCode == 201) {
                                    successCount++;
                                  }
                                } catch (_) {}
                              }
                              setSheetState(() => isUploading = false);
                              if (mounted) {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                _fetchTreatmentHistory();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    content: Text(
                                        'Đã tải lên $successCount/${pickedFiles.length} tài liệu!'),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHealthChart() {
    List<FlSpot> spots = [];
    Color chartColor = const Color(0xFF0EA5E9);
    double minY = 0, maxY = 200;

    List<dynamic> dataToUse = [];
    if (_healthMetrics.isNotEmpty) {
      // getHealthMetrics API returns descending (newest first).
      // We take up to 7 newest records, and reverse to display chronologically left-to-right.
      dataToUse = _healthMetrics.take(7).toList().reversed.toList();
    }

    if (dataToUse.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    switch (_selectedChartMetric) {
      case 'Nhịp tim':
        chartColor = const Color(0xFFE11D48);
        for (int i = 0; i < dataToUse.length; i++) {
          final val =
              double.tryParse(dataToUse[i]['heart_rate']?.toString() ?? '0') ??
              0;
          spots.add(FlSpot(i.toDouble(), val));
        }
        break;
      case 'Đường huyết':
        chartColor = const Color(0xFF0284C7);
        for (int i = 0; i < dataToUse.length; i++) {
          final val =
              double.tryParse(dataToUse[i]['blood_sugar']?.toString() ?? '0') ??
              0;
          spots.add(FlSpot(i.toDouble(), val));
        }
        break;

      case 'Nhiệt độ':
        chartColor = const Color(0xFFEA580C);
        for (int i = 0; i < dataToUse.length; i++) {
          final val =
              double.tryParse(dataToUse[i]['temperature']?.toString() ?? '0') ??
              0;
          spots.add(FlSpot(i.toDouble(), val));
        }
        break;
      case 'Huyết áp':
      default:
        chartColor = const Color(0xFFDC2626);
        for (int i = 0; i < dataToUse.length; i++) {
          final bpStr = dataToUse[i]['blood_pressure']?.toString() ?? '120/80';
          final sys = double.tryParse(bpStr.split('/')[0]) ?? 120;
          spots.add(FlSpot(i.toDouble(), sys)); // Using systolic for chart
        }
        break;
    }

    if (spots.isNotEmpty) {
      minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (minY == maxY) {
        minY -= 10;
        maxY += 10;
      } else {
        double padding = (maxY - minY) * 0.2;
        minY -= padding;
        maxY += padding;
      }
      if (minY < 0 && _selectedChartMetric != 'Nhiệt độ') {
        minY = 0;
      }
    }

    double maxX = (dataToUse.length - 1).toDouble();
    if (maxX < 0) maxX = 0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1).replaceAll('.0', ''),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < dataToUse.length) {
                    final dateStr = dataToUse[idx]['recorded_at']?.toString();
                    if (dateStr != null && dateStr.length >= 10) {
                      try {
                        final date = DateTime.parse(dateStr).toLocal();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            '${date.day}/${date.month}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              height: 1.2,
                            ),
                          ),
                        );
                      } catch (_) {}
                    }
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: chartColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: chartColor.withOpacity(0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}

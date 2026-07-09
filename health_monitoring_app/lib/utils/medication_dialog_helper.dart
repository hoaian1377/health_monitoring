import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/api_service.dart';

class MedicationDialogHelper {
  static Future<void> scanPrescriptionIntoFields({
    required BuildContext context,
    required Function(List<Map<String, dynamic>>) onSelectionsSelected,
  }) async {
    final ImagePicker picker = ImagePicker();
    XFile? image;

    try {
      image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở thư viện ảnh: $e')));
      return;
    }

    if (image == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF0EA5E9)),
            SizedBox(width: 16),
            Expanded(child: Text('Äang quét toa thuốc...')),
          ],
        ),
      ),
    );

    try {
      final res = await ApiService.scanPrescription(image);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (res['error'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['error'].toString())));
        return;
      }

      final medications = (res['medications'] ?? res['results']) as List?;
      if (medications == null || medications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin thuốc trong ảnh.'),
          ),
        );
        return;
      }

      final selectedItems = <Map<String, dynamic>>[];
      final selected = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Chá»n thuốc từ ảnh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medications.length,
                    itemBuilder: (_, index) {
                      final item = medications[index] as Map<String, dynamic>;
                      final itemName =
                          item['name']?.toString() ?? 'Thuốc không tên';
                      final itemDosage = item['dosage']?.toString() ?? '';
                      final itemInstruction =
                          item['instruction']?.toString() ?? '';
                      final isSelected = selectedItems.any((selectedItem) {
                        final selectedName =
                            selectedItem['name']?.toString() ?? '';
                        final selectedDosage =
                            selectedItem['dosage']?.toString() ?? '';
                        return selectedName.toLowerCase() ==
                                itemName.toLowerCase() &&
                            selectedDosage.toLowerCase() ==
                                itemDosage.toLowerCase();
                      });
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          itemName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          itemInstruction.isNotEmpty
                              ? '$itemDosage · $itemInstruction'
                              : itemDosage,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            final candidate = item.cast<String, dynamic>();
                            if (value == true) {
                              if (!selectedItems.any((selectedItem) {
                                final selectedName =
                                    selectedItem['name']?.toString() ?? '';
                                final selectedDosage =
                                    selectedItem['dosage']?.toString() ?? '';
                                return selectedName.toLowerCase() ==
                                        itemName.toLowerCase() &&
                                    selectedDosage.toLowerCase() ==
                                        itemDosage.toLowerCase();
                              })) {
                                selectedItems.add(candidate);
                              }
                            } else {
                              selectedItems.removeWhere((selectedItem) {
                                final selectedName =
                                    selectedItem['name']?.toString() ?? '';
                                final selectedDosage =
                                    selectedItem['dosage']?.toString() ?? '';
                                return selectedName.toLowerCase() ==
                                        itemName.toLowerCase() &&
                                    selectedDosage.toLowerCase() ==
                                        itemDosage.toLowerCase();
                              });
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selectedItems),
                    child: const Text('Chá»n'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected != null && selected.isNotEmpty) {
        onSelectionsSelected(selected);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi quét toa thuốc: $e')));
    }
  }

  static void showAddMedicationDialog({ required BuildContext context, required int elderlyId, required VoidCallback onSuccess,
    String? initialName,
    String? initialDosage,
    String? initialInstruction,
    String? initialTime,
    String? initialDescription,
    int? editScheduleId,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final doseAmountCtrl = TextEditingController(
      text: initialDosage != null
          ? initialDosage.replaceAll(RegExp(r'[^0-9.]'), '')
          : '',
    );
    final remainingCtrl = TextEditingController();
    if (initialDescription != null) {
      final regExp = RegExp(r'(?:Còn lại|Tổng số viên thuốc):\s*(\d+)');
      final match = regExp.firstMatch(initialDescription);
      if (match != null) {
        remainingCtrl.text = match.group(1) ?? '';
      }
    }
    final scannedInstructionCtrl = TextEditingController();

    String selectedGroup = 'Khác';
    String selectedInstruction = 'Sau ăn';
    String selectedDoseUnit = 'viên';
    String selectedTime = initialTime ?? '08:00';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    List<String> timeSlots = [initialTime ?? '08:00'];
    bool isSubmitting = false;

    if (initialDosage != null) {
      for (final unit in ['viên', 'gói', 'ml', 'mg', 'lần']) {
        if (initialDosage.toLowerCase().contains(unit)) {
          selectedDoseUnit = unit;
          break;
        }
      }
    }
    if (initialInstruction != null) {
      final low = initialInstruction.toLowerCase();
      if (low.contains('trước'))
        selectedInstruction = 'Trước ăn';
      else if (low.contains('sau'))
        selectedInstruction = 'Sau ăn';
      else if (low.contains('trong'))
        selectedInstruction = 'Trong bữa ăn';
      else if (low.contains('ngủ'))
        selectedInstruction = 'Trước ngủ';
      else if (low.contains('cần'))
        selectedInstruction = 'Khi cần';
    }

    List<Map<String, dynamic>> scannedSelections = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart ? startDate : endDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('vi'),
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDlg(() {
                if (isStart)
                  startDate = picked;
                else
                  endDate = picked;
              });
            }
          }

          Future<void> pickTime() async {
            final t = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay(
                hour: int.tryParse(selectedTime.split(':')[0]) ?? 8,
                minute: int.tryParse(selectedTime.split(':')[1]) ?? 0,
              ),
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (t != null) {
              setDlg(() {
                final formatted =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                if (!timeSlots.contains(formatted)) {
                  timeSlots.add(formatted);
                }
                selectedTime = formatted;
              });
            }
          }

          void applySuggestions(String value) {
            final normalized = value.trim().toLowerCase();
            if (normalized.isEmpty) return;

            setDlg(() {
              if (selectedGroup == 'Khác') {
                if (normalized.contains('huyết áp') ||
                    normalized.contains('amlodipine') ||
                    normalized.contains('lisinopril')) {
                  selectedGroup = 'Huyết áp';
                } else if (normalized.contains('Ä‘Æ°á»ng') ||
                    normalized.contains('metformin') ||
                    normalized.contains('glipizide')) {
                  selectedGroup = 'Tiểu Ä‘Æ°á»ng';
                } else if (normalized.contains('tim') ||
                    normalized.contains('mạch') ||
                    normalized.contains('atorvastatin')) {
                  selectedGroup = 'Tim mạch';
                } else if (normalized.contains('vitamin') ||
                    normalized.contains('d3')) {
                  selectedGroup = 'Vitamin';
                }
              }

              if (doseAmountCtrl.text.trim().isEmpty) {
                final dosageMatch = RegExp(
                  r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu)',
                ).firstMatch(normalized);
                if (dosageMatch != null) {
                  doseAmountCtrl.text = dosageMatch.group(1)!;
                } else if (normalized.contains('viên') ||
                    normalized.contains('tablet') ||
                    normalized.contains('capsule')) {
                  doseAmountCtrl.text = '1';
                }
              }

              if (normalized.contains('trước ăn')) {
                selectedInstruction = 'Trước ăn';
              } else if (normalized.contains('sau ăn')) {
                selectedInstruction = 'Sau ăn';
              } else if (normalized.contains('trong bữa ăn')) {
                selectedInstruction = 'Trong bữa ăn';
              } else if (normalized.contains('ngủ')) {
                selectedInstruction = 'Trước ngủ';
              } else if (normalized.contains('khi cần')) {
                selectedInstruction = 'Khi cần';
              }

              if (normalized.contains('ml')) {
                selectedDoseUnit = 'ml';
              } else if (normalized.contains('gói')) {
                selectedDoseUnit = 'gói';
              } else if (normalized.contains('ống')) {
                selectedDoseUnit = 'ống';
              }
            });
          }

          Widget fieldLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          );

          final instructions = [
            'Trước ăn',
            'Sau ăn',
            'Trong bữa ăn',
            'Khi cần',
            'Trước ngủ',
          ];
          final doseUnits = ['viên', 'gói', 'ml', 'mg', 'lần'];

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_circle_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Thêm lịch uống',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Nhập nhanh, ít thao tác',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await scanPrescriptionIntoFields(
                              context: ctx,
                              onSelectionsSelected: (selected) => setDlg(() {
                                scannedSelections = selected;
                                if (selected.isNotEmpty) {
                                  final first = selected.first;
                                  final firstName =
                                      first['name']?.toString().trim() ?? '';
                                  if (firstName.isNotEmpty) {
                                    nameCtrl.text = firstName;
                                  }
                                  final dosageValue =
                                      first['dosage']?.toString() ?? '';
                                  if (dosageValue.isNotEmpty) {
                                    final doseMatch = RegExp(
                                      r'(\d+(?:\.\d+)?)',
                                    ).firstMatch(dosageValue);
                                    if (doseMatch != null) {
                                      doseAmountCtrl.text = doseMatch.group(1)!;
                                    }
                                  }
                                  final instructionValue =
                                      first['instruction']?.toString() ?? '';
                                  if (instructionValue.isNotEmpty) {
                                    scannedInstructionCtrl.text =
                                        instructionValue;
                                    final lower = instructionValue
                                        .toLowerCase();
                                    if (lower.contains('trước')) {
                                      selectedInstruction = 'Trước ăn';
                                    } else if (lower.contains('sau')) {
                                      selectedInstruction = 'Sau ăn';
                                    } else if (lower.contains('ngủ')) {
                                      selectedInstruction = 'Trước ngủ';
                                    } else if (lower.contains('cần')) {
                                      selectedInstruction = 'Khi cần';
                                    }
                                  }
                                  final timeValue =
                                      first['time']?.toString() ?? '';
                                  if (timeValue.isNotEmpty) {
                                    timeSlots = [timeValue];
                                    selectedTime = timeValue;
                                  }
                                }
                              }),
                            );
                            applySuggestions(nameCtrl.text);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chỉ nhập những gì thật cần để bắt đầu ngay.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (scannedSelections.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ÄÃ£ chá»n ${scannedSelections.length} thuốc từ ảnh',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      scannedSelections
                                          .map(
                                            (item) =>
                                                item['name']?.toString() ??
                                                'Thuốc không tên',
                                          )
                                          .join(', '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            fieldLabel('Tên thuốc *'),
                            TextField(
                              controller: nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              onChanged: applySuggestions,
                              decoration: InputDecoration(
                                hintText: 'VD: Amlodipine 5mg',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                ),
                                prefixIcon: const Icon(
                                  Icons.medication_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            fieldLabel('Liá»u lượng'),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: doseAmountCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'VD: 1',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.medication_liquid_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF2563EB),
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 110,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedDoseUnit,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF2563EB),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    items: doseUnits
                                        .map(
                                          (unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setDlg(
                                      () => selectedDoseUnit =
                                          value ?? selectedDoseUnit,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                fieldLabel('Giá» uống'),
                                GestureDetector(
                                  onTap: pickTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: Color(0xFF2563EB),
                                          size: 15,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Thêm giá»',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: timeSlots.map((slot) {
                                final isSelected = selectedTime == slot;
                                return GestureDetector(
                                  onTap: () =>
                                      setDlg(() => selectedTime = slot),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 15,
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          slot,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            fieldLabel('Cách dùng'),
                            DropdownButtonFormField<String>(
                              value: selectedInstruction,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              items: instructions
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setDlg(
                                () => selectedInstruction =
                                    value ?? selectedInstruction,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      fieldLabel('Ngày bắt đầu'),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => pickDate(true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 13,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                color: Color(0xFF2563EB),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      fieldLabel('Ngày kết thúc'),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => pickDate(false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 13,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                color: Color(0xFF64748B),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            fieldLabel('Tổng số viên thuốc (tùy chá»n)'),
                            TextField(
                              controller: remainingCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'VD: 30',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                ),
                                prefixIcon: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            fieldLabel('Nhóm thuốc (tùy chá»n)'),
                            DropdownButtonFormField<String>(
                              value: selectedGroup,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(
                                  Icons.category_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              items:
                                  [
                                        'Khác',
                                        'Huyết áp',
                                        'Tiểu Ä‘Æ°á»ng',
                                        'Tim mạch',
                                        'Vitamin',
                                      ]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setDlg(
                                () => selectedGroup = value ?? selectedGroup,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Vui lòng nhập tên thuốc',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setDlg(() => isSubmitting = true);
                                  final dosageStr =
                                      doseAmountCtrl.text.trim().isNotEmpty
                                      ? '${doseAmountCtrl.text.trim()} $selectedDoseUnit'
                                      : selectedDoseUnit;
                                  final startStr =
                                      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                                  final endStr =
                                      '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
                                  final description =
                                      remainingCtrl.text.trim().isNotEmpty
                                      ? 'Nhóm: $selectedGroup · Tổng số viên thuốc: ${remainingCtrl.text.trim()}'
                                      : 'Nhóm: $selectedGroup';

                                  bool ok = false;
                                  if (editScheduleId != null) {
                                    ok = await ApiService.updateMedication(
                                      scheduleId: editScheduleId,
                                      name: name,
                                      dosage: dosageStr,
                                      instruction: selectedInstruction,
                                      time: selectedTime,
                                      frequency: timeSlots.length > 1
                                          ? '${timeSlots.length} lần/ngày'
                                          : 'Hàng ngày',
                                      description: description,
                                      startDate: startStr,
                                      endDate: endStr,
                                    );
                                  } else {
                                    final medicationsToSave =
                                        scannedSelections.isNotEmpty
                                        ? scannedSelections
                                        : <Map<String, dynamic>>[
                                            {
                                              'name': name,
                                              'dosage': dosageStr,
                                              'instruction':
                                                  selectedInstruction,
                                              'time': selectedTime,
                                            },
                                          ];

                                    for (final scannedItem
                                        in medicationsToSave) {
                                      final itemName =
                                          (scannedItem['name'] ?? name)
                                              .toString()
                                              .trim();
                                      if (itemName.isEmpty) continue;
                                      final itemDosage =
                                          (scannedItem['dosage'] ?? dosageStr)
                                              .toString()
                                              .trim();
                                      final itemInstruction =
                                          (scannedItem['instruction'] ??
                                                  selectedInstruction)
                                              .toString()
                                              .trim();
                                      final itemTime =
                                          (scannedItem['time'] ?? selectedTime)
                                              .toString()
                                              .trim();
                                      final success =
                                          await ApiService.addMedication(
                                            elderlyId: elderlyId,
                                            name: itemName,
                                            dosage: itemDosage,
                                            instruction: itemInstruction,
                                            time: itemTime,
                                            frequency: timeSlots.length > 1
                                                ? '${timeSlots.length} lần/ngày'
                                                : 'Hàng ngày',
                                            description: description,
                                            startDate: startStr,
                                            endDate: endStr,
                                          );
                                      if (success) ok = true;
                                    }
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    if (ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          content: Text(
                                            editScheduleId != null
                                                ? '✓ Cập nhật thuốc thành công!'
                                                : '✓ ÄÃ£ thêm thuốc thành công!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                      onSuccess();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Lỗi khi lưu thuốc. Vui lòng thử lại.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  editScheduleId != null
                                      ? 'Lưu thay đổi'
                                      : 'Lưu lịch uống',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
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
}

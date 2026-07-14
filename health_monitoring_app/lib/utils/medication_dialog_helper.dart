import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/api_service.dart';

class MedicationDialogHelper {
  static Future<void> scanPrescriptionIntoFields({
    required BuildContext context,
    required int elderlyId,
    required Function(List<Map<String, dynamic>>) onSelectionsSelected,
  }) async {
    final bool isWeb = kIsWeb;
    final ImageSource? imageSource = isWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Thư viện ảnh'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Chụp ảnh mới'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ],
              ),
            ),
          );

    if (imageSource == null) return;

    final ImagePicker picker = ImagePicker();
    XFile? image;

    try {
      image = await picker.pickImage(
        source: imageSource,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở ảnh: $e')));
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
            Expanded(child: Text('Đang quét toa thuốc...')),
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

      // Auto-upload image as a medical document
      await ApiService.uploadMedicalDocument(
        filePath: image.path,
        documentType: 'Hồ sơ khám bệnh',
        elderlyId: elderlyId,
      );

      // Auto-create appointment if found
      final appointment = res['appointment'];
      if (appointment != null && appointment is Map) {
        final date = appointment['appointment_date']?.toString() ?? '';
        if (date.isNotEmpty && date != 'null') {
          await ApiService.createAppointment(
            elderlyId: elderlyId,
            doctorName: appointment['doctor_name']?.toString() ?? '',
            location: appointment['clinic']?.toString() ?? '',
            appointmentDate: date,
            appointmentTime: appointment['appointment_time']?.toString() ?? '08:00',
            note: appointment['note']?.toString() ?? '',
          );
        }
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
                  'Chọn thuốc từ ảnh (Vui lòng bỏ chọn dữ liệu quét sai)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    child: const Text('Chọn & Lưu Tự Động'),
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
    final descCtrl = TextEditingController();
    if (initialDescription != null) {
      final rmMatch = RegExp(r'(?:Còn lại|Tổng số viên thuốc):\s*(\d+)').firstMatch(initialDescription);
      if (rmMatch != null) remainingCtrl.text = rmMatch.group(1) ?? '';
      
      final descMatch = RegExp(r'Mô tả:\s*([^·]+)').firstMatch(initialDescription);
      if (descMatch != null) descCtrl.text = descMatch.group(1)?.trim() ?? '';
    }
    final scannedInstructionCtrl = TextEditingController();

    String selectedInstruction = 'Sau ăn';
    String selectedDoseUnit = 'viên';
    List<String> selectedTimes = initialTime != null ? [initialTime] : ['08:00'];
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    List<String> timeSlots = initialTime != null ? [initialTime] : ['08:00', '12:00', '18:00'];
    bool isSubmitting = false;
    String? nameError;
    String? doseError;

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
              initialDate: isStart ? startDate : (endDate.isBefore(startDate) ? startDate : endDate),
              firstDate: isStart ? DateTime(2020) : startDate,
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
                if (isStart) {
                  startDate = picked;
                  if (endDate.isBefore(startDate)) {
                    endDate = startDate;
                  }
                } else {
                  endDate = picked;
                }
              });
            }
          }

          Future<void> pickTime() async {
            final firstTime = selectedTimes.isNotEmpty ? selectedTimes.first : '08:00';
            final t = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay(
                hour: firstTime.contains(':') ? (int.tryParse(firstTime.split(':')[0]) ?? 8) : 8,
                minute: firstTime.contains(':') ? (int.tryParse(firstTime.split(':')[1]) ?? 0) : 0,
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
                  timeSlots.sort();
                }
                if (!selectedTimes.contains(formatted)) {
                  selectedTimes.add(formatted);
                  selectedTimes.sort();
                }
              });
            }
          }

          void applySuggestions(String value) {
            final normalized = value.trim().toLowerCase();
            if (normalized.isEmpty) return;

            setDlg(() {
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
                              elderlyId: elderlyId,
                              onSelectionsSelected: (selected) async {
                                if (selected.isNotEmpty) {
                                  setDlg(() => isSubmitting = true);
                                  bool ok = false;
                                  
                                  final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                                  final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

                                  for (final item in selected) {
                                    final itemName = item['name']?.toString().trim() ?? '';
                                    if (itemName.isEmpty) continue;
                                    
                                    final itemDosage = item['dosage']?.toString().trim() ?? '1 viên';
                                    final itemInstruction = item['instruction']?.toString().trim() ?? 'Sau ăn';
                                    final itemTime = item['time']?.toString().trim() ?? '08:00';
                                    final itemFreq = item['frequency']?.toString().trim() ?? 'Hàng ngày';
                                    
                                    final success = await ApiService.addMedication(
                                      elderlyId: elderlyId,
                                      name: itemName,
                                      dosage: itemDosage,
                                      instruction: itemInstruction,
                                      time: itemTime,
                                      frequency: itemFreq,
                                      description: 'Nhóm: Khác',
                                      startDate: startStr,
                                      endDate: endStr,
                                    );
                                    if (success) ok = true;
                                  }
                                  
                                  setDlg(() => isSubmitting = false);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx); // Đóng form chính
                                    if (ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFF10B981),
                                          content: Text('✓ Đã tự động lưu các thuốc từ ảnh thành công!'),
                                          behavior: SnackBarBehavior.floating,
                                        )
                                      );
                                      onSuccess();
                                    }
                                  }
                                }
                              },
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
                                      'Đã chọn ${scannedSelections.length} thuốc từ ảnh',
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
                              onChanged: (val) {
                                if (nameError != null) setDlg(() => nameError = null);
                                applySuggestions(val);
                              },
                              decoration: InputDecoration(
                                errorText: nameError,
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
                            fieldLabel('Liều lượng'),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: doseAmountCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      if (doseError != null) setDlg(() => doseError = null);
                                    },
                                    decoration: InputDecoration(
                                      errorText: doseError,
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
                                fieldLabel('Giờ uống'),
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
                                          'Thêm giờ',
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
                                final isSelected = selectedTimes.contains(slot);
                                return GestureDetector(
                                  onTap: () => setDlg(() {
                                    if (isSelected) {
                                      if (selectedTimes.length > 1) {
                                        selectedTimes.remove(slot);
                                      }
                                    } else {
                                      selectedTimes.add(slot);
                                      selectedTimes.sort();
                                    }
                                  }),
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
                            fieldLabel('Tổng số viên thuốc (tùy chọn)'),
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
                            fieldLabel('Mô tả thuốc (hình dạng, màu sắc)'),
                            TextField(
                              controller: descCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'VD: Viên tròn màu trắng',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                ),
                                prefixIcon: const Icon(
                                  Icons.description_rounded,
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
                                  bool hasError = false;
                                  
                                  setDlg(() {
                                    if (name.isEmpty) {
                                      nameError = 'Vui lòng nhập tên thuốc';
                                      hasError = true;
                                    } else {
                                      nameError = null;
                                    }

                                    if (doseAmountCtrl.text.trim().isEmpty) {
                                      doseError = 'Vui lòng nhập liều lượng';
                                      hasError = true;
                                    } else {
                                      doseError = null;
                                    }
                                  });

                                  if (hasError) return;

                                  if (selectedTimes.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng thêm ít nhất một giờ uống'),
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
                                  String description = '';
                                  if (descCtrl.text.trim().isNotEmpty) {
                                    description = 'Mô tả: ${descCtrl.text.trim()}';
                                  }
                                  if (remainingCtrl.text.trim().isNotEmpty) {
                                    description += (description.isNotEmpty ? ' · ' : '') + 'Tổng số viên thuốc: ${remainingCtrl.text.trim()}';
                                  }

                                  bool ok = false;
                                  if (editScheduleId != null) {
                                    ok = await ApiService.updateMedication(
                                      scheduleId: editScheduleId,
                                      name: name,
                                      dosage: dosageStr,
                                      instruction: selectedInstruction,
                                      time: selectedTimes.first,
                                      frequency: selectedTimes.length > 1
                                          ? '${selectedTimes.length} lần/ngày'
                                          : 'Hàng ngày',
                                      description: description,
                                      startDate: startStr,
                                      endDate: endStr,
                                    );
                                    // Create new schedules for additional times
                                    for (int i = 1; i < selectedTimes.length; i++) {
                                      await ApiService.addMedication(
                                        elderlyId: elderlyId,
                                        name: name,
                                        dosage: dosageStr,
                                        instruction: selectedInstruction,
                                        time: selectedTimes[i],
                                        frequency: selectedTimes.length > 1
                                            ? '${selectedTimes.length} lần/ngày'
                                            : 'Hàng ngày',
                                        description: description,
                                        startDate: startStr,
                                        endDate: endStr,
                                      );
                                    }
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
                                      
                                      List<String> timesToSave = scannedItem.containsKey('time') 
                                          ? [scannedItem['time'].toString().trim()] 
                                          : selectedTimes;
                                          
                                      for (final t in timesToSave) {
                                        final success =
                                            await ApiService.addMedication(
                                              elderlyId: elderlyId,
                                              name: itemName,
                                              dosage: itemDosage,
                                              instruction: itemInstruction,
                                              time: t,
                                              frequency: selectedTimes.length > 1
                                                  ? '${selectedTimes.length} lần/ngày'
                                                  : 'Hàng ngày',
                                              description: description,
                                              startDate: startStr,
                                              endDate: endStr,
                                            );
                                        if (success) ok = true;
                                      }
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
                                                : '✓ Đã thêm thuốc thành công!',
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

import 'package:flutter/material.dart';
import '../utils/alarm_service.dart';

class MedicationConfirmationScreen extends StatefulWidget {
  final String payload;
  const MedicationConfirmationScreen({super.key, required this.payload});

  @override
  State<MedicationConfirmationScreen> createState() => _MedicationConfirmationScreenState();
}

class _MedicationConfirmationScreenState extends State<MedicationConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Stop the alarm ringing if possible
    _stopAlarm();
  }

  Future<void> _stopAlarm() async {
    await AlarmService.stopAll();
  }

  void _onConfirm() {
    // Xử lý API ghi nhận uống thuốc ở đây nếu cần,
    // Hiện tại chỉ đóng màn hình
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xác nhận uống thuốc thành công')),
    );
    Navigator.of(context).pop();
  }

  void _onSkip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn đã bỏ qua lịch uống thuốc này')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Parse payload (ví dụ: medicine_12345)
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      size: 40,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đến giờ uống thuốc!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng xác nhận bạn đã uống thuốc theo lịch nhắc nhở.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onSkip,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF94A3B8)),
                          ),
                          child: const Text(
                            'Bỏ qua',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

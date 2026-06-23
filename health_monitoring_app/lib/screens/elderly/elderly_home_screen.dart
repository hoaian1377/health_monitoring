import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';

class ElderlyHomeScreen extends StatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  State<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends State<ElderlyHomeScreen> {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  bool _isMedsTakenToday = false;
  bool _showMissedMedsAlert = true;
  bool _isAppointmentNear = false;

  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    int takenCount = 3 + (_isMedsTakenToday ? 1 : 0);
    int preparedCount = (_isCCCDPrepared ? 1 : 0) +
        (_isBHYTPrepared ? 1 : 0) +
        (_isSoKhamPrepared ? 1 : 0) +
        (_isDonThuocPrepared ? 1 : 0) +
        (_isXetNghiemPrepared ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  if (_showMissedMedsAlert) ...[
                    _buildAlertCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildMedCard(takenCount),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(),
                  const SizedBox(height: 16),
                  if (_isAppointmentNear)
                    _buildDocCheckCard(preparedCount),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final name = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;

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
        boxShadow: [BoxShadow(color: Color(0x332563EB), blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xin chào,',
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  'Bác $name 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '☀️  Hãy uống đủ nước hôm nay nhé!',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Nút SOS
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Row(children: [
                    Icon(Icons.phone_in_talk_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Đang gọi khẩn cấp cho con gái...'),
                  ]),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 4),
                const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cảnh báo bỏ lỡ thuốc ──────────────────────────────────────────────────
  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chưa uống thuốc buổi Sáng!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                const SizedBox(height: 4),
                const Text('Amlodipine 07:00 chưa xác nhận. Đã báo con gái.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4)),
                const SizedBox(height: 10),
                Row(children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      setState(() { _showMissedMedsAlert = false; });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('✓ Đã cập nhật! Cảm ơn bác.')),
                      );
                    },
                    child: const Text('Bác đã uống', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() { _showMissedMedsAlert = false; }),
                    child: const Text('Bỏ qua', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ uống thuốc ────────────────────────────────────────────────────────
  Widget _buildMedCard(int takenCount) {
    final bool allDone = takenCount >= 4;
    final double progress = takenCount / 4.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: allDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.check_circle_rounded : Icons.medication_rounded,
                color: allDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Nhắc nhở uống thuốc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
              Text(
                '$takenCount/4 liều',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: allDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                  width: double.infinity, height: 6,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: (MediaQuery.of(context).size.width - 72) * progress,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: allDone
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF0EA5E9), const Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isMedsTakenToday ? Icons.check_circle_rounded : Icons.access_time_rounded,
                size: 20,
                color: _isMedsTakenToday ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Liều tiếp theo: Buổi tối (20:00)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
                    SizedBox(height: 4),
                    Text('Atorvastatin 20mg',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 2),
                    Text('1 viên uống sau ăn', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMedsTakenToday ? const Color(0xFFDCFCE7) : const Color(0xFF0EA5E9),
                foregroundColor: _isMedsTakenToday ? const Color(0xFF16A34A) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() { _isMedsTakenToday = !_isMedsTakenToday; });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: _isMedsTakenToday ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  duration: const Duration(seconds: 1),
                  content: Text(_isMedsTakenToday
                      ? 'Đã xác nhận uống thuốc tối! Chúc bác sức khỏe.'
                      : 'Đã hủy xác nhận uống thuốc tối.'),
                ));
              },
              icon: Icon(_isMedsTakenToday ? Icons.done_rounded : Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                _isMedsTakenToday ? 'Đã uống' : 'Xác nhận uống thuốc',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => MainNavigator.of(context)?.setTab(1),
              child: const Text('Xem toàn bộ lịch uống thuốc',
                  style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ lịch khám tiếp theo ───────────────────────────────────────────────
  Widget _buildAppointmentCard() {
    return GestureDetector(
      onTap: () => MainNavigator.of(context)?.setTab(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Lịch khám sắp tới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Bệnh viện Chợ Rẫy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            const Text('BS. Nguyễn Thị Lan  ·  Tim mạch',
                style: TextStyle(fontSize: 15, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('08:30  ·  Thứ Sáu, 12/06/2026',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
            ]),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => MainNavigator.of(context)?.setTab(2),
                child: const Text('Xem chi tiết',
                    style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thẻ chuẩn bị giấy tờ ─────────────────────────────────────────────────
  Widget _buildDocCheckCard(int preparedCount) {
    final bool isAllPrepared = preparedCount == 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: isAllPrepared ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllPrepared ? Icons.task_alt_rounded : Icons.assignment_rounded,
                color: isAllPrepared ? const Color(0xFF16A34A) : const Color(0xFF0EA5E9),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Chuẩn bị giấy tờ đi khám',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckItem('Căn cước công dân (CCCD)', _isCCCDPrepared,
              (v) => setState(() { _isCCCDPrepared = v ?? false; })),
          _buildCheckItem('Thẻ Bảo hiểm Y tế (BHYT)', _isBHYTPrepared,
              (v) => setState(() { _isBHYTPrepared = v ?? false; })),
          _buildCheckItem('Sổ khám bệnh cũ', _isSoKhamPrepared,
              (v) => setState(() { _isSoKhamPrepared = v ?? false; })),
          _buildCheckItem('Đơn thuốc đang sử dụng', _isDonThuocPrepared,
              (v) => setState(() { _isDonThuocPrepared = v ?? false; })),
          _buildCheckItem('Kết quả xét nghiệm, X-Quang', _isXetNghiemPrepared,
              (v) => setState(() { _isXetNghiemPrepared = v ?? false; })),
          if (isAllPrepared) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Đã chuẩn bị đầy đủ giấy tờ.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF15803D), fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: value, onChanged: onChanged,
                activeColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: value ? Colors.grey : const Color(0xFF1E293B),
                  decoration: value ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

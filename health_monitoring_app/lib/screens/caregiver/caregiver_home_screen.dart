import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/api_service.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  // ── Trạng thái ─────────────────────────────────────────────────────────────
  bool _showMissedMedsAlert = true;
  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showMissedMedsAlert) ...[
                    _buildMissedMedsAlert(),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMedicalRecordCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileCard()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMedicationManagementCard(),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(),
                  const SizedBox(height: 16),
                  _buildHealthTrackingCard(),
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
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chào buổi sáng,',
                        style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Chào $name 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              // Chuông thông báo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                    onPressed: _showNotificationsDialog,
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Nút SOS
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Row(children: [
                        Icon(Icons.phone_in_talk_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Đang thực hiện cuộc gọi khẩn cấp tới con gái...'),
                      ]),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lời khuyên sức khỏe hôm nay:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Hãy uống đủ 2 lít nước và duy trì vận động nhẹ nhàng bác nhé!',
                          style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 11.5, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cảnh báo bỏ lỡ thuốc (xem từ góc caregiver) ──────────────────────────
  Widget _buildMissedMedsAlert() {
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
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bỏ lỡ giờ uống thuốc — Đã báo người thân',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                const SizedBox(height: 4),
                const Text(
                  'Thuốc huyết áp Amlodipine lúc 07:00 chưa được xác nhận. Hệ thống đã tự động gửi tin nhắn.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() { _showMissedMedsAlert = false; }),
                  child: const Text('Đóng', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ Hồ sơ khám bệnh ──────────────────────────────────────────────────
  Widget _buildMedicalRecordCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => MainNavigator.of(context)?.setTab(2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF0EA5E9), size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
                  ],
                ),
                const Spacer(),
                const Text('Hồ sơ khám bệnh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('Quản lý hồ sơ, toa thuốc, X-Quang...',
                    style: TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_rounded, color: Color(0xFF0EA5E9), size: 14),
                      SizedBox(width: 4),
                      Text('Upload hồ sơ', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Thẻ Hồ sơ cá nhân ────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final name = ApiService.currentFullname.isNotEmpty
        ? ApiService.currentFullname
        : ApiService.currentUsername;
    final nameSplit = name.split(' ');
    final shortName = nameSplit.isNotEmpty ? nameSplit.last : name;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => MainNavigator.of(context)?.setTab(4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.badge_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
                  ],
                ),
                const Spacer(),
                Text(
                  shortName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Row(children: [
                  Icon(Icons.bloodtype_outlined, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text('Nhóm máu: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('O+', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                ]),
                const SizedBox(height: 3),
                const Row(children: [
                  Icon(Icons.favorite_border_rounded, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text('Bệnh nền: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Huyết áp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                ]),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Thẻ Quản lý lịch uống thuốc ──────────────────────────────────────────
  Widget _buildMedicationManagementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.medication_rounded, color: Color(0xFFD97706), size: 20),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quản lý Lịch uống thuốc',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Thiết lập & Theo dõi việc uống thuốc',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text('Lịch uống thuốc kế tiếp (20:00)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        SizedBox(height: 6),
                        Text('Atorvastatin 20mg',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 2),
                        Text('Điều trị mỡ máu · 1 viên uống sau ăn',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _showEditDeleteMedicationDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                    ),
                    onPressed: () => MainNavigator.of(context)?.setTab(1),
                    icon: const Icon(Icons.history_rounded, color: Color(0xFF0EA5E9), size: 18),
                    label: const Text('Lịch sử uống', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _showAddMedicationDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm lịch', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Thẻ Lịch khám & giấy tờ ──────────────────────────────────────────────
  Widget _buildAppointmentCard() {
    int preparedCount = (_isCCCDPrepared ? 1 : 0) + (_isBHYTPrepared ? 1 : 0) +
        (_isSoKhamPrepared ? 1 : 0) + (_isDonThuocPrepared ? 1 : 0) + (_isXetNghiemPrepared ? 1 : 0);
    double progress = preparedCount / 5.0;
    bool isAllPrepared = preparedCount == 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LỊCH KHÁM TIẾP THEO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                  SizedBox(height: 4),
                  Text('Bệnh viện Chợ Rẫy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('BS. Nguyễn Thị Lan · Tim mạch · 08:30 ngày 12/06',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chuẩn bị giấy tờ đi khám',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllPrepared ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAllPrepared ? 'Hoàn tất' : '$preparedCount/5 giấy tờ',
                  style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.bold,
                    color: isAllPrepared ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: isAllPrepared ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 14),
          _buildDocCheckItem('Căn cước công dân (CCCD/CMND)', 'Giấy tờ tùy thân để làm thủ tục khám', _isCCCDPrepared,
              (v) => setState(() { _isCCCDPrepared = v ?? false; })),
          _buildDocCheckItem('Thẻ Bảo hiểm Y tế (BHYT)', 'Thẻ BHYT giấy hoặc ứng dụng VssID', _isBHYTPrepared,
              (v) => setState(() { _isBHYTPrepared = v ?? false; })),
          _buildDocCheckItem('Sổ khám bệnh cũ', 'Lịch sử khám bệnh trước đây để bác sĩ tham khảo', _isSoKhamPrepared,
              (v) => setState(() { _isSoKhamPrepared = v ?? false; })),
          _buildDocCheckItem('Đơn thuốc đang sử dụng', 'Các loại thuốc cũ hoặc thực phẩm chức năng đang uống', _isDonThuocPrepared,
              (v) => setState(() { _isDonThuocPrepared = v ?? false; })),
          _buildDocCheckItem('Kết quả xét nghiệm liên quan', 'Phiếu chụp X-Quang, siêu âm, xét nghiệm máu gần nhất', _isXetNghiemPrepared,
              (v) => setState(() { _isXetNghiemPrepared = v ?? false; })),
          if (isAllPrepared) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tuyệt vời! Đã chuẩn bị đầy đủ giấy tờ cần thiết.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocCheckItem(String label, String subtitle, bool value, ValueChanged<bool?> onChanged) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.bold,
                    color: value ? Colors.grey : const Color(0xFF1E293B),
                    decoration: value ? TextDecoration.lineThrough : null,
                  )),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(
                    fontSize: 10.5,
                    color: value ? Colors.grey.shade300 : const Color(0xFF94A3B8),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thẻ Theo dõi sức khỏe ────────────────────────────────────────────────
  Widget _buildHealthTrackingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.monitor_heart_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theo dõi sức khỏe người cao tuổi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Chỉ số sinh hiệu hôm nay',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ]),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                  onPressed: () => MainNavigator.of(context)?.setTab(3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildMetricItem(icon: Icons.heart_broken_rounded, iconColor: Colors.red,
                  label: 'Huyết áp', value: '128/82', unit: ' mmHg',
                  status: 'Hơi cao', statusColor: const Color(0xFFD97706), statusBg: const Color(0xFFFEF3C7))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricItem(icon: Icons.water_drop_rounded, iconColor: Colors.blue,
                  label: 'Đường huyết', value: '5.8', unit: ' mmol/L',
                  status: 'Ổn định', statusColor: const Color(0xFF16A34A), statusBg: const Color(0xFFDCFCE7))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildMetricItem(icon: Icons.favorite_rounded, iconColor: Colors.pinkAccent,
                  label: 'Nhịp tim', value: '76', unit: ' bpm',
                  status: 'Bình thường', statusColor: const Color(0xFF16A34A), statusBg: const Color(0xFFDCFCE7))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricItem(icon: Icons.thermostat_rounded, iconColor: Colors.orange,
                  label: 'Nhiệt độ', value: '36.5', unit: ' °C',
                  status: 'Bình thường', statusColor: const Color(0xFF16A34A), statusBg: const Color(0xFFDCFCE7))),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                onPressed: () => MainNavigator.of(context)?.setTab(3),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Xem phân tích chi tiết chỉ số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 6),
                    Icon(Icons.trending_up_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon, required Color iconColor,
    required String label, required String value, required String unit,
    required String status, required Color statusColor, required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ════════════════════════════════════════════════════════════════════════════

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.notifications_rounded, color: Color(0xFF0284C7), size: 24),
                SizedBox(width: 10),
                Text('Thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildNotifItem(icon: Icons.calendar_today_rounded, iconBg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706),
                      title: 'Lịch tái khám sắp tới',
                      body: 'Ngày 12/06 lúc 08:30 — BV Chợ Rẫy, BS. Nguyễn Thị Lan (Tim mạch). Còn 3 ngày nữa.',
                      time: '2 giờ trước'),
                  _buildNotifItem(icon: Icons.medication_rounded, iconBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF16A34A),
                      title: 'Đã uống thuốc buổi sáng',
                      body: 'Bác đã xác nhận uống Amlodipine 5mg và Atorvastatin 20mg lúc 07:15.',
                      time: '5 giờ trước'),
                  _buildNotifItem(icon: Icons.warning_amber_rounded, iconBg: const Color(0xFFFFE4E6), iconColor: const Color(0xFFDC2626),
                      title: 'Bỏ lỡ thuốc buổi trưa',
                      body: 'Bác chưa xác nhận uống Metformin 500mg lúc 12:00. Hệ thống đã gửi nhắc nhở.',
                      time: 'Hôm qua'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required IconData icon, required Color iconBg, required Color iconColor,
    required String title, required String body, required String time,
  }) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                const SizedBox(height: 6),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicationDialog() {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    String selectedTime = 'Buổi sáng (07:00)';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.add_circle_rounded, color: Color(0xFF0EA5E9), size: 24),
            SizedBox(width: 10),
            Text('Thêm lịch uống thuốc', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên thuốc', hintText: 'Ví dụ: Amlodipine 5mg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doseCtrl,
                  decoration: InputDecoration(
                    labelText: 'Liều dùng', hintText: 'Ví dụ: 1 viên uống sau ăn',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: InputDecoration(
                    labelText: 'Thời gian uống',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF0EA5E9)),
                  ),
                  items: ['Buổi sáng (07:00)', 'Buổi trưa (12:00)', 'Buổi tối (20:00)', 'Trước khi ngủ (22:00)']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedTime = v ?? selectedTime),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('✓ Đã thêm lịch uống thuốc thành công!')));
              },
              child: const Text('Lưu lịch', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDeleteMedicationDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atorvastatin 20mg — 20:00',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            const Text('Điều trị mỡ máu · 1 viên uống sau ăn',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              title: const Text('Chỉnh sửa lịch uống', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Thay đổi tên thuốc, liều dùng, thời gian'),
              onTap: () { Navigator.pop(ctx); _showAddMedicationDialog(); },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: const Text('Xóa lịch uống thuốc',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              subtitle: const Text('Xóa vĩnh viễn lịch uống này'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Đã xóa lịch uống thuốc Atorvastatin 20mg lúc 20:00')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

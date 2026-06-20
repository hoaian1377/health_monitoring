import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/global_state.dart';
import '../utils/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMedsTakenToday = false; // Trạng thái uống thuốc tối (Atorvastatin)
  int _imageCount = 3; // Số lượng hình ảnh mô phỏng trong nhật ký
  
  // Trạng thái chuẩn bị giấy tờ đi khám (F05)
  bool _isCCCDPrepared = false;
  bool _isBHYTPrepared = false;
  bool _isSoKhamPrepared = false;
  bool _isDonThuocPrepared = false;
  bool _isXetNghiemPrepared = false;
  
  // Trạng thái hiển thị cảnh báo bỏ lỡ uống thuốc (F03)
  bool _showMissedMedsAlert = true;
  final List<String> _simulatedImages = [
    'Toa_thuoc_BvChoRay.jpg',
    'X_Quang_Phoi.png',
    'Xet_nghiem_mau.jpg',
  ];

  void _showCameraMock() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhật ký Hình ảnh Sức khỏe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chụp ảnh đơn thuốc, kết quả xét nghiệm hoặc tình trạng sức khỏe để lưu trữ và phân tích AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF0EA5E9),
                      label: 'Chụp ảnh mới',
                      onTap: () {
                        Navigator.pop(context);
                        _simulateImageUpload();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF10B981),
                      label: 'Chọn từ thư viện',
                      onTap: () {
                        Navigator.pop(context);
                        _simulateImageUpload();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Image Log History Preview inside Dialog
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hình ảnh gần đây',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _simulatedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade200, Colors.grey.shade300],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, size: 20, color: Color(0xFF64748B)),
                          const SizedBox(height: 4),
                          Text(
                            _simulatedImages[index].split('_').last,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _simulateImageUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Đang quét ảnh và trích xuất dữ liệu y tế...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _imageCount++;
          _simulatedImages.insert(0, 'Anh_don_thuoc_$_imageCount.jpg');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã thêm hình ảnh thành công!'),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số lượng thuốc đã uống
    int takenCount = 3 + (_isMedsTakenToday ? 1 : 0);
    double medsProgress = takenCount / 4.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // ── Beautiful Custom Header ──
          _buildHeader(),

          // ── Main Content Area ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cảnh báo bỏ lỡ thuốc buổi sáng (F03/F08)
                  if (_showMissedMedsAlert) ...[
                    _buildMissedMedsAlert(),
                    const SizedBox(height: 16),
                  ],

                  // 1. Grid of Image Diary and Personal Profile
                  if (ApiService.currentRole == 'elderly')
                    _buildProfileCard()
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Card: "Hình ảnh" (Nhật ký ảnh)
                        Expanded(
                          child: _buildImageDiaryCard(),
                        ),
                        const SizedBox(width: 12),
                        // Right Card: "Thông tin cá nhân"
                        Expanded(
                          child: _buildProfileCard(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // 2. Medication Reminder Card
                  _buildMedicationReminderCard(takenCount, medsProgress),
                  const SizedBox(height: 16),

                  // 2B. Lịch khám tiếp theo & Chuẩn bị giấy tờ (F04/F05)
                  _buildUpcomingAppointmentCard(),
                  const SizedBox(height: 16),

                  // 3. Dashboard Preview Card (Only for caregiver)
                  if (ApiService.currentRole != 'elderly')
                    _buildDashboardPreviewCard(),
                ],
              ),
            ),
          ),
        ],
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
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào buổi sáng,',
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final name = ApiService.currentFullname.isNotEmpty
                          ? ApiService.currentFullname
                          : ApiService.currentUsername;
                      return Text(
                        'Chào $name 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
              // Emergency SOS Button in Header
              InkWell(
                onTap: () {
                  // Switch to Profile Tab to call SOS or simulate direct call
                  MainNavigator.of(context)?.setTab(4);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Đang chuyển đến liên hệ khẩn cấp...'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Health status banner inside header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lời khuyên sức khỏe hôm nay:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hãy uống đủ 2 lít nước và duy trì vận động nhẹ nhàng bác nhé!',
                        style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 11.5, height: 1.3),
                      ),
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

  // 1A. Left Card - "Hình ảnh" (Nhật ký ảnh)
  Widget _buildImageDiaryCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _showCameraMock,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0EA5E9), size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
                  ],
                ),
                const Spacer(),
                // Text info
                const Text(
                  'Nhật ký ảnh',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã lưu $_imageCount hình ảnh sức khỏe',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                // Action Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, color: Color(0xFF0EA5E9), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Chụp ảnh',
                        style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1B. Right Card - "Thông tin cá nhân"
  Widget _buildProfileCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Switch to Profile Tab (index 4)
            MainNavigator.of(context)?.setTab(4);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
                  ],
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final name = ApiService.currentFullname.isNotEmpty
                        ? ApiService.currentFullname
                        : ApiService.currentUsername;
                    final nameSplit = name.split(' ');
                    final shortName = nameSplit.isNotEmpty ? nameSplit.last : name;
                    return Text(
                      ApiService.currentRole == 'caregiver' ? shortName : 'Bác $shortName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                ),
                const SizedBox(height: 6),
                // Health Quick Specs
                Row(
                  children: [
                    const Icon(Icons.bloodtype_outlined, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    const Text('Nhóm máu: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const Text('O+', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, color: Colors.blueGrey, size: 14),
                    const SizedBox(width: 4),
                    const Text('Cân nặng: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const Text('62 kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    const Text('Bệnh nền: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const Expanded(
                      child: Text(
                        'Huyết áp',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Medication Reminder Card
  Widget _buildMedicationReminderCard(int takenCount, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Color(0xFFD97706), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhắc nhở uống thuốc',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hôm nay bác cần uống 4 liều thuốc',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Text Progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progress == 1.0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$takenCount/4 liều',
                    style: TextStyle(
                      color: progress == 1.0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: ((MediaQuery.of(context).size.width - 72) * progress).clamp(0.0, double.infinity),
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: progress == 1.0
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF0EA5E9), const Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Next Dose Status Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isMedsTakenToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              size: 16,
                              color: _isMedsTakenToday ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Liều kế tiếp: Buổi tối (20:00)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Atorvastatin 20mg',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Điều trị mỡ máu · 1 viên uống sau ăn',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirmation Check Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isMedsTakenToday = !_isMedsTakenToday;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: _isMedsTakenToday ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          duration: const Duration(seconds: 1),
                          content: Text(
                            _isMedsTakenToday
                                ? 'Đã xác nhận uống thuốc tối! Chúc bác sức khỏe.'
                                : 'Đã hủy xác nhận uống thuốc tối.',
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isMedsTakenToday ? const Color(0xFFDCFCE7) : const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isMedsTakenToday
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMedsTakenToday ? Icons.done_rounded : Icons.check_circle_outline_rounded,
                            color: _isMedsTakenToday ? const Color(0xFF16A34A) : Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isMedsTakenToday ? 'Đã uống' : 'Uống thuốc',
                            style: TextStyle(
                              color: _isMedsTakenToday ? const Color(0xFF16A34A) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Link to Checklist screen
            InkWell(
              onTap: () {
                // Switch to Checklist tab (index 1)
                MainNavigator.of(context)?.setTab(1);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Xem toàn bộ lịch uống thuốc & checklist hôm nay',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF0EA5E9), size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Dashboard Preview Card
  Widget _buildDashboardPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dashboard_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Sức khỏe',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chỉ số sinh hiệu hôm nay',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                  onPressed: () {
                    MainNavigator.of(context)?.setTab(3); // Dashboard screen is index 3
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics Mini Grid
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetricItem(
                    icon: Icons.heart_broken_rounded,
                    iconColor: Colors.red,
                    label: 'Huyết áp',
                    value: '128/82',
                    unit: ' mmHg',
                    status: 'Hơi cao',
                    statusColor: const Color(0xFFD97706),
                    statusBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniMetricItem(
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blue,
                    label: 'Đường huyết',
                    value: '5.8',
                    unit: ' mmol/L',
                    status: 'Ổn định',
                    statusColor: const Color(0xFF16A34A),
                    statusBg: const Color(0xFFDCFCE7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // View analytics button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Switch to Dashboard Tab
                  MainNavigator.of(context)?.setTab(3);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem phân tích chi tiết chỉ số',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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

  Widget _buildMiniMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required Color statusBg,
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
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // Cảnh báo bỏ lỡ thuốc buổi sáng (F03/F08)
  Widget _buildMissedMedsAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bỏ lỡ giờ uống thuốc — Đã báo người thân',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thuốc huyết áp Amlodipine lúc 07:00 chưa được xác nhận. Hệ thống đã tự động gửi tin nhắn báo cho con gái (Nguyễn Thị Bình).',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        setState(() {
                          _showMissedMedsAlert = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('✓ Đã cập nhật trạng thái uống thuốc và gửi tin báo đến người thân!'),
                          ),
                        );
                      },
                      child: const Text('Bác đã uống', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showMissedMedsAlert = false;
                        });
                      },
                      child: const Text('Bỏ qua', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ Lịch khám bệnh sắp tới & Chuẩn bị giấy tờ (F04/F05)
  Widget _buildUpcomingAppointmentCard() {
    int preparedCount = (_isCCCDPrepared ? 1 : 0) +
                        (_isBHYTPrepared ? 1 : 0) +
                        (_isSoKhamPrepared ? 1 : 0) +
                        (_isDonThuocPrepared ? 1 : 0) +
                        (_isXetNghiemPrepared ? 1 : 0);
    double progress = preparedCount / 5.0;
    bool isAllPrepared = preparedCount == 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'LỊCH KHÁM TIẾP THEO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bệnh viện Chợ Rẫy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'BS. Nguyễn Thị Lan · Tim mạch · 08:30 ngày 12/06',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Checklist section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chuẩn bị giấy tờ đi khám (F05)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
               ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllPrepared ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAllPrepared ? 'Hoàn tất' : '$preparedCount/5 giấy tờ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
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
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: isAllPrepared ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 14),

          // Checkbox list
          _buildDocCheckItem(
            label: 'Căn cước công dân (CCCD/CMND)',
            subtitle: 'Giấy tờ tùy thân để làm thủ tục khám',
            value: _isCCCDPrepared,
            onChanged: (val) {
              setState(() {
                _isCCCDPrepared = val ?? false;
              });
            },
          ),
          _buildDocCheckItem(
            label: 'Thẻ Bảo hiểm Y tế (BHYT)',
            subtitle: 'Thẻ BHYT giấy hoặc ứng dụng VssID',
            value: _isBHYTPrepared,
            onChanged: (val) {
              setState(() {
                _isBHYTPrepared = val ?? false;
              });
            },
          ),
          _buildDocCheckItem(
            label: 'Sổ khám bệnh cũ',
            subtitle: 'Lịch sử khám bệnh trước đây để bác sĩ tham khảo',
            value: _isSoKhamPrepared,
            onChanged: (val) {
              setState(() {
                _isSoKhamPrepared = val ?? false;
              });
            },
          ),
          _buildDocCheckItem(
            label: 'Đơn thuốc đang sử dụng',
            subtitle: 'Các loại thuốc cũ hoặc thực phẩm chức năng đang uống',
            value: _isDonThuocPrepared,
            onChanged: (val) {
              setState(() {
                _isDonThuocPrepared = val ?? false;
              });
            },
          ),
          _buildDocCheckItem(
            label: 'Các kết quả xét nghiệm liên quan',
            subtitle: 'Phiếu chụp X-Quang, siêu âm, xét nghiệm máu gần nhất',
            value: _isXetNghiemPrepared,
            onChanged: (val) {
              setState(() {
                _isXetNghiemPrepared = val ?? false;
              });
            },
          ),

          if (isAllPrepared) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tuyệt vời! Bác đã chuẩn bị đầy đủ giấy tờ cần thiết cho lịch khám sắp tới.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocCheckItem({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: value ? Colors.grey : const Color(0xFF1E293B),
                      decoration: value ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: value ? Colors.grey.shade300 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

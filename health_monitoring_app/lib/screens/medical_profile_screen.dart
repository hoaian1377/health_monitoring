import 'package:flutter/material.dart';


class MedicalProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const MedicalProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  // Bệnh nền
  final List<String> _conditions = ['Tăng huyết áp', 'Tiểu đường type 2'];
  // Dị ứng
  final List<String> _allergies = ['Penicillin', 'Aspirin'];

  // BMI
  double get _bmi => 62 / (1.68 * 1.68); // 21.98

  String get _bmiLabel {
    if (_bmi < 18.5) return 'Thiếu cân';
    if (_bmi < 25) return 'Bình thường';
    if (_bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return const Color(0xFFD97706);
    if (_bmi < 25) return const Color(0xFF16A34A);
    if (_bmi < 30) return const Color(0xFFEA580C);
    return const Color(0xFFC81E1E);
  }

  void _showAddConditionDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm bệnh nền'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Nhập tên bệnh...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(
                    () => _conditions.add(ctrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9)),
            child: const Text('Thêm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAllergyDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm dị ứng'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Nhập tên chất dị ứng...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _allergies.add(ctrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9)),
            child: const Text('Thêm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF0EA5E9);
    const gradientColors = [Color(0xFF0284C7), Color(0xFF38BDF8)];

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, widget.isEmbedded ? 16 : 0, 16, 100),
      child: Column(
        children: [
          // Nếu không nhúng (không phải trong TabView) thì hiển thị Header
          if (!widget.isEmbedded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: -16, right: -16, bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hồ sơ khám bệnh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Column(
            children: [
              // Card: Thông tin y tế cơ bản
              _buildCard(
                title: 'Thông tin y tế cơ bản',
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFDC2626),
                child: Column(
                  children: [
                    _infoTile('🩸', 'Nhóm máu', 'A+',
                        const Color(0xFFFFEBEB), const Color(0xFFC81E1E)),
                    _divider(),
                    _infoTile('📏', 'Chiều cao', '168 cm',
                        const Color(0xFFEBF3FF), const Color(0xFF0EA5E9)),
                    _divider(),
                    _infoTile('⚖️', 'Cân nặng', '62 kg',
                        const Color(0xFFFFF4E6), const Color(0xFFEA580C)),
                    _divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6FBF3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text('📊',
                                style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('BMI',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8))),
                                Text(_bmi.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bmiColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_bmiLabel,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _bmiColor)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card: Bệnh nền
              _buildCard(
                title: 'Bệnh nền',
                icon: Icons.sick_rounded,
                iconColor: const Color(0xFFC81E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._conditions.map((c) => _conditionPill(c)),
                      GestureDetector(
                        onTap: _showAddConditionDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF0EA5E9),
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Color(0xFF0EA5E9), size: 16),
                              SizedBox(width: 4),
                              Text('Thêm',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF0EA5E9),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card: Dị ứng
              _buildCard(
                title: 'Dị ứng',
                icon: Icons.warning_rounded,
                iconColor: const Color(0xFFD97706),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._allergies.map((a) => _allergyPill(a)),
                      GestureDetector(
                        onTap: _showAddAllergyDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFD97706)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Color(0xFFD97706), size: 16),
                              SizedBox(width: 4),
                              Text('Thêm',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card: Tiền sử bệnh
              _buildCard(
                title: 'Tiền sử bệnh',
                icon: Icons.history_edu_rounded,
                iconColor: const Color(0xFF7C3AED),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _timelineItem('2020',
                          'Phẫu thuật đục thủy tinh thể mắt trái',
                          isLast: false),
                      _timelineItem('2018', 'Nhồi máu cơ tim nhẹ',
                          isLast: false),
                      _timelineItem(
                          '2015', 'Phát hiện tiểu đường type 2',
                          isLast: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card: Tài liệu y tế
              _buildCard(
                title: 'Tài liệu y tế',
                icon: Icons.folder_open_rounded,
                iconColor: const Color(0xFF0EA5E9),
                child: Column(
                  children: [
                    _fileItem('Toa thuốc 05/2025.pdf', '12/05/2025'),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _fileItem(
                        'Xét nghiệm máu 03/2025.pdf', '22/03/2025'),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file_rounded,
                            size: 18),
                        label: const Text('Upload tài liệu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0EA5E9),
                          side: const BorderSide(
                              color: Color(0xFF0EA5E9)),
                          minimumSize:
                              const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: content,
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: iconColor)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(
      String emoji, String label, String value, Color bg, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Navigator.canPop(context) ? const SizedBox() : const SizedBox(), // Keep structure similar
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conditionPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF791F1F),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _allergyPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF633806),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _timelineItem(String year, String text, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFEDE9FE), width: 2),
              ),
            ),
            if (!isLast)
              Container(
                  width: 2, height: 40, color: const Color(0xFFEDE9FE)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(year,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED))),
                ),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fileItem(String name, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded,
              color: Color(0xFF0EA5E9), size: 18),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 62, color: Color(0xFFF1F5F9));
}

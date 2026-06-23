import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class MedicalDocumentsScreen extends StatefulWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  State<MedicalDocumentsScreen> createState() =>
      _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends State<MedicalDocumentsScreen> {
  int _filterIndex = 0; // 0=Tất cả, 1=Toa thuốc, 2=Xét nghiệm
  final List<String> _filters = ['Tất cả', 'Toa thuốc', 'Xét nghiệm'];
  final _searchCtrl = TextEditingController();

  final List<_DocFile> _allDocs = [
    _DocFile(
        name: 'Toa thuốc 05/2025.pdf',
        date: '12/05/2025',
        size: '1.2 MB',
        type: 'Toa thuốc'),
    _DocFile(
        name: 'Xét nghiệm máu 03/2025.pdf',
        date: '22/03/2025',
        size: '3.8 MB',
        type: 'Xét nghiệm'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final docs = await ApiService.getMedicalDocument();
    if (docs.isNotEmpty) {
      setState(() {
        _allDocs.clear();
        for (var doc in docs) {
          String type = doc['document_type'] ?? 'Khác';
          if (!['Toa thuốc', 'Xét nghiệm'].contains(type)) {
             type = 'Toa thuốc'; 
          }
          String date = 'N/A';
          if (doc['upload_at'] != null) {
            try {
               DateTime dt = DateTime.parse(doc['upload_at']);
               date = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
            } catch (e) {}
          }
          _allDocs.add(_DocFile(
            name: doc['file_url']?.split('/').last ?? 'Tai_lieu_${doc['medical_documentid']}.pdf',
            date: date,
            size: 'N/A',
            type: type,
          ));
        }
      });
    }
  }

  List<_DocFile> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _allDocs.where((d) {
      final matchFilter = _filterIndex == 0 ||
          d.type == _filters[_filterIndex];
      final matchSearch = q.isEmpty || d.name.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toa thuốc & Xét nghiệm',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Tài liệu y tế của bạn',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.description_rounded,
                        color: Colors.white70, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Tìm tài liệu...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: _filters.asMap().entries.map((e) {
                    final selected = e.key == _filterIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _filterIndex = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? const Color(0xFF0EA5E9)
                                    : Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy tài liệu',
                        style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildDocCard(_filtered[i]),
                  ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chọn file để upload...'),
            duration: Duration(seconds: 2),
          ));
        },
        backgroundColor: const Color(0xFF0EA5E9),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildDocCard(_DocFile doc) {
    final isToa = doc.type == 'Toa thuốc';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isToa ? const Color(0xFFEBF3FF) : const Color(0xFFE6FBF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color:
                  isToa ? const Color(0xFF0EA5E9) : const Color(0xFF0D9488),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(doc.date,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    const Text(' · ',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                    Text(doc.size,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isToa
                        ? const Color(0xFFEBF3FF)
                        : const Color(0xFFE0F7F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(doc.type,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToa
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFF0D9488))),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _iconBtn(Icons.visibility_outlined, const Color(0xFF0EA5E9),
                  const Color(0xFFEBF3FF), () {}),
              const SizedBox(height: 8),
              _iconBtn(Icons.download_rounded, const Color(0xFF16A34A),
                  const Color(0xFFE6FBF3), () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _DocFile {
  final String name, date, size, type;
  const _DocFile(
      {required this.name,
      required this.date,
      required this.size,
      required this.type});
}

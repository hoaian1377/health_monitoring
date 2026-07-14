import 'package:flutter/material.dart';
import '../../../utils/elderly_provider.dart';
import 'elderly_selection_sheet.dart';

/// A compact, persistent bar showing the currently selected elderly person.
/// Tap to open the [ElderlySelectionSheet] for switching between elderly.
///
/// Place this widget above the main content area in the caregiver layout.
class ElderlySwitcherBar extends StatelessWidget {
  final ElderlyProvider provider;

  const ElderlySwitcherBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        if (!provider.hasElderly) {
          return _buildEmptyState(context);
        }
        return _buildSwitcherBar(context);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa có người cao tuổi. Hãy thêm người cao tuổi để bắt đầu quản lý.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherBar(BuildContext context) {
    final elderly = provider.selectedElderly;
    final name = elderly?['fullname']?.toString() ?? 'Chọn người cao tuổi';
    final dobStr = elderly?['date_of_birthday']?.toString();
    final age = ElderlyProvider.calculateAge(dobStr);
    final gender = elderly?['gender'];
    final bloodType = elderly?['blood_type']?.toString();
    final elderlyCount = provider.elderlyList.length;

    // Get initials for avatar
    final nameParts = name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : (nameParts.isNotEmpty ? nameParts.first[0].toUpperCase() : '?');

    // Avatar color based on selected elderly index
    final colorIndex = provider.elderlyList.indexWhere(
        (e) => e['id'] == provider.selectedElderlyId);
    final avatarColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
    ];
    final avatarColor = avatarColors[colorIndex.clamp(0, avatarColors.length - 1) % avatarColors.length];

    return GestureDetector(
      onTap: () => _showSelectionSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: avatarColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: avatarColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor.withValues(alpha: 0.8), avatarColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đang chăm sóc',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (age != null) ...[
                        Icon(
                          gender == true ? Icons.male_rounded : Icons.female_rounded,
                          size: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$age tuổi',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (age != null && bloodType != null && bloodType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·',
                            style: TextStyle(
                              color: const Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (bloodType != null && bloodType.isNotEmpty) ...[
                        const Icon(Icons.bloodtype_rounded, size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 2),
                        Text(
                          bloodType,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),


            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đổi',
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.unfold_more_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ElderlySelectionSheet(provider: provider),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../utils/elderly_provider.dart';

/// Beautiful bottom sheet for selecting an elderly person.
/// Shows card-based list with avatar, name, age, health info, and selection state.
class ElderlySelectionSheet extends StatelessWidget {
  final ElderlyProvider provider;

  const ElderlySelectionSheet({super.key, required this.provider});

  static const _avatarColors = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
  ];

  @override
  Widget build(BuildContext context) {
    final list = provider.elderlyList;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn người cao tuổi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Đang quản lý ${list.length} người',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Elderly List ──
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
              itemCount: list.length,
              itemBuilder: (ctx, index) =>
                  _buildElderlyCard(context, list[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElderlyCard(
    BuildContext context,
    Map<String, dynamic> elderly,
    int index,
  ) {
    final elderlyId = elderly['id'] as int;
    final isSelected = elderlyId == provider.selectedElderlyId;
    final name = elderly['fullname']?.toString() ?? 'N/A';
    final dobStr = elderly['date_of_birthday']?.toString();
    final age = ElderlyProvider.calculateAge(dobStr);
    final gender = elderly['gender'];
    final bloodType = elderly['blood_type']?.toString();
    final conditions = elderly['underlying_conditions']?.toString();
    final allergies = elderly['allergies']?.toString();

    // Avatar
    final nameParts = name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : (nameParts.isNotEmpty ? nameParts.first[0].toUpperCase() : '?');
    final avatarColor = _avatarColors[index % _avatarColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            provider.switchElderly(elderlyId);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? avatarColor.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: avatarColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // ── Avatar ──
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        avatarColor,
                        avatarColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
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
                    children: [
                      // Name
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isSelected
                              ? avatarColor
                              : const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Age + Gender + Blood type
                      Row(
                        children: [
                          if (age != null) ...[
                            _infoPill(
                              icon: gender == true
                                  ? Icons.male_rounded
                                  : Icons.female_rounded,
                              iconColor: gender == true
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFEC4899),
                              text: '$age tuổi',
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (bloodType != null && bloodType.isNotEmpty)
                            _infoPill(
                              icon: Icons.bloodtype_rounded,
                              iconColor: const Color(0xFFEF4444),
                              text: bloodType,
                            ),
                        ],
                      ),

                      // Conditions
                      if (conditions != null && conditions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_information_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                conditions,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Allergies
                      if (allergies != null && allergies.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Dị ứng: $allergies',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDC2626),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Selection indicator ──
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? avatarColor
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: avatarColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

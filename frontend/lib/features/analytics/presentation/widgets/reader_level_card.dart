import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/journey_models.dart';

/// Card displaying the user's current reading level, points progress, and next tier.
class ReaderLevelCard extends StatelessWidget {
  final int currentLevel;
  final String levelTitle;
  final int currentPoints;
  final int targetPoints;
  final String nextTierTitle;

  const ReaderLevelCard({
    super.key,
    this.currentLevel = 4,
    this.levelTitle = 'Thoughtful reader',
    this.currentPoints = 720,
    this.targetPoints = 1000,
    this.nextTierTitle = 'Book sage',
  });

  static const List<ReaderLevelTier> _allTiers = [
    ReaderLevelTier(
      level: 1,
      title: 'Curious page-turner',
      minPoints: 0,
      maxPoints: 200,
      description: 'Taking your first steps into a daily reading habit.',
    ),
    ReaderLevelTier(
      level: 2,
      title: 'Steady reader',
      minPoints: 200,
      maxPoints: 450,
      description: 'Building momentum one chapter at a time.',
    ),
    ReaderLevelTier(
      level: 3,
      title: 'Chapter explorer',
      minPoints: 450,
      maxPoints: 700,
      description: 'Diving deep into stories and ideas across genres.',
    ),
    ReaderLevelTier(
      level: 4,
      title: 'Thoughtful reader',
      minPoints: 700,
      maxPoints: 1000,
      description: 'Reflecting deeply and sharing inspiration with your circle.',
    ),
    ReaderLevelTier(
      level: 5,
      title: 'Book sage',
      minPoints: 1000,
      maxPoints: 1500,
      description: 'A seasoned reader whose library inspires the community.',
    ),
  ];

  void _showTiersModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reading Ranks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Earn points by completing reading sessions and maintaining your streak.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._allTiers.map((tier) {
              final isCurrent = tier.level == currentLevel;
              final isUnlocked = tier.level <= currentLevel;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF557A68)
                            : (isUnlocked
                                ? const Color(0xFFE8EEEA)
                                : AppColors.background),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${tier.level}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? Colors.white
                              : (isUnlocked
                                  ? AppColors.primary
                                  : AppColors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            tier.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4C6E5D),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingPoints = (targetPoints - currentPoints).clamp(0, targetPoints);
    final progress = targetPoints > 0
        ? (currentPoints / targetPoints).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () => _showTiersModal(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF2EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Sprout badge + Level title + Chevron ─
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF4C6E5D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL $currentLevel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: const Color(0xFF5A7E6F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Points & Next Tier Row ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentPoints / 1,000 points',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Next: $nextTierTitle',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A7E6F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Linear Progress Bar ────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF557A68),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Remaining Points Caption ───────────────────────
            Text(
              '$remainingPoints points to your next chapter.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

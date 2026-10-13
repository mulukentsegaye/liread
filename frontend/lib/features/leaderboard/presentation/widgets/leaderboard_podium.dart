import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leaderboard_models.dart';

/// Top-3 podium showcasing the leading readers for the selected period.
class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntry> topThree;
  final LeaderboardPeriod period;

  const LeaderboardPodium({
    super.key,
    required this.topThree,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.length < 3) return const SizedBox.shrink();

    final first = topThree[0];
    final second = topThree[1];
    final third = topThree[2];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── #2 Place (Left) ────────────────────────────────
          Expanded(
            child: _PodiumColumn(
              entry: second,
              rank: 2,
              period: period,
              pedestalHeight: 44,
              pedestalColor: const Color(0xFFE4EAE6),
              badgeColor: const Color(0xFF6B8577),
            ),
          ),
          const SizedBox(width: 10),

          // ── #1 Place (Center Leader) ───────────────────────
          Expanded(
            child: _PodiumColumn(
              entry: first,
              rank: 1,
              period: period,
              pedestalHeight: 64,
              pedestalColor: const Color(0xFF557A68),
              badgeColor: const Color(0xFFC59B27),
              isFirst: true,
            ),
          ),
          const SizedBox(width: 10),

          // ── #3 Place (Right) ───────────────────────────────
          Expanded(
            child: _PodiumColumn(
              entry: third,
              rank: 3,
              period: period,
              pedestalHeight: 32,
              pedestalColor: const Color(0xFFEDF2EE),
              badgeColor: const Color(0xFF9C7A54),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final LeaderboardPeriod period;
  final double pedestalHeight;
  final Color pedestalColor;
  final Color badgeColor;
  final bool isFirst;

  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.period,
    required this.pedestalHeight,
    required this.pedestalColor,
    required this.badgeColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isFirst ? 56.0 : 46.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon for #1 leader
        if (isFirst) ...[
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFC59B27),
            size: 22,
          ),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 26),

        // Avatar with rank badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFirst
                      ? const Color(0xFFC59B27)
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: isFirst ? 2.0 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                entry.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isFirst ? 16 : 13,
                  fontWeight: FontWeight.w700,
                  color: entry.isCurrentUser ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          entry.isCurrentUser ? '${entry.name.split(' ').first} (You)' : entry.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Reading time pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            entry.formattedTimeFor(period),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4C6E5D),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pedestal bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: pedestalHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pedestalColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFirst ? Colors.white : const Color(0xFF4C6E5D),
            ),
          ),
        ),
      ],
    );
  }
}

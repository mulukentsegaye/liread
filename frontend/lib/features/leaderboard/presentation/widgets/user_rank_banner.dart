import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leaderboard_models.dart';

/// Highlighted card displaying the current user's live standing and progress to the next rank.
class UserRankBanner extends StatelessWidget {
  final LeaderboardEntry userEntry;
  final int userRank;
  final LeaderboardEntry? nextHigherEntry;
  final LeaderboardPeriod period;

  const UserRankBanner({
    super.key,
    required this.userEntry,
    required this.userRank,
    required this.nextHigherEntry,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final gapSeconds = nextHigherEntry != null
        ? (nextHigherEntry!.secondsFor(period) - userEntry.secondsFor(period) + 60)
            .clamp(60, 999999)
        : 0;

    final subtitle = userRank == 1
        ? 'You are leading the circle!'
        : '${LeaderboardEntry.formatSeconds(gapSeconds)} to overtake #${userRank - 1} ${nextHigherEntry!.name.split(' ').first}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank circle badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$userRank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Standing title & gap subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR STANDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEntry.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Total time for active period
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userEntry.formattedTimeFor(period),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _periodLabel(period),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _periodLabel(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return 'Today';
      case LeaderboardPeriod.weekly:
        return 'This week';
      case LeaderboardPeriod.yearly:
        return 'This year';
    }
  }
}

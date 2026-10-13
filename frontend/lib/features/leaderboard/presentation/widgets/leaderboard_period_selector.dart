import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leaderboard_models.dart';

/// 3-way segmented control for switching between Daily rank, Weekly rank, and Yearly rank.
class LeaderboardPeriodSelector extends StatelessWidget {
  final LeaderboardPeriod selectedPeriod;
  final ValueChanged<LeaderboardPeriod> onPeriodChanged;

  const LeaderboardPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegment(
            label: 'Daily rank',
            period: LeaderboardPeriod.daily,
          ),
          _buildSegment(
            label: 'Weekly rank',
            period: LeaderboardPeriod.weekly,
          ),
          _buildSegment(
            label: 'Yearly rank',
            period: LeaderboardPeriod.yearly,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required LeaderboardPeriod period,
  }) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFD5E0DA),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF4C6E5D)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

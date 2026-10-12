import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/journey_models.dart';

/// 3-way segmented control for switching between "This week", "This month", and "This year".
class PeriodSelector extends StatelessWidget {
  final JourneyPeriod selectedPeriod;
  final ValueChanged<JourneyPeriod> onPeriodChanged;

  const PeriodSelector({
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
            label: 'This week',
            period: JourneyPeriod.week,
          ),
          _buildSegment(
            label: 'This month',
            period: JourneyPeriod.month,
          ),
          _buildSegment(
            label: 'This year',
            period: JourneyPeriod.year,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required JourneyPeriod period,
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

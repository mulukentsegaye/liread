import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/journey_models.dart';

/// "A steady rhythm" weekly reading bar chart + 7-day streak banner.
class WeeklyRhythmChart extends StatefulWidget {
  final List<DailyReadingBar> bars;
  final String totalTime;
  final String trendText;
  final int streakDays;

  const WeeklyRhythmChart({
    super.key,
    required this.bars,
    this.totalTime = '3h 36m',
    this.trendText = '↗ 18% from last week',
    this.streakDays = 7,
  });

  @override
  State<WeeklyRhythmChart> createState() => _WeeklyRhythmChartState();
}

class _WeeklyRhythmChartState extends State<WeeklyRhythmChart> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Default to Sunday (last bar) matching the screenshot
    _selectedIndex = widget.bars.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title Row ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'A steady rhythm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'This week',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A7E6F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Total Weekly Time & Trend Row ──────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.totalTime,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.trendText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A7E6F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── 7-Day Bar Chart ────────────────────────────────
        SizedBox(
          height: 132,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.bars.length, (index) {
              final bar = widget.bars[index];
              final isSelected = index == _selectedIndex;
              final barHeight = (bar.normalizedHeight * 100).clamp(18.0, 100.0);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Animated bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF557A68)
                              : const Color(0xFFE4EAE6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Day label (M, T, W, T, F, S, S)
                      Text(
                        bar.dayLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF557A68)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

        // ── Streak Row ─────────────────────────────────────
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 20,
              color: Color(0xFF557A68),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.streakDays}-day reading streak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              'Keep it growing',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

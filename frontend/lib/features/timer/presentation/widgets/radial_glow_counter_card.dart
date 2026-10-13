import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/timer_theme_model.dart';
import 'arched_dial_gauge_painter.dart';
import 'rolling_digit_counter.dart';

/// Squircle glass card with graduated radial arched dial, bottom horizon glow,
/// dynamic rolling digits, and reading focus copy inspired directly by the design.
class RadialGlowCounterCard extends StatelessWidget {
  final CounterThemeConfig theme;
  final double progress; // 0.0 to 1.0
  final int elapsedSeconds;
  final int goalMinutes;
  final String bookTitle;
  final bool isRunning;

  const RadialGlowCounterCard({
    super.key,
    required this.theme,
    required this.progress,
    required this.elapsedSeconds,
    required this.goalMinutes,
    required this.bookTitle,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      height: 310,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: theme.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (theme.isDark && theme.glowColors.isNotEmpty)
            BoxShadow(
              color: theme.glowColors.last.withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── 1. Bottom Ambient Horizon Glow ───────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: theme.glowColors,
                  ),
                ),
              ),
            ),

            // ── 2. Content Column ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                children: [
                  // Top Typographic Heading
                  Text(
                    isRunning ? 'In Your Flow' : 'Mindful Reading',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                      children: [
                        const TextSpan(text: 'Today With '),
                        TextSpan(
                          text: bookTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'And Pages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor.withValues(alpha: 0.85),
                    ),
                  ),

                  const Spacer(),

                  // Arched Radial Dial Gauge
                  SizedBox(
                    width: 250,
                    height: 90,
                    child: CustomPaint(
                      painter: ArchedDialGaugePainter(
                        progress: progress,
                        tickColor: theme.tickColor,
                        activeTickColor: theme.activeTickColor,
                        needleColor: theme.needleColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Dynamic Rolling Digits with number-drop animation
                  RollingDigitCounter(
                    totalSeconds: elapsedSeconds,
                    textStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryTextColor,
                    ),
                    colonColor: theme.primaryTextColor.withValues(alpha: 0.7),
                  ),

                  const SizedBox(height: 4),

                  // Goal subtitle
                  Text(
                    'of your $goalMinutes min goal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

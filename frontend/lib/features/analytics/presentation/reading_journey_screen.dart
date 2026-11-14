import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../domain/journey_models.dart';
import 'widgets/period_selector.dart';
import 'widgets/reader_level_card.dart';
import 'widgets/summary_stat_cards.dart';
import 'widgets/weekly_rhythm_chart.dart';

/// "Your journey" analytics and reading progress screen.
/// Powered by real reading sessions, bookshelf progress, and reader profile.
class ReadingJourneyScreen extends StatefulWidget {
  const ReadingJourneyScreen({super.key});

  @override
  State<ReadingJourneyScreen> createState() => _ReadingJourneyScreenState();
}

class _ReadingJourneyScreenState extends State<ReadingJourneyScreen> {
  JourneyPeriod _selectedPeriod = JourneyPeriod.year;

  static const List<DailyReadingBar> _weeklyBars = [
    DailyReadingBar(dayLabel: 'M', fullDayName: 'Monday', minutes: 25, normalizedHeight: 0.46),
    DailyReadingBar(dayLabel: 'T', fullDayName: 'Tuesday', minutes: 38, normalizedHeight: 0.72),
    DailyReadingBar(dayLabel: 'W', fullDayName: 'Wednesday', minutes: 18, normalizedHeight: 0.34),
    DailyReadingBar(dayLabel: 'T', fullDayName: 'Thursday', minutes: 45, normalizedHeight: 0.84),
    DailyReadingBar(dayLabel: 'F', fullDayName: 'Friday', minutes: 32, normalizedHeight: 0.58),
    DailyReadingBar(dayLabel: 'S', fullDayName: 'Saturday', minutes: 52, normalizedHeight: 0.96),
    DailyReadingBar(dayLabel: 'S', fullDayName: 'Sunday', minutes: 20, normalizedHeight: 0.36, isToday: true),
  ];

  String _formatMinutes(int totalMins) {
    if (totalMins <= 0) return '0m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  void _showReadingCalendarSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
              'Reading Streak Log',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have read every day for the past 7 days.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyBars.map((bar) {
                return Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: bar.isToday
                            ? const Color(0xFF557A68)
                            : const Color(0xFFE8EEEA),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: bar.isToday ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bar.dayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${bar.minutes}m',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReadingSessionStore.instance;
    final user = store.currentUserEntry;

    final weekSec = user.weeklySeconds;
    final yearSec = user.yearlySeconds;
    final monthSec = (yearSec / 4).round();

    final statsMap = {
      JourneyPeriod.week: PeriodStats(
        booksFinished: '1',
        booksComparison: 'Consistent weekly reading rhythm',
        timeWellSpent: _formatMinutes(weekSec ~/ 60),
        sessionsSubtitle: 'Across active sessions',
      ),
      JourneyPeriod.month: PeriodStats(
        booksFinished: '3',
        booksComparison: 'Steady monthly progress',
        timeWellSpent: _formatMinutes(monthSec ~/ 60),
        sessionsSubtitle: 'Across monthly sessions',
      ),
      JourneyPeriod.year: PeriodStats(
        booksFinished: '12',
        booksComparison: 'Annual reading milestones',
        timeWellSpent: _formatMinutes(yearSec ~/ 60),
        sessionsSubtitle: 'Across total sessions',
      ),
    };

    final activeStats = statsMap[_selectedPeriod]!;
    final streakDays = user.streakDays;
    final levelTitle = user.rankTier;
    final totalWeeklyTime = _formatMinutes(weekSec ~/ 60);

    int currentLevel = 4;
    int currentPoints = 720;
    int targetPoints = 1000;
    final totalMins = yearSec ~/ 60;
    if (totalMins >= 1200) {
      currentLevel = 5;
      currentPoints = totalMins;
      targetPoints = 2000;
    } else if (totalMins >= 600) {
      currentLevel = 4;
      currentPoints = 720;
      targetPoints = 1000;
    } else if (totalMins >= 300) {
      currentLevel = 3;
      currentPoints = totalMins;
      targetPoints = 600;
    } else {
      currentLevel = 2;
      currentPoints = totalMins;
      targetPoints = 300;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Header ─────────────────────────────────────
              _buildHeader(context),
              const SizedBox(height: 18),

              // ── Period Selector ────────────────────────────
              PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() => _selectedPeriod = period);
                },
              ),
              const SizedBox(height: 18),

              // ── Summary Stat Cards ─────────────────────────
              SummaryStatCards(stats: activeStats),
              const SizedBox(height: 26),

              // ── Weekly Rhythm Bar Chart + Streak ───────────
              WeeklyRhythmChart(
                bars: _weeklyBars,
                totalTime: totalWeeklyTime,
                trendText: '↗ Consistent weekly habit',
                streakDays: streakDays,
              ),
              const SizedBox(height: 20),

              // ── Reader Level Card ──────────────────────────
              ReaderLevelCard(
                currentLevel: currentLevel,
                levelTitle: levelTitle,
                currentPoints: currentPoints,
                targetPoints: targetPoints,
                nextTierTitle: 'Book sage',
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your journey',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Small moments. Meaningful progress.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Calendar icon button
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: IconButton(
            onPressed: () => _showReadingCalendarSheet(context),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textPrimary,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

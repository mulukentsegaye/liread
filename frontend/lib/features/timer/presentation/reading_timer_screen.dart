import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../../leaderboard/domain/leaderboard_models.dart';
import '../domain/book_model.dart';
import '../domain/timer_theme_model.dart';
import 'widgets/book_selector_sheet.dart';
import 'widgets/currently_reading_card.dart';
import 'widgets/radial_glow_counter_card.dart';
import 'widgets/reading_timer_painter.dart';
import 'widgets/timer_settings_sheet.dart';
import 'widgets/timer_theme_sheet.dart';

/// Full interactive Reading Timer screen with Light and Dark mode harmony,
/// mode-matched counter themes, and dynamic session sync.
class ReadingTimerScreen extends StatefulWidget {
  const ReadingTimerScreen({super.key});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen> {
  // Available books in library
  final List<ReadingBook> _library = const [
    ReadingBook(
      id: '1',
      title: 'Before the coffee gets cold',
      author: 'Toshikazu Kawaguchi',
      coverColor: Color(0xFF1E3A2E),
      coverIcon: Icons.local_cafe_rounded,
      totalPages: 213,
      currentPage: 94,
    ),
    ReadingBook(
      id: '2',
      title: 'The Creative Act',
      author: 'Rick Rubin',
      coverColor: Color(0xFF2D4A3E),
      coverIcon: Icons.palette_outlined,
      totalPages: 432,
      currentPage: 180,
    ),
    ReadingBook(
      id: '3',
      title: 'Atomic Habits',
      author: 'James Clear',
      coverColor: Color(0xFF385547),
      coverIcon: Icons.trending_up_rounded,
      totalPages: 320,
      currentPage: 210,
    ),
    ReadingBook(
      id: '4',
      title: 'East of Eden',
      author: 'John Steinbeck',
      coverColor: Color(0xFF233B31),
      coverIcon: Icons.auto_stories_rounded,
      totalPages: 601,
      currentPage: 312,
    ),
  ];

  late ReadingBook _selectedBook;
  int _goalMinutes = 30;

  // Track user-chosen theme per mode so preferences are remembered
  CounterThemeId _lightThemeId = CounterThemeId.sageOrganic;
  CounterThemeId _darkThemeId = CounterThemeId.obsidianEmber;

  int _elapsedSeconds = 0;
  bool _isRunning = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _selectedBook = _library.first;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRunning) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
  }

  void _finishAndSave() {
    _ticker?.cancel();
    final sessionSeconds = _elapsedSeconds;
    final minutes = (sessionSeconds / 60).floor();
    final seconds = sessionSeconds % 60;

    // Save completed session to the shared store so Daily, Weekly, and Yearly ranks update
    ReadingSessionStore.instance.recordSession(
      bookTitle: _selectedBook.title,
      durationSeconds: sessionSeconds > 0 ? sessionSeconds : 60,
    );

    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
    });

    final store = ReadingSessionStore.instance;
    final dailyRank = store.getCurrentUserRank(LeaderboardPeriod.daily);
    final weeklyRank = store.getCurrentUserRank(LeaderboardPeriod.weekly);
    final yearlyRank = store.getCurrentUserRank(LeaderboardPeriod.yearly);

    final isDark = AppThemeController.instance.isDarkMode;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Session Saved',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great reading session! You logged:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimarySurface : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$minutes min $seconds sec · ${_selectedBook.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2B24) : const Color(0xFFEDF2EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daily #$dailyRank · Weekly #$weeklyRank · Yearly #$yearlyRank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ReadingSessionStore.instance.navigateToTab(3);
            },
            child: const Text('View Leaderboard'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds / 60).floor();
    final secs = totalSeconds % 60;
    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = secs.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }

  double get _progress {
    final totalGoalSecs = _goalMinutes * 60;
    if (totalGoalSecs <= 0) return 0.0;
    return (_elapsedSeconds / totalGoalSecs).clamp(0.0, 1.0);
  }

  CounterThemeId _getActiveThemeId(bool isDark) {
    return isDark ? _darkThemeId : _lightThemeId;
  }

  void _setActiveThemeId(bool isDark, CounterThemeId themeId) {
    setState(() {
      if (isDark) {
        _darkThemeId = themeId;
      } else {
        _lightThemeId = themeId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        final isDark = AppThemeController.instance.isDarkMode;
        final currentMinutesToday = (_elapsedSeconds / 60).floor();

        final currentThemeId = _getActiveThemeId(isDark);
        final activeTheme = CounterThemeConfig.byId(currentThemeId);

        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
        final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
        final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ─────────────────────────────────────
                  _buildHeader(context, isDark, currentThemeId),
                  const SizedBox(height: 18),

                  // ── Currently Reading Card ─────────────────────
                  CurrentlyReadingCard(
                    book: _selectedBook,
                    onTap: () async {
                      final picked = await BookSelectorSheet.show(
                        context,
                        books: _library,
                        selectedBook: _selectedBook,
                      );
                      if (picked != null) {
                        setState(() => _selectedBook = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Quick Theme Selector Pill ──────────────────
                  Center(
                    child: InkWell(
                      onTap: () {
                        TimerThemeSheet.show(
                          context,
                          currentThemeId: currentThemeId,
                          onThemeSelected: (id) => _setActiveThemeId(isDark, id),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activeTheme.themeIcon,
                              size: 15,
                              color: activeTheme.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Theme: ${activeTheme.name}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Counter Display (Classic Ring or Arched Dial Card) ────
                  Center(
                    child: currentThemeId == CounterThemeId.sageOrganic
                        ? _buildClassicCircularCounter(isDark)
                        : RadialGlowCounterCard(
                            theme: activeTheme,
                            progress: _progress,
                            elapsedSeconds: _elapsedSeconds,
                            goalMinutes: _goalMinutes,
                            bookTitle: _selectedBook.title,
                            isRunning: _isRunning,
                          ),
                  ),
                  const SizedBox(height: 28),

                  // ── Primary Action Pill: Pause / Resume Session ─
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTimer,
                      icon: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: Text(
                        _isRunning
                            ? 'Pause session'
                            : (_elapsedSeconds > 0
                                ? 'Resume session'
                                : 'Start session'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentThemeId == CounterThemeId.sageOrganic
                            ? (isDark ? AppColors.darkPrimary : const Color(0xFF557766))
                            : activeTheme.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Secondary Action: Finish & save ────────────
                  Center(
                    child: TextButton(
                      onPressed: _finishAndSave,
                      child: Text(
                        'Finish & save',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Divider ────────────────────────────────────
                  Divider(color: dividerColor, height: 1),
                  const SizedBox(height: 16),

                  // ── Daily Goal Status ──────────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'A little every day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$currentMinutesToday / $_goalMinutes min today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Inspirational Footer Quote ─────────────────
                  Center(
                    child: Text(
                      'The world can wait for one more chapter.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: textTertiary,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassicCircularCounter(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accentGreen = isDark ? AppColors.darkPrimary : const Color(0xFF557A68);
    final trackColor = isDark ? const Color(0xFF232B26) : const Color(0xFFE2E9E4);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular ring painter
          CustomPaint(
            size: const Size(260, 260),
            painter: ReadingTimerPainter(
              progress: _progress,
              trackColor: trackColor,
              progressColor: accentGreen,
              knobColor: isDark ? AppColors.darkPrimaryLight : const Color(0xFF456656),
              strokeWidth: 7.0,
            ),
          ),

          // Center labels
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? accentGreen
                          : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRunning
                        ? 'IN YOUR FLOW'
                        : (_elapsedSeconds > 0
                            ? 'SESSION PAUSED'
                            : 'READY TO READ'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _isRunning ? accentGreen : textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Large Timer Digits
              Text(
                _formatTime(_elapsedSeconds),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 50,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),

              // Goal subtitle
              Text(
                'of your $_goalMinutes min goal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, CounterThemeId activeThemeId) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderAlpha = isDark ? 0.28 : 0.18;
    final borderColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A moment to read',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'One page. One breath. At your pace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // 1. App Dark / Light Mode Toggle Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor.withValues(alpha: borderAlpha),
              width: 1.5,
            ),
          ),
          child: IconButton(
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () {
              AppThemeController.instance.toggleThemeMode();
            },
            padding: EdgeInsets.zero,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: textPrimary,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 2. Theme Palette Icon button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor.withValues(alpha: borderAlpha),
              width: 1.5,
            ),
          ),
          child: IconButton(
            tooltip: 'Counter Theme',
            onPressed: () {
              TimerThemeSheet.show(
                context,
                currentThemeId: activeThemeId,
                onThemeSelected: (id) => _setActiveThemeId(isDark, id),
              );
            },
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.palette_outlined,
              color: textPrimary,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 3. Settings / Preferences Icon button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor.withValues(alpha: borderAlpha),
              width: 1.5,
            ),
          ),
          child: IconButton(
            tooltip: 'Settings',
            onPressed: () {
              TimerSettingsSheet.show(
                context,
                currentGoalMinutes: _goalMinutes,
                onGoalChanged: (goal) {
                  setState(() => _goalMinutes = goal);
                },
                currentThemeId: activeThemeId,
                onThemeChanged: (id) {
                  _setActiveThemeId(isDark, id);
                },
              );
            },
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.tune_rounded,
              color: textPrimary,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

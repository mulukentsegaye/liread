import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/book_model.dart';
import 'widgets/book_selector_sheet.dart';
import 'widgets/currently_reading_card.dart';
import 'widgets/reading_timer_painter.dart';
import 'widgets/timer_settings_sheet.dart';

/// Full interactive Reading Timer screen matching "A moment to read".
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

  // Initialize at 18:42 to mirror the exact state from the mockup
  int _elapsedSeconds = 18 * 60 + 42;
  bool _isRunning = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _selectedBook = _library.first;
    _startTicker();
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
  }

  void _finishAndSave() {
    _ticker?.cancel();
    setState(() => _isRunning = false);

    final minutes = (_elapsedSeconds / 60).floor();
    final seconds = _elapsedSeconds % 60;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Session Complete',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great reading session! You spent:',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes min $seconds sec · ${_selectedBook.title}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your daily streak has been updated! Keep up the momentum.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _elapsedSeconds = 0;
                _isRunning = false;
              });
              _startTicker();
            },
            child: Text(
              'Reset & Finish',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _startTicker();
            },
            child: const Text('Keep Reading'),
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

  @override
  Widget build(BuildContext context) {
    final currentMinutesToday = (_elapsedSeconds / 60).floor();

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
              const SizedBox(height: 28),

              // ── Circular Reading Timer ─────────────────────
              Center(
                child: SizedBox(
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
                          trackColor: const Color(0xFFE2E9E4),
                          progressColor: const Color(0xFF557A68),
                          knobColor: const Color(0xFF456656),
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
                                      ? const Color(0xFF557A68)
                                      : AppColors.textTertiary,
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
                                  color: _isRunning
                                      ? const Color(0xFF557A68)
                                      : AppColors.textSecondary,
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
                              color: AppColors.textPrimary,
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

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
                    backgroundColor: const Color(0xFF557766),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Divider ────────────────────────────────────
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // ── Daily Goal Status ──────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'A little every day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$currentMinutesToday / $_goalMinutes min today',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
                    color: AppColors.textTertiary,
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
  }

  // ── Header Widget ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A moment to read',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'One page. One breath. At your pace.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Settings / Preferences Icon button
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
            onPressed: () {
              TimerSettingsSheet.show(
                context,
                currentGoalMinutes: _goalMinutes,
                onGoalChanged: (goal) {
                  setState(() => _goalMinutes = goal);
                },
              );
            },
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

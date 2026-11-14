import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/co_reading_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../leaderboard/data/reading_session_store.dart';
import 'widgets/live_co_readers_widget.dart';

/// Distraction-free Reading Timer screen ("A moment to read").
class ReadingTimerScreen extends StatefulWidget {
  const ReadingTimerScreen({super.key});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen> {
  // Timer state
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  // Selected book
  String _currentBook = 'Before the coffee gets cold';
  String _currentAuthor = 'Toshikazu Kawaguchi';

  // Active theme name for timer counter style
  String _activeCounterTheme = 'Sage Classic';

  // Ambient sound selection
  String _activeAmbientSound = 'Forest Birds';
  bool _isAmbientPlaying = false;

  final List<String> _ambientSounds = const [
    'Forest Birds',
    'Gentle Rain',
    'Library Atmosphere',
    'Deep Space',
  ];

  @override
  void initState() {
    super.initState();
    CoReadingService.instance.initChannel();
    ReadingSessionStore.instance.selectedBookForTimer
        .addListener(_onExternalBookSelected);
  }

  void _onExternalBookSelected() {
    final bookData =
        ReadingSessionStore.instance.selectedBookForTimer.value;
    if (bookData != null && mounted) {
      setState(() {
        _currentBook = bookData['title'] ?? _currentBook;
        _currentAuthor = bookData['author'] ?? _currentAuthor;
      });
      if (_isRunning) {
        CoReadingService.instance.track(
          bookTitle: _currentBook,
          bookAuthor: _currentAuthor,
          startedAt: DateTime.now().millisecondsSinceEpoch - (_secondsElapsed * 1000),
        );
      }
      ReadingSessionStore.instance.selectedBookForTimer.value = null;
    }
  }

  @override
  void dispose() {
    if (_isRunning) {
      CoReadingService.instance.untrack();
    }
    ReadingSessionStore.instance.selectedBookForTimer
        .removeListener(_onExternalBookSelected);
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
        CoReadingService.instance.untrack();
      } else {
        _isRunning = true;
        CoReadingService.instance.track(
          bookTitle: _currentBook,
          bookAuthor: _currentAuthor,
          startedAt: DateTime.now().millisecondsSinceEpoch - (_secondsElapsed * 1000),
        );
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsElapsed++;
            });
          }
        });
      }
    });
  }

  void _finishSession() {
    _timer?.cancel();
    if (_secondsElapsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reading time recorded yet. Start the timer to begin your reading session.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final durationSec = _secondsElapsed;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final durationMinutes = (durationSec / 60).ceil();
        final textTheme = Theme.of(ctx).textTheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Session Complete!',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You read "$_currentBook" for $durationMinutes minutes.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Every minute brings quiet presence and connection.',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _timer?.cancel();
                CoReadingService.instance.untrack();
                // Add to local reactive store
                ReadingSessionStore.instance.recordSession(
                  bookTitle: _currentBook,
                  durationSeconds: durationSec,
                );
                // Sync to Supabase in background
                SupabaseService.instance.logReadingSession(
                  bookTitle: _currentBook,
                  durationMinutes: durationMinutes,
                  durationSeconds: durationSec,
                );
                setState(() {
                  _secondsElapsed = 0;
                  _isRunning = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reading session saved to your Journey and Ranks!'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save session'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DefaultTabController(
          length: 2,
          initialIndex: AppThemeController.instance.isDarkMode ? 1 : 0,
          child: Material(
            color: AppColors.resolve(
              context,
              light: AppColors.surface,
              dark: AppColors.darkSurface,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Counter Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Light Themes'),
                    Tab(text: 'Dark Themes'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Light Themes
                      ListView(
                        children: [
                          _buildThemeOption('Sage Classic', 'Warm organic paper feel with sage tones'),
                          _buildThemeOption('Ceramic Frost', 'Clean alabaster ceramic with crisp mint'),
                          _buildThemeOption('Warm Papyrus', 'Gentle parchment with antique gold accent'),
                          _buildThemeOption('Linen Minimal', 'Textured linen with understated slate lines'),
                        ],
                      ),
                      // Dark Themes
                      ListView(
                        children: [
                          _buildThemeOption('Obsidian Ember', 'Deep obsidian with warm amber glow'),
                          _buildThemeOption('Midnight Aurora', 'Velvet navy with vivid aurora emerald'),
                          _buildThemeOption('Obsidian Sage', 'Dark slate paired with serene muted green'),
                          _buildThemeOption('Charcoal Minimal', 'OLED pure black with subtle platinum highlights'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(String name, String description) {
    final isSelected = _activeCounterTheme == name;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _activeCounterTheme = name;
        });
        Navigator.of(context).pop();
      },
    ),
    );
  }

  void _showBookSelector() async {
    final shelf = await SupabaseService.instance.fetchBookshelf();
    if (!mounted) return;

    final titleCtrl = TextEditingController(text: _currentBook);
    final authorCtrl = TextEditingController(text: _currentAuthor);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final surfaceColor = AppColors.resolve(
          sheetCtx,
          light: AppColors.surface,
          dark: AppColors.darkSurface,
        );

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 14),
                Text(
                  'Select Book for Timer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick from your sanctuary bookshelf or type any title:',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                if (shelf.isNotEmpty) ...[
                  const Text(
                    'FROM YOUR BOOKSHELF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...shelf.take(5).map((b) {
                    final bTitle = b['title'] ?? 'Untitled';
                    final bAuthor = b['author'] ?? 'Unknown Author';
                    final isSel = bTitle.toString().toLowerCase() == _currentBook.toLowerCase();

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        Icons.bookmark_rounded,
                        color: isSel ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        bTitle,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel ? AppColors.primary : null,
                        ),
                      ),
                      subtitle: Text(bAuthor, style: const TextStyle(fontSize: 11)),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() {
                          _currentBook = bTitle;
                          _currentAuthor = bAuthor;
                        });
                        if (_isRunning) {
                          CoReadingService.instance.track(
                            bookTitle: _currentBook,
                            bookAuthor: _currentAuthor,
                            startedAt: DateTime.now().millisecondsSinceEpoch - (_secondsElapsed * 1000),
                          );
                        }
                        Navigator.of(sheetCtx).pop();
                      },
                    );
                  }),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'CUSTOM BOOK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Book Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Author Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final t = titleCtrl.text.trim();
                      final a = authorCtrl.text.trim();
                      if (t.isNotEmpty) {
                        setState(() {
                          _currentBook = t;
                          _currentAuthor = a.isNotEmpty ? a : 'Author';
                        });
                        if (_isRunning) {
                          CoReadingService.instance.track(
                            bookTitle: _currentBook,
                            bookAuthor: _currentAuthor,
                            startedAt: DateTime.now().millisecondsSinceEpoch - (_secondsElapsed * 1000),
                          );
                        }
                      }
                      Navigator.of(sheetCtx).pop();
                    },
                    child: const Text('Apply Book to Timer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimerTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.resolve(
      context,
      light: AppColors.surface,
      dark: AppColors.darkSurface,
    );
    final cardBg = AppColors.resolve(
      context,
      light: AppColors.bookCardBackground,
      dark: AppColors.darkBookCardBackground,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header & Active Readers Count ─────────────
              Align(
                alignment: Alignment.centerLeft,
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
                    const SizedBox(height: 12),
                    ValueListenableBuilder<List<LiveCoReader>>(
                      valueListenable: CoReadingService.instance.activeCoReaders,
                      builder: (context, readers, _) {
                        final count = readers.length;
                        final hasActive = count > 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: hasActive
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.12)
                                : (isDark
                                    ? AppColors.darkDivider.withValues(alpha: 0.5)
                                    : AppColors.divider.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasActive
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hasActive
                                      ? const Color(0xFF10B981)
                                      : AppColors.textTertiary,
                                  shape: BoxShape.circle,
                                  boxShadow: hasActive
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x6610B981),
                                            blurRadius: 6,
                                            spreadRadius: 1.5,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                count == 0
                                    ? '0 reading right now'
                                    : count == 1
                                        ? '1 person reading right now'
                                        : '$count people reading right now',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: hasActive
                                      ? const Color(0xFF059669)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Theme Selector Pill ────────────────────────
              GestureDetector(
                onTap: () => _showThemeSelector(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Theme: $_activeCounterTheme',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Book Selection Card ────────────────────────
              GestureDetector(
                onTap: _showBookSelector,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentBook,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentAuthor,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to switch book',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Main Timer Display ─────────────────────────
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: _activeCounterTheme == 'Obsidian Ember'
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius: _activeCounterTheme == 'Obsidian Ember'
                      ? BorderRadius.circular(40)
                      : null,
                  color: surfaceColor,
                  border: Border.all(
                    color: _isRunning
                        ? AppColors.primary
                        : AppColors.divider,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _isRunning ? 0.15 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTimerTime(_secondsElapsed),
                      style: GoogleFonts.dmMono(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRunning ? 'Reading in focus' : 'And Pages',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentBook,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Action Buttons ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start/Pause Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(
                          _isRunning ? 'Pause session' : 'Start session',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Finish & save Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _finishSession,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text(
                          'Finish & save',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Ambient Soundscapes Bar ────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      final nextIdx = (_ambientSounds.indexOf(_activeAmbientSound) + 1) % _ambientSounds.length;
                      _activeAmbientSound = _ambientSounds[nextIdx];
                    });
                  },
                  child: Row(
                  children: [
                    Icon(
                      _isAmbientPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambient Sound: $_activeAmbientSound',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _isAmbientPlaying ? 'Playing calmly' : 'Muted',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isAmbientPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAmbientPlaying = !_isAmbientPlaying;
                        });
                      },
                    ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 24),

              // ── Live Co-Reading Room Widget ────────────────
              const LiveReadingRoomWidget(
                showStartButton: false,
                margin: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // ── Encouragement Footer ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'A little every day',
                    style: GoogleFonts.newsreader(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

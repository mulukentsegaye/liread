import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/reader_avatar.dart';
import '../../analytics/presentation/reading_journey_screen.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// Real Reader Profile & Sanctuary Shelf screen.
/// Connected to Supabase Auth and database tables (profiles, bookshelf, saved_posts).
class ReaderProfileScreen extends StatefulWidget {
  const ReaderProfileScreen({super.key});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _fullName = 'Reader';
  String _handle = '@reader';
  String _bio = 'Mindful reader cultivating daily habits.';
  String _rankTier = 'Novice Reader';
  String? _avatarUrl;
  int _dailyGoalMinutes = 60;
  int _totalMinutesRead = 0;
  int _currentStreak = 0;

  List<Map<String, dynamic>> _bookshelfItems = [];
  List<Map<String, dynamic>> _savedPassages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profile = await SupabaseService.instance.fetchCurrentUserProfile();
    if (mounted) {
      setState(() {
        if (profile != null) {
          _fullName = profile['full_name'] ?? _fullName;
          _handle = '@${profile['username'] ?? _handle.replaceAll('@', '')}';
          _bio = profile['bio'] ?? _bio;
          _rankTier = profile['rank_tier'] ?? _rankTier;
          _dailyGoalMinutes = (profile['daily_goal_minutes'] as num?)?.toInt() ?? _dailyGoalMinutes;
          _totalMinutesRead = (profile['total_minutes_read'] as num?)?.toInt() ?? _totalMinutesRead;
          _currentStreak = (profile['current_streak'] as num?)?.toInt() ?? _currentStreak;
          _avatarUrl = profile['avatar_url'] as String?;
        } else if (SupabaseService.instance.isGuest) {
          _fullName = 'Guest Reader';
          _handle = '@guest';
          _bio = 'Exploring LiRead sanctuary as a guest.';
          _avatarUrl = null;
        }
      });
    }

    _loadShelf();
    _loadSaved();
  }

  Future<void> _loadShelf() async {
    final shelf = await SupabaseService.instance.fetchBookshelf();
    if (mounted) {
      setState(() {
        _bookshelfItems = shelf;
      });
    }
  }

  Future<void> _loadSaved() async {
    final saved = await SupabaseService.instance.fetchSavedPassages();
    if (mounted) {
      setState(() {
        _savedPassages = saved;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _fullName);
    final bioCtrl = TextEditingController(text: _bio);
    final avatarCtrl = TextEditingController(text: _avatarUrl ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: avatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Avatar Image URL',
                    hintText: 'https://... or data:image/...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newBio = bioCtrl.text.trim();
                final newAvatar = avatarCtrl.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _fullName = newName;
                    _bio = newBio;
                    _avatarUrl = newAvatar.isNotEmpty ? newAvatar : null;
                  });
                  await SupabaseService.instance.updateProfile(
                    fullName: newName,
                    bio: newBio,
                    avatarUrl: newAvatar.isNotEmpty ? newAvatar : null,
                  );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showGoalAdjustDialog() {
    int selected = _dailyGoalMinutes;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Daily Reading Target'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set a daily reading habit you can sustain with calm consistency:'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90].map((mins) {
                      final isSel = selected == mins;
                      return ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) setDlgState(() => selected = mins);
                        },
                      );
                    }).toList(),
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
                  ),
                  onPressed: () async {
                    setState(() => _dailyGoalMinutes = selected);
                    await SupabaseService.instance.updateProfile(
                      dailyGoalMinutes: selected,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of LiRead?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await SupabaseService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
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

    final isGuest = SupabaseService.instance.isGuest;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── Header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your corner',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The reader behind the pages.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      // Settings, Theme Switcher & Sign Out
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Settings',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ).then((_) => _loadProfileData());
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: () {
                              AppThemeController.instance.toggleThemeMode();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isGuest ? Icons.login_rounded : Icons.logout_rounded,
                              color: isGuest ? AppColors.primary : AppColors.textSecondary,
                            ),
                            tooltip: isGuest ? 'Sign In / Register' : 'Sign Out',
                            onPressed: () {
                              if (isGuest) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                                );
                              } else {
                                _showSignOutDialog();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Guest Banner if applicable ─────────────────
              if (isGuest)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Guest mode active. Create an account to sync your reading streak across devices.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                            );
                          },
                          child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Reader Identity Card ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar
                            ReaderAvatar(
                              avatarUrl: _avatarUrl,
                              name: _fullName,
                              radius: 30,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                  ),
                                  Text(
                                    _handle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _rankTier,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit Profile button
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                side: const BorderSide(color: AppColors.divider),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showEditProfileDialog,
                              child: const Text(
                                'Edit profile',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Bio
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _bio,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 14),
                        // Real Stats Row (tappable to view detailed Journey)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('${_totalMinutesRead}m', 'Total read', onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReadingJourneyScreen()),
                              );
                            }),
                            _buildStatColumn('${_currentStreak}d', 'Streak', onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReadingJourneyScreen()),
                              );
                            }),
                            _buildStatColumn('${_bookshelfItems.length}', 'On shelf'),
                            _buildStatColumn('$_dailyGoalMinutes m', 'Daily goal', onTap: _showGoalAdjustDialog),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Tab Bar ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'On my shelf'),
                      Tab(text: 'Saved passages'),
                      Tab(text: 'My reading circles'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. On my shelf
              _buildBookshelfTab(cardBg),

              // 2. Saved passages
              _buildSavedPassagesTab(surfaceColor),

              // 3. My reading circles
              _buildReadingCirclesTab(surfaceColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBookshelfTab(Color cardBg) {
    if (_bookshelfItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Icon(Icons.library_books_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Your sanctuary shelf is waiting',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore millions of titles in Open Library and add books to your shelf or timer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: () => ReadingSessionStore.instance.navigateToTab(1), // Explore tab
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Discover & Add Books'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _bookshelfItems.length,
      itemBuilder: (context, index) {
        final book = _bookshelfItems[index];
        final title = book['title'] ?? 'Untitled';
        final author = book['author'] ?? 'Unknown Author';
        final progress = (book['progress_percentage'] as num?)?.toInt() ?? 0;
        final status = book['status'] ?? 'currently_reading';

        String statusLabel = 'Currently Reading';
        Color statusColor = AppColors.primary;
        if (status == 'finished') {
          statusLabel = 'Finished';
          statusColor = const Color(0xFF2E7D32);
        } else if (status == 'want_to_read') {
          statusLabel = 'Want to Read';
          statusColor = const Color(0xFFE65100);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.book_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      author,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (progress / 100).clamp(0.0, 1.0),
                              backgroundColor: AppColors.divider,
                              color: AppColors.primary,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress%',
                          style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ReadingSessionStore.instance.selectBookForTimer(
                    title,
                    author,
                    coverUrl: book['cover_image_url']?.toString(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Read',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedPassagesTab(Color surfaceColor) {
    if (_savedPassages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        children: [
          Icon(Icons.bookmark_border_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'No saved passages yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the bookmark icon under any passage in the feed to save quotes to your personal commonplace book.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _savedPassages.length,
      itemBuilder: (context, index) {
        final q = _savedPassages[index];
        final quoteText = q['quote'] ?? '';
        final author = q['author'] ?? 'Unknown Author';
        final book = q['book'] ?? 'Untitled';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$quoteText"',
                style: GoogleFonts.newsreader(
                  fontSize: 15,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '— $author, $book',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.bookmark_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingCirclesTab(Color surfaceColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Community Circle Stats',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect with readers sharing notes, book recommendations, and daily habit commitments.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('$_currentStreak d', 'Streak'),
                  _buildStatColumn('${_bookshelfItems.length}', 'Bookshelf'),
                  _buildStatColumn('${_savedPassages.length}', 'Saved quotes'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../../leaderboard/domain/leaderboard_models.dart';

/// Reader Profile & Settings screen ("Your corner").
class ReaderProfileScreen extends StatefulWidget {
  const ReaderProfileScreen({super.key});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _fullName = 'Emma Laurent';
  String _handle = '@emma.reads';
  String _bio = 'Seeking stillness between pages. Currently captivated by Japanese contemporary fiction and stoic essays.';
  int _dailyGoalMinutes = 60;

    List<Map<String, dynamic>> _bookshelfItems = const [
    {
      'title': 'Before the coffee gets cold',
      'author': 'Toshikazu Kawaguchi',
      'status': 'currently_reading',
      'progress_percentage': 42,
    },
    {
      'title': 'The Creative Act',
      'author': 'Rick Rubin',
      'status': 'currently_reading',
      'progress_percentage': 75,
    },
    {
      'title': 'East of Eden',
      'author': 'John Steinbeck',
      'status': 'finished',
      'progress_percentage': 100,
    },
  ];
  bool _isLoadingShelf = false;

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
    if (profile != null && mounted) {
      setState(() {
        _fullName = profile['full_name'] ?? _fullName;
        _handle = '@${profile['username'] ?? _handle.replaceAll('@', '')}';
        _bio = profile['bio'] ?? _bio;
        _dailyGoalMinutes = profile['daily_goal_minutes'] ?? _dailyGoalMinutes;
      });
    }

    final shelf = await SupabaseService.instance.fetchBookshelf();
    if (mounted) {
      setState(() {
        _bookshelfItems = shelf;
        _isLoadingShelf = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _fullName);
    final bioCtrl = TextEditingController(text: _bio);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile'),
          content: Column(
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
                final newName = nameCtrl.text.trim();
                final newBio = bioCtrl.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _fullName = newName;
                    _bio = newBio;
                  });
                  await SupabaseService.instance.updateProfile(
                    fullName: newName,
                    bio: newBio,
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
                  const Text('Choose a mindful daily reading habit to sustain without stress:'),
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

  void _showAuthModal() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: AppColors.resolve(
                  ctx,
                  light: AppColors.surface,
                  dark: AppColors.darkSurface,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    isSignUp ? 'Create a LiRead Account' : 'Welcome to LiRead',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sync your habits, bookshelf, and insights with the community.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  if (isSignUp) ...[
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text;
                        if (email.isEmpty || pass.isEmpty) return;
                        try {
                          if (isSignUp) {
                            await SupabaseService.instance.signUp(
                              email,
                              pass,
                              userCtrl.text.trim(),
                              _fullName,
                            );
                          } else {
                            await SupabaseService.instance.signIn(email, pass);
                          }
                          await _loadProfileData();
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isSignUp ? 'Account created! Welcome.' : 'Signed in successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(isSignUp ? 'Create Account' : 'Sign In'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setSheetState(() => isSignUp = !isSignUp);
                      },
                      child: Text(
                        isSignUp
                            ? 'Already have an account? Sign In'
                            : 'New reader? Create an account',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
                      // Theme Switcher & Auth
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Toggle Dark/Light mode',
                            onPressed: () {
                              AppThemeController.instance.toggleThemeMode();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              SupabaseService.instance.isAuthenticated
                                  ? Icons.account_circle_rounded
                                  : Icons.login_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: SupabaseService.instance.isAuthenticated
                                ? 'Account settings'
                                : 'Sign In / Register',
                            onPressed: _showAuthModal,
                          ),
                        ],
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
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                _fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase(),
                                style: GoogleFonts.newsreader(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
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
                                    child: const Text(
                                      'Thoughtful reader',
                                      style: TextStyle(
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
                        // Quick Stats Row
                        ListenableBuilder(
                          listenable: ReadingSessionStore.instance,
                          builder: (context, _) {
                            final userEntry = ReadingSessionStore.instance.currentUserEntry;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(userEntry.formattedTimeFor(LeaderboardPeriod.yearly), 'Read time'),
                                _buildStatColumn('${userEntry.streakDays}d', 'Streak'),
                                _buildStatColumn('${_bookshelfItems.length}', 'Books'),
                                _buildStatColumn('$_dailyGoalMinutes m', 'Daily goal', onTap: _showGoalAdjustDialog),
                              ],
                            );
                          },
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
    if (_isLoadingShelf) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _bookshelfItems.length,
      itemBuilder: (context, index) {
        final book = _bookshelfItems[index];
        final title = book['title'] ?? 'Untitled';
        final author = book['author'] ?? 'Unknown Author';
        final progress = book['progress_percentage'] ?? 0;
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
                              value: progress / 100,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedPassagesTab(Color surfaceColor) {
    final savedQuotes = [
      {
        'quote': 'And now that you don\'t have to be perfect, you can be good.',
        'author': 'John Steinbeck',
        'book': 'East of Eden',
      },
      {
        'quote': 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
        'author': 'Will Durant',
        'book': 'The Story of Philosophy',
      },
      {
        'quote': 'The object of life is not to be on the side of the majority, but to escape finding oneself in the ranks of the insane.',
        'author': 'Marcus Aurelius',
        'book': 'Meditations',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: savedQuotes.length,
      itemBuilder: (context, index) {
        final q = savedQuotes[index];
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
                '"${q['quote']}"',
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
                    '— ${q['author']}, ${q['book']}',
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
          padding: const EdgeInsets.all(16),
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
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'You share mindful habits with 1,420 readers around the world.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('14', 'Followers'),
                  _buildStatColumn('28', 'Following'),
                  _buildStatColumn('38', 'Quotes shared'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

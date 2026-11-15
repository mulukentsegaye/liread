import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../timer/presentation/widgets/live_co_readers_widget.dart';
import '../domain/post_model.dart';
import 'widgets/book_recommendation_card.dart';
import 'widgets/feed_post_header.dart';
import 'widgets/post_actions_bar.dart';
import 'widgets/quote_card.dart';

/// The main Discover Feed screen â€” "Between pages".
/// Powered by live community posts from Supabase.
class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<FeedPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLivePosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLivePosts() async {
    setState(() => _isLoading = true);
    final livePosts = await SupabaseService.instance.fetchFeedPosts();
    if (mounted) {
      setState(() {
        _posts = livePosts;
        _isLoading = false;
      });
    }
  }

  void _toggleLike(int index) {
    if (index >= _posts.length) return;
    final post = _posts[index];
    final newIsLiked = !post.isLiked;
    final newLikes = newIsLiked ? post.likes + 1 : (post.likes > 0 ? post.likes - 1 : 0);

    setState(() {
      _posts[index] = FeedPost(
        id: post.id,
        userName: post.userName,
        userInitials: post.userInitials,
        actionText: post.actionText,
        timeAgo: post.timeAgo,
        type: post.type,
        bookRecommendation: post.bookRecommendation,
        quotePost: post.quotePost,
        likes: newLikes,
        comments: post.comments,
        isLiked: newIsLiked,
        isBookmarked: post.isBookmarked,
      );
    });

    SupabaseService.instance.toggleUpvote(post.id);
  }

  void _toggleBookmark(int index) {
    if (index >= _posts.length) return;
    final post = _posts[index];
    final newIsBookmarked = !post.isBookmarked;

    setState(() {
      _posts[index] = FeedPost(
        id: post.id,
        userName: post.userName,
        userInitials: post.userInitials,
        actionText: post.actionText,
        timeAgo: post.timeAgo,
        type: post.type,
        bookRecommendation: post.bookRecommendation,
        quotePost: post.quotePost,
        likes: post.likes,
        comments: post.comments,
        isLiked: post.isLiked,
        isBookmarked: newIsBookmarked,
      );
    });

    SupabaseService.instance.toggleBookmark(post.id);
  }

  void _onCommentTapped(FeedPost post) {
    final bookTitle = post.bookRecommendation?.bookTitle ??
        post.quotePost?.bookTitle ??
        'this passage';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.forum_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Community discussion threads for "$bookTitle" are opening soon!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCreatePostModal() {
    bool isQuote = true;
    final bookTitleCtrl = TextEditingController();
    final bookAuthorCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    String selectedTag = 'Creativity';
    double rating = 5.0;

    final tags = ['Creativity', 'Philosophy', 'Fiction', 'Habits', 'Mindfulness', 'General'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final surfaceColor = AppColors.resolve(
              ctx,
              light: AppColors.surface,
              dark: AppColors.darkSurface,
            );

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.8,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                    'Share with Circle',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  // Post Type Selector
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Passage Quote'),
                        selected: isQuote,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isQuote ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => isQuote = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Book Recommendation'),
                        selected: !isQuote,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: !isQuote ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => isQuote = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: bookTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Book Title',
                              hintText: 'e.g. Meditations',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: bookAuthorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Author',
                              hintText: 'e.g. Marcus Aurelius',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: textCtrl,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: isQuote ? 'Passage / Quote' : 'Review & Recommendation',
                              hintText: isQuote
                                  ? 'Write the resonant sentence or paragraph...'
                                  : 'What made this book worth your time?',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Category tag selector
                          Row(
                            children: [
                              const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: selectedTag,
                                underline: const SizedBox(),
                                items: tags.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedTag = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        final title = bookTitleCtrl.text.trim();
                        final author = bookAuthorCtrl.text.trim();
                        final content = textCtrl.text.trim();
                        if (title.isEmpty || content.isEmpty) return;

                        final profile = SupabaseService.instance.currentProfile;
                        final authorName = profile?['full_name'] ?? profile?['username'] ?? 'You';
                        final initials = authorName.toString().trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase();

                        final newPost = FeedPost(
                          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                          userName: authorName,
                          userInitials: initials.isEmpty ? 'Y' : initials,
                          actionText: isQuote ? 'Saved a passage' : 'Finished a book',
                          timeAgo: 'Just now',
                          type: isQuote ? PostType.quote : PostType.bookRecommendation,
                          likes: 1,
                          comments: 0,
                          isLiked: true,
                          quotePost: isQuote
                              ? QuotePost(
                                  quoteText: content,
                                  quoteAuthor: author.isNotEmpty ? author : 'Unknown',
                                  bookTitle: title,
                                )
                              : null,
                          bookRecommendation: !isQuote
                              ? BookRecommendation(
                                  bookTitle: title,
                                  bookAuthor: author.isNotEmpty ? author : 'Unknown',
                                  rating: rating,
                                  category: selectedTag,
                                  pages: 250,
                                  recommendationText: content,
                                )
                              : null,
                        );

                        setState(() {
                          _posts.insert(0, newPost);
                        });

                        Navigator.of(sheetCtx).pop();

                        // Sync to Supabase in background
                        await SupabaseService.instance.createPost(
                          bookTitle: title,
                          bookAuthor: author.isNotEmpty ? author : 'Unknown Author',
                          quoteText: isQuote ? content : null,
                          recommendationText: !isQuote ? content : null,
                          rating: isQuote ? null : rating,
                          tag: selectedTag,
                          postType: isQuote ? 'passage' : 'recommendation',
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your post is published to the community!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      child: const Text('Publish Post'),
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildHeader(context),

            // â”€â”€ Tab bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildTabBar(context),

            // â”€â”€ Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Divider(height: 1, color: AppColors.divider),

            // â”€â”€ Tab Views â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Community Feed with Live Co-Reading banner
                  _buildCommunityFeedTab(),

                  // Tab 1: Reading Circle Leaderboard
                  const LeaderboardScreen(showHeader: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityFeedTab() {
    return RefreshIndicator(
      onRefresh: _fetchLivePosts,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // â”€â”€ Live Co-Reading Feed Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const SliverToBoxAdapter(
            child: LiveCoReadingFeedBanner(),
          ),

          // â”€â”€ Feed list / Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          else if (_posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.format_quote_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your feed is quiet',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first reader to share a resonant passage or recommend a book to your circle.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showCreatePostModal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Share a passage'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  return _FeedPostItem(
                    post: post,
                    onLike: () => _toggleLike(index),
                    onBookmark: () => _toggleBookmark(index),
                    onComment: () => _onCommentTapped(post),
                  );
                },
                childCount: _posts.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Between pages',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'A little inspiration from your circle.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Settings gear icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              tooltip: 'Settings',
            ),
          ),
          const SizedBox(width: 8),

          // Create-post FAB
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _showCreatePostModal,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Share a passage',
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Tab bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          // Tabs
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.tabInactive,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.only(right: 24),
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Community Feed'),
                Tab(text: 'Reading Circle'),
              ],
            ),
          ),

          // "LIREAD" trailing label
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'LIREAD',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Individual feed post â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FeedPostItem extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onComment;

  const _FeedPostItem({
    required this.post,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          FeedPostHeader(
            userName: post.userName,
            userInitials: post.userInitials,
            actionText: post.actionText,
            timeAgo: post.timeAgo,
          ),
          const SizedBox(height: 14),

          // Post content
          if (post.type == PostType.bookRecommendation &&
              post.bookRecommendation != null)
            BookRecommendationCard(data: post.bookRecommendation!),

          if (post.type == PostType.quote && post.quotePost != null)
            QuoteCard(data: post.quotePost!),

          const SizedBox(height: 14),

          // Actions
          PostActionsBar(
            likes: post.likes,
            comments: post.comments,
            isLiked: post.isLiked,
            isBookmarked: post.isBookmarked,
            onLike: onLike,
            onBookmark: onBookmark,
            onComment: onComment,
          ),
        ],
      ),
    );
  }
}

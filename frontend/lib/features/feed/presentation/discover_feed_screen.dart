import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/post_model.dart';
import 'widgets/book_recommendation_card.dart';
import 'widgets/feed_post_header.dart';
import 'widgets/post_actions_bar.dart';
import 'widgets/quote_card.dart';

/// The main Discover Feed screen — "Between pages".
class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late List<FeedPost> _posts;

  // ── Mock default posts ───────────────────────────────────
  static const List<FeedPost> _defaultPosts = [
    FeedPost(
      id: '1',
      userName: 'Jamie Lee',
      userInitials: 'JL',
      actionText: 'Finished a book',
      timeAgo: '2h ago',
      type: PostType.bookRecommendation,
      likes: 24,
      comments: 6,
      bookRecommendation: BookRecommendation(
        bookTitle: 'The Creative Act',
        bookAuthor: 'Rick Rubin',
        rating: 5,
        category: 'Creativity',
        pages: 432,
        recommendationText:
            'A gentle reminder that creativity is a way of being, not just a thing we do.',
      ),
    ),
    FeedPost(
      id: '2',
      userName: 'Amara Miles',
      userInitials: 'AM',
      actionText: 'Saved a passage',
      timeAgo: '4h ago',
      type: PostType.quote,
      likes: 38,
      comments: 4,
      quotePost: QuotePost(
        quoteText:
            'And now that you don\'t have to be perfect, you can be good.',
        quoteAuthor: 'John Steinbeck',
        bookTitle: 'East of Eden',
      ),
    ),
    FeedPost(
      id: '3',
      userName: 'Daniel Cho',
      userInitials: 'DC',
      actionText: 'Finished a book',
      timeAgo: '5h ago',
      type: PostType.bookRecommendation,
      likes: 41,
      comments: 12,
      bookRecommendation: BookRecommendation(
        bookTitle: 'Atomic Habits',
        bookAuthor: 'James Clear',
        rating: 5,
        category: 'Self-Help',
        pages: 320,
        recommendationText:
            'Small changes, remarkable results. This book rewired how I think about daily routines.',
      ),
    ),
    FeedPost(
      id: '4',
      userName: 'Sofia Reyes',
      userInitials: 'SR',
      actionText: 'Saved a passage',
      timeAgo: '6h ago',
      type: PostType.quote,
      likes: 52,
      comments: 8,
      quotePost: QuotePost(
        quoteText:
            'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
        quoteAuthor: 'Will Durant',
        bookTitle: 'The Story of Philosophy',
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _posts = List.from(_defaultPosts);
    _fetchLivePosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLivePosts() async {
    final livePosts = await SupabaseService.instance.fetchFeedPosts();
    if (livePosts.isNotEmpty && mounted) {
      setState(() {
        // Merge live posts on top of default posts
        final Set<String> liveIds = livePosts.map((p) => p.id).toSet();
        final filteredDefaults = _defaultPosts.where((p) => !liveIds.contains(p.id)).toList();
        _posts = [...livePosts, ...filteredDefaults];
      });
    }
  }

  void _toggleLike(int index) {
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

  void _showCommentsSheet(FeedPost post) {
    final textCtrl = TextEditingController();
    final sampleComments = [
      {'user': 'Julian Vance', 'text': 'Such a powerful passage, resonates deeply.'},
      {'user': 'Amara Miles', 'text': 'Added this book to my shelf immediately!'},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thoughts & Reflections',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.divider),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sampleComments.length,
                      itemBuilder: (c, i) {
                        final comment = sampleComments[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  comment['user']![0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['user']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      comment['text']!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textCtrl,
                          decoration: InputDecoration(
                            hintText: 'Share a reflection...',
                            hintStyle: const TextStyle(fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: () {
                          if (textCtrl.text.trim().isNotEmpty) {
                            setSheetState(() {
                              sampleComments.add({
                                'user': 'Emma Laurent',
                                'text': textCtrl.text.trim(),
                              });
                            });
                            textCtrl.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.8,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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

                        final newPost = FeedPost(
                          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
                          userName: 'Emma Laurent',
                          userInitials: 'EL',
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
                              content: Text('Your post is published to the community circle!'),
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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _fetchLivePosts,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── Tab bar ──────────────────────────────────────
            SliverToBoxAdapter(child: _buildTabBar(context)),

            // ── Divider ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Divider(height: 1, color: AppColors.divider),
            ),

            // ── Feed list ────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  return _FeedPostItem(
                    post: post,
                    onLike: () => _toggleLike(index),
                    onBookmark: () => _toggleBookmark(index),
                    onComment: () => _showCommentsSheet(post),
                  );
                },
                childCount: _posts.length,
              ),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 16),

          // Create-post FAB
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
              onPressed: _showCreatePostModal,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────
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
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.tabInactive,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.only(right: 24),
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'For you'),
                Tab(text: 'Following'),
              ],
            ),
          ),

          // "FOLIO" trailing label
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'FOLIO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual feed post ───────────────────────────────────────
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

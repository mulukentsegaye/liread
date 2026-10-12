import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Mock data ────────────────────────────────────────────
  static const List<FeedPost> _mockPosts = [
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
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
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
                final post = _mockPosts[index];
                return _FeedPostItem(post: post);
              },
              childCount: _mockPosts.length,
            ),
          ),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
              onPressed: () {},
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

  const _FeedPostItem({required this.post});

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
          ),
        ],
      ),
    );
  }
}

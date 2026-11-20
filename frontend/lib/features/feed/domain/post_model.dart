// Data models for the Discover Feed.

enum PostType { bookRecommendation, quote }

class FeedPost {
  final String id;
  final String userName;
  final String userInitials;
  final String? avatarUrl;
  final String actionText;
  final String timeAgo;
  final PostType type;
  final BookRecommendation? bookRecommendation;
  final QuotePost? quotePost;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;

  const FeedPost({
    required this.id,
    required this.userName,
    required this.userInitials,
    this.avatarUrl,
    required this.actionText,
    required this.timeAgo,
    required this.type,
    this.bookRecommendation,
    this.quotePost,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  FeedPost copyWith({
    String? id,
    String? userName,
    String? userInitials,
    String? avatarUrl,
    String? actionText,
    String? timeAgo,
    PostType? type,
    BookRecommendation? bookRecommendation,
    QuotePost? quotePost,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return FeedPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userInitials: userInitials ?? this.userInitials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      actionText: actionText ?? this.actionText,
      timeAgo: timeAgo ?? this.timeAgo,
      type: type ?? this.type,
      bookRecommendation: bookRecommendation ?? this.bookRecommendation,
      quotePost: quotePost ?? this.quotePost,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class BookRecommendation {
  final String bookTitle;
  final String bookAuthor;
  final String? coverImageUrl;
  final double rating;
  final String category;
  final int pages;
  final String recommendationText;

  const BookRecommendation({
    required this.bookTitle,
    required this.bookAuthor,
    this.coverImageUrl,
    required this.rating,
    required this.category,
    required this.pages,
    required this.recommendationText,
  });
}

class QuotePost {
  final String quoteText;
  final String quoteAuthor;
  final String bookTitle;

  const QuotePost({
    required this.quoteText,
    required this.quoteAuthor,
    required this.bookTitle,
  });
}

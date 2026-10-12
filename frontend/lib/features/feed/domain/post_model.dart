// Data models for the Discover Feed.

enum PostType { bookRecommendation, quote }

class FeedPost {
  final String id;
  final String userName;
  final String userInitials;
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

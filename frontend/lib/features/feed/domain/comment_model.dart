import 'package:flutter/foundation.dart';

/// A single reader comment or reflection on a community feed post.
@immutable
class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String initials;
  final String? avatarUrl;
  final String text;
  final DateTime createdAt;
  final String timeAgo;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.initials,
    this.avatarUrl,
    required this.text,
    required this.createdAt,
    required this.timeAgo,
  });

  factory FeedComment.fromMap(Map<String, dynamic> map, String postId) {
    final prof = map['profiles'] as Map<String, dynamic>? ?? {};
    final name = prof['full_name'] ?? prof['username'] ?? map['authorName'] ?? 'Fellow Reader';
    final initials = name.toString().trim().split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2).join('').toUpperCase();

    final dateStr = map['created_at'] ?? map['createdAt'];
    DateTime date = DateTime.now();
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    final diff = DateTime.now().difference(date);
    String timeAgo = 'Just now';
    if (diff.inDays > 0) {
      timeAgo = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      timeAgo = '${diff.inMinutes}m ago';
    }

    return FeedComment(
      id: map['id']?.toString() ?? 'cmt-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: map['user_id']?.toString() ?? map['userId'] ?? 'guest',
      authorName: name.toString(),
      initials: initials.isEmpty ? 'FR' : initials,
      avatarUrl: prof['avatar_url'] as String?,
      text: map['comment_text'] ?? map['text'] ?? map['commentText'] ?? '',
      createdAt: date,
      timeAgo: timeAgo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'authorName': authorName,
      'comment_text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

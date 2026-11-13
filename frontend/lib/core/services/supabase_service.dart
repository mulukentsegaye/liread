import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/domain/post_model.dart';

/// Central service communicating with Supabase backend and OpenLibrary API.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl = 'https://zlrrnnoqektzirwrgftj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpscnJubm9xZWt0emlyd3JnZnRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwOTU5MDEsImV4cCI6MjEwNzY3MTkwMX0.qfu9KYzq91Ya3l8taGcjinSGZos0NSPDa_oTJjwGECs';

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Active user profile cache
  Map<String, dynamic>? _currentProfile;
  Map<String, dynamic>? get currentProfile => _currentProfile;

  bool get isAuthenticated => client?.auth.currentUser != null;
  String? get currentUserId => client?.auth.currentUser?.id;

  /// Initialize Supabase
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
      if (isAuthenticated) {
        await fetchCurrentUserProfile();
      }
    } catch (e) {
      debugPrint('Supabase initialize warning: $e');
      _initialized = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // AUTHENTICATION
  // ─────────────────────────────────────────────────────────────

  Future<AuthResponse?> signIn(String email, String password) async {
    if (!_initialized || client == null) return null;
    final res = await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (res.user != null) {
      await fetchCurrentUserProfile();
    }
    return res;
  }

  Future<AuthResponse?> signUp(
      String email, String password, String username, String fullName) async {
    if (!_initialized || client == null) return null;
    final cleanUsername =
        username.toLowerCase().replaceAll('@', '').trim();
    final res = await client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': cleanUsername,
        'full_name': fullName.trim(),
      },
    );
    if (res.user != null) {
      await ensureProfileExists(res.user!.id, cleanUsername, fullName.trim());
      await fetchCurrentUserProfile();
    }
    return res;
  }

  Future<void> signOut() async {
    if (_initialized && client != null) {
      await client!.auth.signOut();
    }
    _currentProfile = null;
  }

  Future<void> ensureProfileExists(
      String userId, String username, String fullName) async {
    if (client == null) return;
    try {
      final existing = await client!
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (existing == null) {
        await client!.from('profiles').insert({
          'id': userId,
          'username': username.isNotEmpty ? username : 'reader_${userId.substring(0, 6)}',
          'full_name': fullName.isNotEmpty ? fullName : 'Avid Reader',
          'daily_goal_minutes': 60,
          'rank_tier': 'Novice Reader',
        });
      }
    } catch (e) {
      debugPrint('Error ensuring profile: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    if (client == null || currentUserId == null) return null;
    try {
      final data = await client!
          .from('profiles')
          .select('*')
          .eq('id', currentUserId!)
          .maybeSingle();
      if (data != null) {
        _currentProfile = Map<String, dynamic>.from(data);
      }
      return _currentProfile;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    int? dailyGoalMinutes,
  }) async {
    if (client == null || currentUserId == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (dailyGoalMinutes != null) {
      updates['daily_goal_minutes'] = dailyGoalMinutes;
    }
    updates['updated_at'] = DateTime.now().toIso8601String();

    await client!.from('profiles').update(updates).eq('id', currentUserId!);
    await fetchCurrentUserProfile();
  }

  // ─────────────────────────────────────────────────────────────
  // READING SESSIONS
  // ─────────────────────────────────────────────────────────────

  Future<bool> logReadingSession({
    required String bookTitle,
    required int durationMinutes,
    required int durationSeconds,
  }) async {
    if (client == null || currentUserId == null) return false;
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await client!.from('reading_sessions').insert({
        'user_id': currentUserId,
        'book_title': bookTitle,
        'duration_minutes': durationMinutes,
        'duration_seconds': durationSeconds,
        'session_date': todayStr,
      });
      await fetchCurrentUserProfile();
      return true;
    } catch (e) {
      debugPrint('Error logging session: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // COMMUNITY FEED POSTS
  // ─────────────────────────────────────────────────────────────

  Future<List<FeedPost>> fetchFeedPosts({String? tag}) async {
    if (client == null) return [];
    try {
      var query = client!.from('posts').select('''
        *,
        profiles:user_id (
          username,
          full_name,
          avatar_url
        ),
        post_upvotes (
          user_id
        ),
        saved_posts (
          user_id
        )
      ''');

      if (tag != null && tag != 'All') {
        query = query.eq('tag', tag);
      }

      final res = await query.order('created_at', ascending: false).limit(30);
      final List<dynamic> data = res as List<dynamic>;

      final uid = currentUserId;

      return data.map((item) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final authorName =
            profile?['full_name'] ?? profile?['username'] ?? 'Fellow Reader';
        final initials = authorName.isNotEmpty
            ? authorName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
            : 'FR';

        final createdAt = item['created_at'] != null
            ? DateTime.tryParse(item['created_at'])
            : null;
        String timeAgo = 'Just now';
        if (createdAt != null) {
          final diff = DateTime.now().difference(createdAt);
          if (diff.inDays > 0) {
            timeAgo = '${diff.inDays}d ago';
          } else if (diff.inHours > 0) {
            timeAgo = '${diff.inHours}h ago';
          } else if (diff.inMinutes > 0) {
            timeAgo = '${diff.inMinutes}m ago';
          }
        }

        final upvotesList = item['post_upvotes'] as List<dynamic>? ?? [];
        final savesList = item['saved_posts'] as List<dynamic>? ?? [];

        final isLiked = uid != null &&
            upvotesList.any((u) => u['user_id'] == uid);
        final isBookmarked = uid != null &&
            savesList.any((s) => s['user_id'] == uid);

        final postTypeStr = item['post_type'] as String? ?? 'passage';
        final isRecommendation = postTypeStr == 'recommendation' ||
            postTypeStr == 'finished_book';

        final postType = isRecommendation
            ? PostType.bookRecommendation
            : PostType.quote;

        final ratingVal = item['rating'] != null
            ? (item['rating'] as num).toDouble()
            : 5.0;

        return FeedPost(
          id: item['id'].toString(),
          userName: authorName,
          userInitials: initials.isEmpty ? 'R' : initials,
          actionText: postTypeStr == 'finished_book'
              ? 'Finished a book'
              : (isRecommendation ? 'Recommended a book' : 'Saved a passage'),
          timeAgo: timeAgo,
          type: postType,
          likes: upvotesList.length,
          comments: item['comments_count'] ?? 0,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
          bookRecommendation: isRecommendation
              ? BookRecommendation(
                  bookTitle: item['book_title'] ?? 'Untitled Book',
                  bookAuthor: item['book_author'] ?? 'Unknown Author',
                  coverImageUrl: item['cover_image_url'],
                  rating: ratingVal,
                  category: item['tag'] ?? 'General',
                  pages: item['page_number'] ?? 280,
                  recommendationText: item['recommendation_text'] ??
                      item['quote_text'] ??
                      '',
                )
              : null,
          quotePost: !isRecommendation
              ? QuotePost(
                  quoteText: item['quote_text'] ??
                      item['recommendation_text'] ??
                      'No quote text',
                  quoteAuthor: item['book_author'] ?? 'Unknown Author',
                  bookTitle: item['book_title'] ?? 'Untitled Book',
                )
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  Future<bool> createPost({
    required String bookTitle,
    required String bookAuthor,
    String? quoteText,
    String? recommendationText,
    double? rating,
    int? pageNumber,
    String tag = 'General',
    String postType = 'passage',
    String? coverImageUrl,
  }) async {
    if (client == null || currentUserId == null) return false;
    try {
      await client!.from('posts').insert({
        'user_id': currentUserId,
        'book_title': bookTitle,
        'book_author': bookAuthor,
        'quote_text': quoteText,
        'recommendation_text': recommendationText,
        'rating': rating,
        'page_number': pageNumber,
        'tag': tag,
        'post_type': postType,
        'cover_image_url': coverImageUrl,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  Future<bool> toggleUpvote(String postId) async {
    if (client == null || currentUserId == null) return false;
    try {
      final existing = await client!
          .from('post_upvotes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existing != null) {
        await client!
            .from('post_upvotes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId!);
        return false;
      } else {
        await client!.from('post_upvotes').insert({
          'post_id': postId,
          'user_id': currentUserId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling upvote: $e');
      return false;
    }
  }

  Future<bool> toggleBookmark(String postId) async {
    if (client == null || currentUserId == null) return false;
    try {
      final existing = await client!
          .from('saved_posts')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existing != null) {
        await client!
            .from('saved_posts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId!);
        return false;
      } else {
        await client!.from('saved_posts').insert({
          'post_id': postId,
          'user_id': currentUserId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BOOKSHELF
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBookshelf() async {
    if (client == null || currentUserId == null) {
      return _getLocalBookshelf();
    }
    try {
      final res = await client!
          .from('bookshelf')
          .select('*')
          .eq('user_id', currentUserId!)
          .order('updated_at', ascending: false);
      final List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(res as List);
      _cacheBookshelfLocally(items);
      return items;
    } catch (e) {
      debugPrint('Error fetching bookshelf: $e');
      return _getLocalBookshelf();
    }
  }

  Future<bool> updateBookStatus({
    required String title,
    required String author,
    required String status,
    int progressPercentage = 0,
    String? coverImageUrl,
  }) async {
    if (client == null || currentUserId == null) {
      return _updateLocalBookshelf(title, author, status, progressPercentage, coverImageUrl);
    }
    try {
      final existing = await client!
          .from('bookshelf')
          .select('id')
          .eq('user_id', currentUserId!)
          .ilike('title', title.trim())
          .maybeSingle();

      final now = DateTime.now().toIso8601String();
      if (existing != null) {
        await client!.from('bookshelf').update({
          'status': status,
          'progress_percentage': progressPercentage,
          'updated_at': now,
        }).eq('id', existing['id']);
      } else {
        await client!.from('bookshelf').insert({
          'user_id': currentUserId,
          'title': title.trim(),
          'author': author.trim(),
          'status': status,
          'progress_percentage': progressPercentage,
          'cover_image_url': coverImageUrl,
          'created_at': now,
          'updated_at': now,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error updating bookshelf: $e');
      return false;
    }
  }

  Future<void> _cacheBookshelfLocally(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('liread_local_bookshelf', jsonEncode(items));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _getLocalBookshelf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_local_bookshelf');
      if (str != null) {
        final List decoded = jsonDecode(str);
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (_) {}
    return [
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
      {
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'status': 'finished',
        'progress_percentage': 100,
      },
      {
        'title': 'The Shadow of the Wind',
        'author': 'Carlos Ruiz Zafón',
        'status': 'want_to_read',
        'progress_percentage': 0,
      },
    ];
  }

  bool _updateLocalBookshelf(String title, String author, String status, int progress, String? cover) {
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // OPEN LIBRARY BOOK SEARCH
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchOpenLibrary(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final url = Uri.parse(
          'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query.trim())}&limit=12&fields=key,title,author_name,cover_i,first_publish_year,subject');
      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final docs = json['docs'] as List<dynamic>? ?? [];
        return docs.map((doc) {
          final title = doc['title'] ?? 'Unknown';
          final authors = doc['author_name'] as List<dynamic>?;
          final author = authors != null && authors.isNotEmpty
              ? authors.first.toString()
              : 'Unknown Author';
          final coverId = doc['cover_i'];
          final coverUrl = coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : null;
          return {
            'title': title,
            'author': author,
            'firstPublishYear': doc['first_publish_year'],
            'coverUrl': coverUrl,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('OpenLibrary search error: $e');
    }
    return [];
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/domain/comment_model.dart';
import '../../features/feed/domain/post_model.dart';
import '../../features/leaderboard/data/reading_session_store.dart';
import '../../features/leaderboard/domain/leaderboard_models.dart';

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

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  bool get isAuthenticated => client?.auth.currentUser != null;
  String? get currentUserId => client?.auth.currentUser?.id;

  /// Check whether user is logged in or active in guest mode
  Future<bool> hasActiveSession() async {
    if (isAuthenticated) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('liread_is_guest') ?? false;
      return _isGuest;
    } catch (_) {
      return false;
    }
  }

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
        _isGuest = false;
        await fetchCurrentUserProfile();
      } else {
        final prefs = await SharedPreferences.getInstance();
        _isGuest = prefs.getBool('liread_is_guest') ?? false;
        if (_isGuest) {
          _loadGuestProfile(prefs);
        }
      }
    } catch (e) {
      debugPrint('Supabase initialize warning: $e');
      _initialized = false;
    }
  }

  void _loadGuestProfile(SharedPreferences prefs) {
    _currentProfile = {
      'id': 'guest',
      'username': prefs.getString('liread_guest_handle') ?? 'guest',
      'full_name': prefs.getString('liread_guest_name') ?? 'Guest Reader',
      'bio': 'Exploring LiRead sanctuary as a guest.',
      'daily_goal_minutes': prefs.getInt('liread_guest_goal') ?? 30,
      'rank_tier': 'Novice Reader',
      'total_minutes_read': prefs.getInt('liread_guest_minutes') ?? 0,
      'current_streak': prefs.getInt('liread_guest_streak') ?? 0,
    };
    ReadingSessionStore.instance.updateCurrentUserProfile(_currentProfile!);
  }

  Future<void> setGuestMode({String? name, String? handle}) async {
    _isGuest = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('liread_is_guest', true);
      if (name != null) await prefs.setString('liread_guest_name', name);
      if (handle != null) await prefs.setString('liread_guest_handle', handle);
      _loadGuestProfile(prefs);
    } catch (_) {}
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
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('liread_is_guest', false);
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
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('liread_is_guest', false);
      await ensureProfileExists(res.user!.id, cleanUsername, fullName.trim());
      await fetchCurrentUserProfile();
    }
    return res;
  }

  Future<void> signOut() async {
    if (_initialized && client != null) {
      await client!.auth.signOut();
    }
    _isGuest = false;
    _currentProfile = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('liread_is_guest');
    } catch (_) {}
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
    if (client == null || currentUserId == null) {
      if (_isGuest) return _currentProfile;
      return null;
    }
    try {
      final data = await client!
          .from('profiles')
          .select('*')
          .eq('id', currentUserId!)
          .maybeSingle();
      if (data != null) {
        _currentProfile = Map<String, dynamic>.from(data);
        ReadingSessionStore.instance.updateCurrentUserProfile(_currentProfile!);
      }
      return _currentProfile;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return _currentProfile;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    int? dailyGoalMinutes,
    String? avatarUrl,
  }) async {
    if (_isGuest) {
      if (_currentProfile != null) {
        if (fullName != null) _currentProfile!['full_name'] = fullName;
        if (bio != null) _currentProfile!['bio'] = bio;
        if (dailyGoalMinutes != null) _currentProfile!['daily_goal_minutes'] = dailyGoalMinutes;
        if (avatarUrl != null) _currentProfile!['avatar_url'] = avatarUrl;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        if (fullName != null) await prefs.setString('liread_guest_name', fullName);
        if (dailyGoalMinutes != null) await prefs.setInt('liread_guest_goal', dailyGoalMinutes);
        if (avatarUrl != null) await prefs.setString('liread_guest_avatar', avatarUrl);
      } catch (_) {}
      return;
    }

    if (client == null || currentUserId == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (dailyGoalMinutes != null) {
      updates['daily_goal_minutes'] = dailyGoalMinutes;
    }
    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
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
    final sessionMap = {
      'id': 'session-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': currentUserId ?? 'guest',
      'book_title': bookTitle,
      'duration_minutes': durationMinutes,
      'duration_seconds': durationSeconds,
      'session_date': DateTime.now().toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    };
    await _cacheReadingSessionLocally(sessionMap);

    if (_isGuest) {
      final currentMins = (_currentProfile?['total_minutes_read'] as num?)?.toInt() ?? 0;
      final currentStreak = (_currentProfile?['current_streak'] as num?)?.toInt() ?? 0;
      final newMins = currentMins + durationMinutes;
      final newStreak = currentStreak + 1;
      if (_currentProfile != null) {
        _currentProfile!['total_minutes_read'] = newMins;
        _currentProfile!['current_streak'] = newStreak;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('liread_guest_minutes', newMins);
        await prefs.setInt('liread_guest_streak', newStreak);
      } catch (_) {}
      return true;
    }

    if (client == null || currentUserId == null) return true;
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
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> fetchReadingSessions() async {
    final List<Map<String, dynamic>> results = [];
    if (client != null && currentUserId != null) {
      try {
        final res = await client!
            .from('reading_sessions')
            .select('*')
            .eq('user_id', currentUserId!)
            .order('created_at', ascending: false);
        results.addAll(List<Map<String, dynamic>>.from(res));
      } catch (e) {
        debugPrint('Error fetching reading sessions: $e');
      }
    }

    final local = await _getLocalReadingSessions();
    for (final s in local) {
      if (!results.any((r) => r['id'] == s['id'])) {
        results.add(s);
      }
    }
    return results;
  }

  Future<void> _cacheReadingSessionLocally(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_local_reading_sessions');
      List<Map<String, dynamic>> list = [];
      if (str != null) {
        list = List<Map<String, dynamic>>.from(jsonDecode(str));
      }
      list.insert(0, session);
      await prefs.setString('liread_local_reading_sessions', jsonEncode(list));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _getLocalReadingSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_local_reading_sessions');
      if (str != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(str));
      }
    } catch (_) {}
    return [];
  }

  // ─────────────────────────────────────────────────────────────
  // COMMUNITY FEED POSTS (REAL DATA)
  // ─────────────────────────────────────────────────────────────

  Future<List<FeedPost>> fetchFeedPosts({String? tag}) async {
    final List<dynamic> allRawData = [];

    // Prepend local user created posts
    final localPosts = await _getLocalPosts();
    for (final lp in localPosts) {
      if (tag == null || tag == 'All' || lp['tag'] == tag) {
        allRawData.add(lp);
      }
    }

    if (client != null) {
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

        final res = await query.order('created_at', ascending: false).limit(40);
        final List<dynamic> data = res as List<dynamic>;
        for (final item in data) {
          if (!allRawData.any((r) => r['id'].toString() == item['id'].toString())) {
            allRawData.add(item);
          }
        }
      } catch (e) {
        debugPrint('Error fetching posts: $e');
      }
    }

    final uid = currentUserId;

    return allRawData.map((item) {
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
        avatarUrl: profile?['avatar_url'] as String?,
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
  }

  Future<void> _cachePostLocally(Map<String, dynamic> post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_local_posts');
      List<dynamic> list = [];
      if (str != null) {
        list = jsonDecode(str) as List<dynamic>;
      }
      list.insert(0, post);
      await prefs.setString('liread_local_posts', jsonEncode(list));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _getLocalPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_local_posts');
      if (str != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(str));
      }
    } catch (_) {}
    return [];
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
    final localMap = {
      'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': currentUserId ?? 'guest',
      'book_title': bookTitle,
      'book_author': bookAuthor,
      'quote_text': quoteText,
      'recommendation_text': recommendationText,
      'rating': rating,
      'page_number': pageNumber,
      'tag': tag,
      'post_type': postType,
      'cover_image_url': coverImageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'profiles': {
        'full_name': _currentProfile?['full_name'] ?? (_isGuest ? 'Guest Reader' : 'You'),
        'username': _currentProfile?['username'] ?? 'reader',
      },
      'post_upvotes': [{'user_id': currentUserId ?? 'guest'}],
      'saved_posts': [],
    };
    await _cachePostLocally(localMap);

    if (client == null || currentUserId == null) return true;
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
      debugPrint('Error creating post in Supabase: $e');
      return true;
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
  // COMMUNITY POST COMMENTS (REAL DATA)
  // ─────────────────────────────────────────────────────────────

  Future<List<FeedComment>> fetchPostComments(String postId) async {
    final List<FeedComment> comments = [];

    // 1. Fetch real comments from Supabase post_comments table
    if (client != null) {
      try {
        final res = await client!
            .from('post_comments')
            .select('''
              id,
              post_id,
              user_id,
              comment_text,
              created_at,
              profiles:user_id (
                username,
                full_name,
                avatar_url
              )
            ''')
            .eq('post_id', postId)
            .order('created_at', ascending: true);

        for (final item in res) {
          comments.add(FeedComment.fromMap(Map<String, dynamic>.from(item), postId));
        }
      } catch (e) {
        debugPrint('Error fetching comments from Supabase: $e');
      }
    }

    // 2. Merge local cached comments for this post
    final local = await _getLocalPostComments(postId);
    for (final lc in local) {
      if (!comments.any((c) => c.id == lc.id)) {
        comments.add(lc);
      }
    }

    // Sort by created date ascending
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  Future<FeedComment?> createComment({
    required String postId,
    required String commentText,
  }) async {
    final trimmed = commentText.trim();
    if (trimmed.isEmpty) return null;

    final now = DateTime.now();
    final profile = currentProfile;
    final authorName = profile?['full_name'] ?? profile?['username'] ?? (_isGuest ? 'Guest Reader' : 'You');
    final initials = authorName.toString().trim().split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2).join('').toUpperCase();

    FeedComment newComment = FeedComment(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: currentUserId ?? 'guest',
      authorName: authorName.toString(),
      initials: initials.isEmpty ? 'Y' : initials,
      text: trimmed,
      createdAt: now,
      timeAgo: 'Just now',
    );

    // If authenticated with Supabase, insert into real post_comments table
    if (client != null && currentUserId != null) {
      try {
        final res = await client!.from('post_comments').insert({
          'post_id': postId,
          'user_id': currentUserId,
          'comment_text': trimmed,
        }).select('''
          id,
          post_id,
          user_id,
          comment_text,
          created_at,
          profiles:user_id (
            username,
            full_name,
            avatar_url
          )
        ''').maybeSingle();

        if (res != null) {
          newComment = FeedComment.fromMap(Map<String, dynamic>.from(res), postId);
        }
      } catch (e) {
        debugPrint('Error inserting comment into Supabase: $e');
      }
    }

    // Always cache locally so guest and offline submissions persist
    await _saveLocalPostComment(postId, newComment);

    return newComment;
  }

  Future<List<FeedComment>> _getLocalPostComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_comments_$postId');
      if (str != null) {
        final List decoded = jsonDecode(str);
        return decoded
            .map((item) => FeedComment.fromMap(Map<String, dynamic>.from(item), postId))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalPostComment(String postId, FeedComment comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('liread_comments_$postId');
      List<dynamic> list = [];
      if (str != null) {
        list = jsonDecode(str) as List<dynamic>;
      }
      list.add(comment.toMap());
      await prefs.setString('liread_comments_$postId', jsonEncode(list));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // LEADERBOARD (REAL DATA)
  // ─────────────────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> fetchLeaderboard(LeaderboardPeriod period) async {
    if (client == null) return [];
    try {
      String rpcName = 'get_weekly_leaderboard';
      Map<String, dynamic> args = {'max_limit': 30};

      if (period == LeaderboardPeriod.daily) {
        rpcName = 'get_daily_leaderboard';
        args = {
          'target_date': DateTime.now().toIso8601String().split('T')[0],
          'max_limit': 30,
        };
      } else if (period == LeaderboardPeriod.yearly) {
        rpcName = 'get_lifetime_leaderboard';
        args = {'max_limit': 30};
      }

      final res = await client!.rpc(rpcName, params: args);
      if (res is List && res.isNotEmpty) {
        final uid = currentUserId;
        return res.map((item) {
          final mins = (item['minutes_read'] as num?)?.toInt() ?? 0;
          final sec = mins * 60;
          final name = item['full_name'] ?? item['username'] ?? 'Reader';
          final handle = '@${item['username'] ?? 'reader'}';
          final initials = name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase();

          return LeaderboardEntry(
            userId: item['user_id']?.toString() ?? '',
            name: name,
            handle: handle,
            initials: initials.isEmpty ? 'R' : initials,
            avatarUrl: item['avatar_url'] as String?,
            currentBook: 'Active Reader',
            rankTier: item['rank_tier'] ?? 'Novice Reader',
            streakDays: 1,
            dailySeconds: period == LeaderboardPeriod.daily ? sec : sec ~/ 7,
            weeklySeconds: period == LeaderboardPeriod.weekly ? sec : sec,
            yearlySeconds: period == LeaderboardPeriod.yearly ? sec : sec * 4,
            isCurrentUser: uid != null && item['user_id'] == uid,
          );
        }).toList();
      }

      // Fallback: Query profiles table ordered by total_minutes_read
      final profilesRes = await client!
          .from('profiles')
          .select('*')
          .order('total_minutes_read', ascending: false)
          .limit(30);

      final List<dynamic> profiles = profilesRes as List<dynamic>;
      final uid = currentUserId;

      return profiles.map((p) {
        final name = p['full_name'] ?? p['username'] ?? 'Reader';
        final handle = '@${p['username'] ?? 'reader'}';
        final initials = name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase();
        final totalMins = (p['total_minutes_read'] as num?)?.toInt() ?? 0;
        final totalSec = totalMins * 60;

        return LeaderboardEntry(
          userId: p['id'].toString(),
          name: name,
          handle: handle,
          initials: initials.isEmpty ? 'R' : initials,
          avatarUrl: p['avatar_url'] as String?,
          currentBook: 'Active Reader',
          rankTier: p['rank_tier'] ?? 'Novice Reader',
          streakDays: (p['current_streak'] as num?)?.toInt() ?? 0,
          dailySeconds: (totalSec / 30).round(),
          weeklySeconds: (totalSec / 4).round(),
          yearlySeconds: totalSec,
          isCurrentUser: uid != null && p['id'] == uid,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BOOKSHELF (REAL DATA)
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
    // Always persist to local cache first so it reflects immediately
    await _updateLocalBookshelf(title, author, status, progressPercentage, coverImageUrl);

    if (client == null || currentUserId == null) {
      return true;
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
      debugPrint('Error updating bookshelf in Supabase: $e');
      return true;
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
    return [];
  }

  Future<bool> _updateLocalBookshelf(
    String title,
    String author,
    String status,
    int progress,
    String? cover,
  ) async {
    try {
      final items = await _getLocalBookshelf();
      final idx = items.indexWhere(
        (b) => (b['title'] as String?)?.toLowerCase().trim() == title.toLowerCase().trim(),
      );
      final now = DateTime.now().toIso8601String();
      if (idx != -1) {
        items[idx]['status'] = status;
        items[idx]['progress_percentage'] = progress;
        items[idx]['updated_at'] = now;
        if (cover != null) items[idx]['cover_image_url'] = cover;
      } else {
        items.insert(0, {
          'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
          'user_id': currentUserId ?? 'guest',
          'title': title.trim(),
          'author': author.trim(),
          'status': status,
          'progress_percentage': progress,
          'cover_image_url': cover,
          'created_at': now,
          'updated_at': now,
        });
      }
      await _cacheBookshelfLocally(items);
      return true;
    } catch (e) {
      debugPrint('Error updating local bookshelf: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SAVED PASSAGES
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSavedPassages() async {
    if (client == null || currentUserId == null) return [];
    try {
      final res = await client!.from('saved_posts').select('''
        id,
        created_at,
        posts:post_id (
          id,
          book_title,
          book_author,
          quote_text,
          page_number,
          profiles:user_id (
            username,
            full_name
          )
        )
      ''').eq('user_id', currentUserId!).order('created_at', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      return data.map((item) {
        final p = item['posts'] as Map<String, dynamic>? ?? {};
        final prof = p['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'quote': p['quote_text'] ?? 'Saved passage',
          'author': p['book_author'] ?? 'Unknown Author',
          'book': p['book_title'] ?? 'Untitled',
          'sharedBy': prof['full_name'] ?? prof['username'] ?? 'Fellow Reader',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching saved passages: $e');
      return [];
    }
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

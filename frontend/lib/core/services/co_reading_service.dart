import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Models an active live co-reader broadcasted via Supabase Realtime presence.
class LiveCoReader {
  final String userId;
  final String username;
  final String fullName;
  final String initials;
  final String? avatarUrl;
  final String bookTitle;
  final String? bookAuthor;
  final int sessionStartedMinutesAgo;
  final bool isCurrentUser;

  const LiveCoReader({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.initials,
    this.avatarUrl,
    required this.bookTitle,
    this.bookAuthor,
    required this.sessionStartedMinutesAgo,
    required this.isCurrentUser,
  });
}

/// Service that connects to the Supabase Realtime Presence channel ('liread:live-co-reading')
/// ensuring active reading sessions started on mobile are broadcast in real-time
/// to the web and other connected clients.
class CoReadingService {
  CoReadingService._();
  static final CoReadingService instance = CoReadingService._();

  static const String channelName = 'liread:live-co-reading';

  RealtimeChannel? _channel;
  bool _isSubscribed = false;
  Map<String, dynamic>? _currentPresence;

  final String _clientId =
      'mobile-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000000)}';

  final ValueNotifier<List<LiveCoReader>> activeCoReaders =
      ValueNotifier<List<LiveCoReader>>([]);

  /// Initialize channel subscription to the live co-reading room
  void initChannel() {
    final client = SupabaseService.instance.client;
    if (client == null || _channel != null) return;

    try {
      _channel = client.channel(
        channelName,
        opts: RealtimeChannelConfig(key: _clientId, enabled: true),
      );

      _channel!
          .onPresenceSync((payload) {
            _handlePresenceSync();
          })
          .onPresenceJoin((payload) {
            _handlePresenceSync();
          })
          .onPresenceLeave((payload) {
            _handlePresenceSync();
          })
          .subscribe((status, [error]) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _isSubscribed = true;
              if (_currentPresence != null) {
                await _trackCurrentPresence();
              }
            } else {
              _isSubscribed = false;
            }
          });
    } catch (e) {
      debugPrint('CoReadingService init warning: $e');
    }
  }

  void _handlePresenceSync() {
    if (_channel == null) return;
    try {
      final states = _channel!.presenceState();
      final List<LiveCoReader> readers = [];

      for (final single in states) {
        final key = single.key;
        for (final presence in single.presences) {
          final p = presence.payload;
          final bookTitle =
              p['bookTitle'] as String? ?? p['book_title'] as String?;
          if (bookTitle == null || bookTitle.trim().isEmpty) continue;

          final fullName = (p['fullName'] as String?)?.trim().isNotEmpty == true
              ? (p['fullName'] as String).trim()
              : (p['username'] as String?)?.trim().isNotEmpty == true
                  ? (p['username'] as String).trim()
                  : 'Quiet Reader';

          final initials = fullName
              .split(' ')
              .where((s) => s.isNotEmpty)
              .map((s) => s[0])
              .take(2)
              .join('')
              .toUpperCase();

          final startedAt = (p['startedAt'] is num)
              ? (p['startedAt'] as num).toInt()
              : DateTime.now().millisecondsSinceEpoch;
          final diffMs = DateTime.now().millisecondsSinceEpoch - startedAt;
          final minutesAgo = (diffMs / 60000).round().clamp(1, 1440);

          readers.add(
            LiveCoReader(
              userId: (p['userId'] as String?) ?? key,
              username: (p['username'] as String?) ?? 'reader',
              fullName: fullName,
              initials: initials.isNotEmpty ? initials : 'RD',
              avatarUrl:
                  p['avatarUrl'] as String? ?? p['avatar_url'] as String?,
              bookTitle: bookTitle,
              bookAuthor:
                  p['bookAuthor'] as String? ?? p['book_author'] as String?,
              sessionStartedMinutesAgo: minutesAgo,
              isCurrentUser: key == _clientId ||
                  ((p['userId'] as String?) != null &&
                      p['userId'] == SupabaseService.instance.currentUserId),
            ),
          );
        }
      }

      _rawPresences = readers;
      _updateActiveCoReaders();
    } catch (e) {
      debugPrint('CoReadingService presenceSync error: $e');
    }
  }

  List<LiveCoReader> _rawPresences = [];

  void _updateActiveCoReaders() {
    final list = List<LiveCoReader>.from(_rawPresences);
    if (_currentPresence != null) {
      final hasLocal = list.any((r) => r.isCurrentUser);
      if (!hasLocal) {
        final p = _currentPresence!;
        final fullName = (p['fullName'] as String?)?.trim().isNotEmpty == true
            ? (p['fullName'] as String).trim()
            : 'You';
        final initials = fullName
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join('')
            .toUpperCase();
        final startedAt = (p['startedAt'] is num)
            ? (p['startedAt'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch;
        final diffMs = DateTime.now().millisecondsSinceEpoch - startedAt;
        final minutesAgo = (diffMs / 60000).round().clamp(1, 1440);

        list.insert(
          0,
          LiveCoReader(
            userId: (p['userId'] as String?) ?? 'you',
            username: (p['username'] as String?) ?? 'you',
            fullName: fullName,
            initials: initials.isNotEmpty ? initials : 'YOU',
            avatarUrl: p['avatarUrl'] as String?,
            bookTitle: p['bookTitle'] as String? ?? 'Focus Session',
            bookAuthor: p['bookAuthor'] as String? ?? 'Reading Now',
            sessionStartedMinutesAgo: minutesAgo,
            isCurrentUser: true,
          ),
        );
      }
    } else {
      list.removeWhere((r) => r.isCurrentUser);
    }
    activeCoReaders.value = list;
  }

  /// Broadcast active reading session presence to other readers
  Future<void> track({
    required String bookTitle,
    String? bookAuthor,
    int? startedAt,
  }) async {
    // Ensure profile is loaded if user is authenticated
    if (SupabaseService.instance.isAuthenticated &&
        SupabaseService.instance.currentProfile == null) {
      await SupabaseService.instance.fetchCurrentUserProfile();
    }

    final profile = SupabaseService.instance.currentProfile;
    final user = SupabaseService.instance.client?.auth.currentUser;
    final userId = SupabaseService.instance.currentUserId ?? 'guest';

    String username = (profile?['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) {
      username = (user?.userMetadata?['username'] as String?)?.trim() ?? '';
    }
    if (username.isEmpty && user?.email != null) {
      username = user!.email!.split('@').first;
    }
    if (username.isEmpty) {
      username = 'reader';
    }

    String fullName = (profile?['full_name'] as String?)?.trim() ?? '';
    if (fullName.isEmpty) {
      fullName = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    }
    if (fullName.isEmpty) {
      fullName = username != 'reader'
          ? username
          : (SupabaseService.instance.isGuest
              ? 'Guest Explorer'
              : 'Quiet Reader');
    }

    final avatarUrl = (profile?['avatar_url'] as String?)?.trim() ??
        (user?.userMetadata?['avatar_url'] as String?)?.trim();

    final payload = <String, dynamic>{
      'userId': userId,
      'username': username,
      'fullName': fullName,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      'bookTitle': bookTitle,
      'bookAuthor': (bookAuthor != null && bookAuthor.trim().isNotEmpty)
          ? bookAuthor.trim()
          : 'Reading Now',
      'startedAt': startedAt ?? DateTime.now().millisecondsSinceEpoch,
      'clientId': _clientId,
    };

    _currentPresence = payload;
    _updateActiveCoReaders();

    if (_channel == null) {
      initChannel();
    } else if (_isSubscribed) {
      await _trackCurrentPresence();
    }
  }

  Future<void> _trackCurrentPresence() async {
    if (_channel == null || _currentPresence == null || !_isSubscribed) return;
    try {
      await _channel!.track(_currentPresence!);
    } catch (e) {
      debugPrint('CoReadingService track error: $e');
    }
  }

  /// Remove current user from live co-reading presence (timer paused, finished, or screen left)
  Future<void> untrack() async {
    _currentPresence = null;
    _updateActiveCoReaders();
    if (_channel != null && _isSubscribed) {
      try {
        await _channel!.untrack();
      } catch (e) {
        debugPrint('CoReadingService untrack error: $e');
      }
    }
  }
}

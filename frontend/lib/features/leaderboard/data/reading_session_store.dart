import 'package:flutter/foundation.dart';

import '../domain/leaderboard_models.dart';

/// Reactive store that syncs completed reading timer sessions directly to
/// the Daily, Weekly, and Yearly community leaderboards.
class ReadingSessionStore extends ChangeNotifier {
  ReadingSessionStore._() {
    _initDefaultData();
  }

  static final ReadingSessionStore instance = ReadingSessionStore._();

  /// Allows screens or dialogs (e.g. Timer completion dialog) to switch the active bottom nav tab.
  final ValueNotifier<int?> tabNavigationRequest = ValueNotifier<int?>(null);

  late List<LeaderboardEntry> _entries;
  late List<SavedReadingSession> _savedSessions;

  List<SavedReadingSession> get savedSessions => List.unmodifiable(_savedSessions);

  void _initDefaultData() {
    _entries = [
      const LeaderboardEntry(
        userId: 'u1',
        name: 'Julian Vance',
        handle: '@julian.reads',
        initials: 'JV',
        currentBook: 'The Shadow of the Wind',
        rankTier: 'Book sage',
        streakDays: 19,
        dailySeconds: 52 * 60, // 52m today
        weeklySeconds: (5 * 3600) + (40 * 60), // 5h 40m this week
        yearlySeconds: (58 * 3600) + (15 * 60), // 58h 15m this year
      ),
      const LeaderboardEntry(
        userId: 'u2',
        name: 'Amara Miles',
        handle: '@amara.m',
        initials: 'AM',
        currentBook: 'East of Eden',
        rankTier: 'Book sage',
        streakDays: 14,
        dailySeconds: 45 * 60, // 45m today
        weeklySeconds: (4 * 3600) + (50 * 60), // 4h 50m this week
        yearlySeconds: (51 * 3600) + (20 * 60), // 51h 20m this year
      ),
      const LeaderboardEntry(
        userId: 'u3',
        name: 'Jamie Lee',
        handle: '@jamie.lee',
        initials: 'JL',
        currentBook: 'The Creative Act',
        rankTier: 'Thoughtful reader',
        streakDays: 11,
        dailySeconds: 34 * 60, // 34m today
        weeklySeconds: (4 * 3600) + (5 * 60), // 4h 05m this week
        yearlySeconds: (46 * 3600) + (45 * 60), // 46h 45m this year
      ),
      const LeaderboardEntry(
        userId: 'current_user',
        name: 'Emma Laurent',
        handle: '@emma.reads',
        initials: 'EL',
        currentBook: 'Before the coffee gets cold',
        rankTier: 'Thoughtful reader',
        streakDays: 7,
        dailySeconds: 20 * 60, // 20m today
        weeklySeconds: (3 * 3600) + (36 * 60), // 3h 36m this week
        yearlySeconds: (42 * 3600) + (18 * 60), // 42h 18m this year
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        userId: 'u5',
        name: 'Daniel Cho',
        handle: '@dcho',
        initials: 'DC',
        currentBook: 'Atomic Habits',
        rankTier: 'Chapter explorer',
        streakDays: 6,
        dailySeconds: 18 * 60, // 18m today
        weeklySeconds: (3 * 3600) + (10 * 60), // 3h 10m this week
        yearlySeconds: (37 * 3600) + (50 * 60), // 37h 50m this year
      ),
      const LeaderboardEntry(
        userId: 'u6',
        name: 'Sofia Reyes',
        handle: '@sofia.lit',
        initials: 'SR',
        currentBook: 'The Story of Philosophy',
        rankTier: 'Chapter explorer',
        streakDays: 5,
        dailySeconds: 15 * 60, // 15m today
        weeklySeconds: (2 * 3600) + (45 * 60), // 2h 45m this week
        yearlySeconds: (31 * 3600) + (12 * 60), // 31h 12m this year
      ),
      const LeaderboardEntry(
        userId: 'u7',
        name: 'Liam O\'Connor',
        handle: '@liam.oc',
        initials: 'LO',
        currentBook: 'Norwegian Wood',
        rankTier: 'Steady reader',
        streakDays: 3,
        dailySeconds: 10 * 60, // 10m today
        weeklySeconds: (1 * 3600) + (55 * 60), // 1h 55m this week
        yearlySeconds: (24 * 3600) + (40 * 60), // 24h 40m this year
      ),
    ];

    _savedSessions = [
      SavedReadingSession(
        id: 's1',
        bookTitle: 'Before the coffee gets cold',
        durationSeconds: 20 * 60,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Resets the store to initial mock state (useful for deterministic widget tests).
  void reset() {
    _initDefaultData();
    notifyListeners();
  }

  /// Records a completed reading timer session and updates the current user's
  /// daily, weekly, and yearly leaderboard totals.
  void recordSession({
    required String bookTitle,
    required int durationSeconds,
  }) {
    if (durationSeconds <= 0) return;

    final index = _entries.indexWhere((e) => e.isCurrentUser);
    if (index != -1) {
      _entries[index] = _entries[index].addSessionSeconds(
        durationSeconds,
        updatedBook: bookTitle,
      );
    }

    _savedSessions.insert(
      0,
      SavedReadingSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        bookTitle: bookTitle,
        durationSeconds: durationSeconds,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// Returns all entries sorted by highest reading time for the given [period].
  List<LeaderboardEntry> getRankedEntries(LeaderboardPeriod period) {
    final sorted = List<LeaderboardEntry>.from(_entries);
    sorted.sort((a, b) => b.secondsFor(period).compareTo(a.secondsFor(period)));
    return sorted;
  }

  /// Returns the current user's 1-based rank for the given [period].
  int getCurrentUserRank(LeaderboardPeriod period) {
    final ranked = getRankedEntries(period);
    final idx = ranked.indexWhere((e) => e.isCurrentUser);
    return idx == -1 ? ranked.length : idx + 1;
  }

  /// Returns the current user's entry.
  LeaderboardEntry get currentUserEntry {
    return _entries.firstWhere((e) => e.isCurrentUser);
  }

  /// Requests MainNavigationShell to switch to [tabIndex].
  void navigateToTab(int tabIndex) {
    tabNavigationRequest.value = tabIndex;
  }
}

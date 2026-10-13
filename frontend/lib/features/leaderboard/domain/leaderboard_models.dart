// Domain models for the Community Leaderboard feature (Daily, Weekly, Yearly ranks).

enum LeaderboardPeriod { daily, weekly, yearly }

class SavedReadingSession {
  final String id;
  final String bookTitle;
  final int durationSeconds;
  final DateTime timestamp;

  const SavedReadingSession({
    required this.id,
    required this.bookTitle,
    required this.durationSeconds,
    required this.timestamp,
  });

  String get formattedDuration => LeaderboardEntry.formatSeconds(durationSeconds);
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final String handle;
  final String initials;
  final String currentBook;
  final String rankTier;
  final int streakDays;
  final int dailySeconds;
  final int weeklySeconds;
  final int yearlySeconds;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.handle,
    required this.initials,
    required this.currentBook,
    required this.rankTier,
    required this.streakDays,
    required this.dailySeconds,
    required this.weeklySeconds,
    required this.yearlySeconds,
    this.isCurrentUser = false,
  });

  LeaderboardEntry addSessionSeconds(int addedSeconds, {String? updatedBook}) {
    return LeaderboardEntry(
      userId: userId,
      name: name,
      handle: handle,
      initials: initials,
      currentBook: updatedBook ?? currentBook,
      rankTier: rankTier,
      streakDays: streakDays,
      dailySeconds: dailySeconds + addedSeconds,
      weeklySeconds: weeklySeconds + addedSeconds,
      yearlySeconds: yearlySeconds + addedSeconds,
      isCurrentUser: isCurrentUser,
    );
  }

  int secondsFor(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return dailySeconds;
      case LeaderboardPeriod.weekly:
        return weeklySeconds;
      case LeaderboardPeriod.yearly:
        return yearlySeconds;
    }
  }

  String formattedTimeFor(LeaderboardPeriod period) {
    return formatSeconds(secondsFor(period));
  }

  static String formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    if (minutes > 0) {
      if (seconds > 0 && minutes < 10) {
        return '${minutes}m ${seconds}s';
      }
      return '${minutes}m';
    }
    return '${seconds}s';
  }
}

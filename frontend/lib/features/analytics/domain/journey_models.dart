// Domain models for the Reading Journey (Analytics) feature.

enum JourneyPeriod { week, month, year }

class PeriodStats {
  final String booksFinished;
  final String booksComparison;
  final String timeWellSpent;
  final String sessionsSubtitle;

  const PeriodStats({
    required this.booksFinished,
    required this.booksComparison,
    required this.timeWellSpent,
    required this.sessionsSubtitle,
  });
}

class DailyReadingBar {
  final String dayLabel;
  final String fullDayName;
  final int minutes;
  final double normalizedHeight; // 0.0 to 1.0
  final bool isToday;

  const DailyReadingBar({
    required this.dayLabel,
    required this.fullDayName,
    required this.minutes,
    required this.normalizedHeight,
    this.isToday = false,
  });
}

class ReaderLevelTier {
  final int level;
  final String title;
  final int minPoints;
  final int maxPoints;
  final String description;

  const ReaderLevelTier({
    required this.level,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
    required this.description,
  });
}

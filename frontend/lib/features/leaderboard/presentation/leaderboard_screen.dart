import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../data/reading_session_store.dart';
import '../domain/leaderboard_models.dart';
import 'widgets/leaderboard_list_tile.dart';
import 'widgets/leaderboard_period_selector.dart';
import 'widgets/leaderboard_podium.dart';
import 'widgets/user_rank_banner.dart';

/// Community Leaderboard screen ("Reading circle") with Daily, Weekly, and Yearly ranks.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.daily;

  void _showSavedSessionsSheet(BuildContext context) {
    final sessions = ReadingSessionStore.instance.savedSessions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Synced Timer Sessions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Every finished timer session automatically updates your Daily, Weekly, and Yearly rank.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...sessions.take(5).map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${s.formattedDuration}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReadingSessionStore.instance,
      builder: (context, _) {
        final store = ReadingSessionStore.instance;
        final rankedEntries = store.getRankedEntries(_selectedPeriod);
        final userRank = store.getCurrentUserRank(_selectedPeriod);
        final userEntry = store.currentUserEntry;
        final nextHigherEntry =
            userRank > 1 ? rankedEntries[userRank - 2] : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ───────────────────────────────────
                  _buildHeader(context),
                  const SizedBox(height: 18),

                  // ── Daily / Weekly / Yearly Selector ─────────
                  LeaderboardPeriodSelector(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: (period) {
                      setState(() => _selectedPeriod = period);
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Top-3 Podium ─────────────────────────────
                  LeaderboardPodium(
                    topThree: rankedEntries.take(3).toList(),
                    period: _selectedPeriod,
                  ),
                  const SizedBox(height: 16),

                  // ── Current User Standing Banner ─────────────
                  UserRankBanner(
                    userEntry: userEntry,
                    userRank: userRank,
                    nextHigherEntry: nextHigherEntry,
                    period: _selectedPeriod,
                  ),
                  const SizedBox(height: 24),

                  // ── Ranked List Header ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All readers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${rankedEntries.length} in your circle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A7E6F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── All Readers Ranked List ──────────────────
                  ...List.generate(rankedEntries.length, (index) {
                    return LeaderboardListTile(
                      entry: rankedEntries[index],
                      rank: index + 1,
                      period: _selectedPeriod,
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading circle',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Every page counts. Inspired together.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Synced sessions history icon button
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
            onPressed: () => _showSavedSessionsSheet(context),
            padding: EdgeInsets.zero,
            tooltip: 'Synced sessions',
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

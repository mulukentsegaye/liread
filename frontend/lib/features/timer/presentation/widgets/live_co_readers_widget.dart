import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/co_reading_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../leaderboard/data/reading_session_store.dart';

/// Horizontal banner displayed on the Discover Feed (Home Page) showing
/// currently reading readers whose timers are activated.
class LiveCoReadingFeedBanner extends StatelessWidget {
  const LiveCoReadingFeedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LiveCoReader>>(
      valueListenable: CoReadingService.instance.activeCoReaders,
      builder: (context, readers, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = AppColors.resolve(
          context,
          light: AppColors.surface,
          dark: AppColors.darkSurface,
        );
        final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Row ─────────────────────────────
              Row(
                children: [
                  // Pulsing emerald indicator
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6610B981),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Co-Reading',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      readers.isEmpty ? 'Quiet' : '${readers.length} active',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      ReadingSessionStore.instance.tabNavigationRequest.value = 2;
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            readers.any((r) => r.isCurrentUser)
                                ? 'View Timer'
                                : 'Start Focus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Readers currently in quiet focus sessions',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // ── Active Readers List or Empty State ─────────
              if (readers.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.resolve(
                      context,
                      light: AppColors.background,
                      dark: AppColors.darkBookCardBackground,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 20,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No one reading right now. Start a timer to lead the circle!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: readers.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final reader = readers[index];
                      return _ReaderPillCard(reader: reader);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Rich "Live Reading Room" widget displayed at the top of the Reading Circle (Leaderboard)
/// and Reading Timer screen, mirroring the Sanctuary view from the web.
class LiveReadingRoomWidget extends StatelessWidget {
  final bool showStartButton;

  const LiveReadingRoomWidget({
    super.key,
    this.showStartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LiveCoReader>>(
      valueListenable: CoReadingService.instance.activeCoReaders,
      builder: (context, readers, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = AppColors.resolve(
          context,
          light: AppColors.surface,
          dark: AppColors.darkSurface,
        );
        final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ─────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6610B981),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Live Reading Room',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.2),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                '${readers.length} currently reading',
                                style: GoogleFonts.dmMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Quiet companionship in books. Focused minds reading side by side.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStartButton &&
                      !readers.any((r) => r.isCurrentUser)) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ReadingSessionStore.instance.tabNavigationRequest.value = 2;
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 14),
                      label: const Text(
                        'Read',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Reader Cards ───────────────────────────────
              if (readers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.resolve(
                      context,
                      light: AppColors.background,
                      dark: AppColors.darkBookCardBackground,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No co-readers currently in an active session. Tap "Read" to start reading!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: readers.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final reader = readers[index];
                      return _ReaderPillCard(reader: reader, isRoomCard: true);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReaderPillCard extends StatelessWidget {
  final LiveCoReader reader;
  final bool isRoomCard;

  const _ReaderPillCard({
    required this.reader,
    this.isRoomCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = reader.isCurrentUser
        ? (isDark
            ? AppColors.darkPrimarySurface
            : AppColors.primarySurface.withValues(alpha: 0.6))
        : AppColors.resolve(
            context,
            light: isRoomCard ? AppColors.background : AppColors.bookCardBackground,
            dark: AppColors.darkBookCardBackground,
          );
    final borderColor = reader.isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.35)
        : (isDark ? AppColors.darkDivider : AppColors.divider);

    return Container(
      width: isRoomCard ? 200 : 185,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Avatar with emerald live dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (reader.avatarUrl != null &&
                  reader.avatarUrl!.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    reader.avatarUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitials(),
                  ),
                )
              else
                _buildInitials(),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cardBg,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 9),

          // Name and book title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reader.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: reader.isCurrentUser
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    ),
                    if (reader.isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: GoogleFonts.dmMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'reading ${reader.bookTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${reader.sessionStartedMinutesAgo}m in focus',
                  style: GoogleFonts.dmMono(
                    fontSize: 9.5,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          reader.initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

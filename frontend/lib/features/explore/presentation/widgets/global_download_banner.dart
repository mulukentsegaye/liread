import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/ebook_download_service.dart';

/// Floating global banner shown above the bottom navigation bar whenever a book
/// is downloading or recently completed, enabling users to explore the app freely.
class GlobalDownloadBanner extends StatelessWidget {
  const GlobalDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ActiveDownloadTask?>(
      valueListenable: EbookDownloadService.instance.currentTask,
      builder: (context, task, _) {
        if (task == null ||
            task.status == DownloadTaskStatus.idle ||
            task.status == DownloadTaskStatus.canceled) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = AppColors.resolve(
          context,
          light: AppColors.surface,
          dark: AppColors.darkSurface,
        );
        final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
        final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

        final isCompleted = task.status == DownloadTaskStatus.completed;
        final isFailed = task.status == DownloadTaskStatus.failed;
        final isDownloading = task.status == DownloadTaskStatus.downloading;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : (isFailed ? Colors.red.withValues(alpha: 0.4) : borderColor),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Status Icon
                  if (isDownloading)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                    )
                  else if (isCompleted)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 10),

                  // Title and Subtext
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.format.toUpperCase(),
                                style: GoogleFonts.dmMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDownloading
                              ? (task.progress >= 0
                                  ? 'Downloading • ${(task.progress * 100).toInt()}% • Runs in background'
                                  : 'Connecting to archive servers...')
                              : (isCompleted
                                  ? 'Downloaded to device • Tap Open to read'
                                  : (task.errorMessage ?? 'Download failed')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isCompleted
                                ? const Color(0xFF059669)
                                : (isFailed ? Colors.red : AppColors.textSecondary),
                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Actions
                  if (isCompleted) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final target = task.localUri ?? task.localFilePath;
                        if (target != null) {
                          EbookDownloadService.instance.openDownloadedBook(
                            target,
                            downloadId: task.nativeDownloadId,
                            format: task.format,
                          );
                        }
                      },
                      child: Text(
                        'Open',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Dismiss or Cancel button
                  IconButton(
                    icon: Icon(
                      isDownloading ? Icons.close_rounded : Icons.clear_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    splashRadius: 16,
                    tooltip: isDownloading ? 'Cancel download' : 'Dismiss',
                    onPressed: () {
                      if (isDownloading) {
                        EbookDownloadService.instance.cancelCurrentDownload();
                      } else {
                        EbookDownloadService.instance.dismissTask();
                      }
                    },
                  ),
                ],
              ),

              // Progress Bar while downloading
              if (isDownloading) ...[
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: task.progress >= 0 ? task.progress : null,
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    color: primaryColor,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

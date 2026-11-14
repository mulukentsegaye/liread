import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/open_library_service.dart';
import 'book_cover_image.dart';

/// Modal bottom sheet displaying detailed book metadata and actions.
class BookDetailsSheet extends StatefulWidget {
  final OpenLibraryBook book;
  final ValueChanged<OpenLibraryBook>? onStartTimer;
  final ValueChanged<OpenLibraryBook>? onShareBook;

  const BookDetailsSheet({
    super.key,
    required this.book,
    this.onStartTimer,
    this.onShareBook,
  });

  static Future<void> show(
    BuildContext context, {
    required OpenLibraryBook book,
    ValueChanged<OpenLibraryBook>? onStartTimer,
    ValueChanged<OpenLibraryBook>? onShareBook,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookDetailsSheet(
        book: book,
        onStartTimer: onStartTimer,
        onShareBook: onShareBook,
      ),
    );
  }

  @override
  State<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends State<BookDetailsSheet> {
  late OpenLibraryBook _book;
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_book.description == null && _book.workKey != null) {
      setState(() => _loadingDetails = true);
      final enriched =
          await OpenLibraryService.instance.fetchBookDetails(_book);
      if (mounted) {
        setState(() {
          _book = enriched;
          _loadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.instance.isDarkMode;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Banner & Metadata Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover
                      SizedBox(
                        width: 100,
                        child: BookCoverImage(
                          title: _book.title,
                          author: _book.author,
                          coverUrl: _book.coverImageUrl ?? _book.coverThumbnailUrl,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title, Author, Year, Source
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _book.title,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _book.author,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (_book.firstPublishYear != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'First published ${_book.firstPublishYear}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),

                            // Open Library verification badge
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Open Library Catalog',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subject Pills
                  if (_book.subjects.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _book.subjects.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimarySurface
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Divider
                  Divider(color: dividerColor),
                  const SizedBox(height: 12),

                  // Description Header
                  Text(
                    'About this book',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (_loadingDetails)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading editorial description...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_book.description != null &&
                      _book.description!.isNotEmpty)
                    Text(
                      _book.description!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: textSecondary,
                      ),
                    )
                  else
                    Text(
                      'No editorial summary is currently recorded in Open Library for this edition. You can still track your reading session and save quotes from it.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: textSecondary,
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action Buttons
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await SupabaseService.instance.updateBookStatus(
                        title: _book.title,
                        author: _book.author,
                        status: 'want_to_read',
                        coverImageUrl: _book.coverImageUrl,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${_book.title}" added to your bookshelf!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                    label: Text(
                      'Add to Shelf',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onStartTimer?.call(_book);
                    },
                    icon: const Icon(Icons.timer_outlined, size: 17),
                    label: Text(
                      'Read in Timer',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF222B25)
                        : const Color(0xFFEEF2EF),
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

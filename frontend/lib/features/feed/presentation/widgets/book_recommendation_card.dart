import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/post_model.dart';
import 'book_cover_placeholder.dart';

/// A card displaying a book recommendation with cover, metadata,
/// star rating, and a snippet of the user's recommendation text.
class BookRecommendationCard extends StatelessWidget {
  final BookRecommendation data;

  const BookRecommendationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Book info card ─────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.bookCardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cover
                BookCoverPlaceholder(
                  title: data.bookTitle,
                  author: data.bookAuthor,
                ),
                const SizedBox(width: 16),

                // Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Text(
                        'WORTH A READ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        data.bookTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Author
                      Text(
                        data.bookAuthor,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stars
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < data.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: AppColors.starActive,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),

                      // Category + Pages
                      Text(
                        '${data.category} · ${data.pages} pages',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Recommendation text ────────────────────────────
          if (data.recommendationText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              data.recommendationText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}

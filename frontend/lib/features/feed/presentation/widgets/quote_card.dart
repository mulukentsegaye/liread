import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/post_model.dart';

/// A card displaying a saved passage / quote with large
/// typographic treatment and attribution.
class QuoteCard extends StatelessWidget {
  final QuotePost data;

  const QuoteCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.quoteCardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote marks
            Text(
              '\u201C',
              style: GoogleFonts.lora(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.4),
                height: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Quote text
            Text(
              data.quoteText,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Attribution
            Text(
              '${data.quoteAuthor} · ${data.bookTitle}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

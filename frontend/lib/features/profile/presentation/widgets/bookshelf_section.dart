import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/profile_models.dart';

/// "On my shelf" section showing the user's 3 featured books and a "View all" sheet.
class BookshelfSection extends StatelessWidget {
  final List<ShelfBook> books;
  final VoidCallback onViewAll;

  const BookshelfSection({
    super.key,
    required this.books,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'On my shelf',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View all',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A7E6F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── 3 Book Covers Row ────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < books.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _ShelfBookTile(book: books[i]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ShelfBookTile extends StatelessWidget {
  final ShelfBook book;

  const _ShelfBookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final isReading = book.status == ShelfStatus.reading;

    return Column(
      children: [
        // Cover container
        AspectRatio(
          aspectRatio: 0.70,
          child: Container(
            decoration: BoxDecoration(
              color: book.coverColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Book Title
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: book.textColor,
                    height: 1.2,
                  ),
                ),

                // Center Motif based on book id
                _buildCenterMotif(book),

                // Author
                Text(
                  book.author.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: book.textColor.withValues(alpha: 0.75),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Status label ("Reading", "Finished", "Want to read")
        Text(
          book.statusLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isReading ? FontWeight.w600 : FontWeight.w500,
            color: isReading
                ? const Color(0xFF5A7E6F)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterMotif(ShelfBook book) {
    if (book.id == '1') {
      // Coffee cup with steam
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '~ ~ ~',
            style: TextStyle(
              fontSize: 7,
              color: book.textColor.withValues(alpha: 0.65),
              height: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            Icons.coffee_outlined,
            size: 22,
            color: book.textColor.withValues(alpha: 0.85),
          ),
        ],
      );
    } else if (book.id == '2') {
      // Minimalist circle for The Creative Act
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: book.textColor.withValues(alpha: 0.75),
            width: 1.2,
          ),
        ),
      );
    } else {
      // Botanical flower for The Wild Iris
      return Icon(
        Icons.local_florist_outlined,
        size: 24,
        color: book.textColor.withValues(alpha: 0.8),
      );
    }
  }
}

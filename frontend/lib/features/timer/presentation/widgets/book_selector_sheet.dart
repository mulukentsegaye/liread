import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/book_model.dart';

/// Modal bottom sheet for switching currently active book.
class BookSelectorSheet extends StatelessWidget {
  final List<ReadingBook> books;
  final ReadingBook selectedBook;
  final ValueChanged<ReadingBook> onSelect;

  const BookSelectorSheet({
    super.key,
    required this.books,
    required this.selectedBook,
    required this.onSelect,
  });

  static Future<ReadingBook?> show(
    BuildContext context, {
    required List<ReadingBook> books,
    required ReadingBook selectedBook,
  }) {
    return showModalBottomSheet<ReadingBook>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BookSelectorSheet(
        books: books,
        selectedBook: selectedBook,
        onSelect: (b) => Navigator.of(ctx).pop(b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Select Book',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose which book you want to log your reading time for.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: books.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final book = books[index];
                final isSelected = book.id == selectedBook.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 36,
                    height: 50,
                    decoration: BoxDecoration(
                      color: book.coverColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      book.coverIcon ?? Icons.menu_book_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    book.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${book.author} · ${book.currentPage}/${book.totalPages} pages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                      : null,
                  onTap: () => onSelect(book),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

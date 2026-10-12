import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Bottom action rows on the profile page ("Saved passages" & "My reading circles").
class ProfileMenuSection extends StatelessWidget {
  final int savedPassagesCount;
  final int readingCirclesCount;
  final VoidCallback onSavedPassagesTap;
  final VoidCallback onReadingCirclesTap;

  const ProfileMenuSection({
    super.key,
    required this.savedPassagesCount,
    required this.readingCirclesCount,
    required this.onSavedPassagesTap,
    required this.onReadingCirclesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 6),

        // ── Saved passages ───────────────────────────────────
        _MenuRow(
          icon: Icons.bookmark_border_rounded,
          title: 'Saved passages',
          trailingText: '$savedPassagesCount',
          onTap: onSavedPassagesTap,
        ),

        // ── My reading circles ───────────────────────────────
        _MenuRow(
          icon: Icons.people_outline_rounded,
          title: 'My reading circles',
          trailingText: '$readingCirclesCount circles',
          onTap: onReadingCirclesTap,
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailingText;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF5A7E6F),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              trailingText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

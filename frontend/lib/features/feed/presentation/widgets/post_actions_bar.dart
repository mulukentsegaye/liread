import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Heart, comment, bookmark action row beneath every post.
class PostActionsBar extends StatelessWidget {
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;

  const PostActionsBar({
    super.key,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Like
          _ActionChip(
            icon: isLiked ? Icons.favorite : Icons.favorite_border_rounded,
            iconColor: isLiked ? Colors.redAccent : AppColors.textSecondary,
            label: likes.toString(),
            labelStyle: textStyle,
            onTap: () {},
          ),
          const SizedBox(width: 16),

          // Comment
          _ActionChip(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.textSecondary,
            label: comments.toString(),
            labelStyle: textStyle,
            onTap: () {},
          ),

          const Spacer(),

          // Bookmark
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isBookmarked
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/reader_avatar.dart';

/// User avatar + name + action text + time + more button.
class FeedPostHeader extends StatelessWidget {
  final String userName;
  final String userInitials;
  final String? avatarUrl;
  final String actionText;
  final String timeAgo;

  const FeedPostHeader({
    super.key,
    required this.userName,
    required this.userInitials,
    this.avatarUrl,
    required this.actionText,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar
          ReaderAvatar(
            avatarUrl: avatarUrl,
            name: userName,
            initials: userInitials,
            radius: 20,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          const SizedBox(width: 12),

          // Name + action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '$actionText · $timeAgo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // More options
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

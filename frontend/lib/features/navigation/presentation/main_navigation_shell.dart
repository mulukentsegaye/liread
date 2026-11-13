import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../analytics/presentation/reading_journey_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../feed/presentation/discover_feed_screen.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../profile/presentation/reader_profile_screen.dart';
import '../../timer/presentation/reading_timer_screen.dart';

/// Root scaffold with bottom navigation hosting the six main tabs:
/// Feed, Explore (Open Library), Read (Timer), Journey, Ranks (Leaderboard), and Profile.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  // All six main app screens: Feed, Explore, Read, Journey, Ranks, Profile.
  final List<Widget> _screens = const [
    DiscoverFeedScreen(),
    ExploreScreen(),
    ReadingTimerScreen(),
    ReadingJourneyScreen(),
    LeaderboardScreen(),
    ReaderProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    ReadingSessionStore.instance.tabNavigationRequest
        .addListener(_onExternalTabRequest);
  }

  @override
  void dispose() {
    ReadingSessionStore.instance.tabNavigationRequest
        .removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final target = ReadingSessionStore.instance.tabNavigationRequest.value;
    if (target != null && target >= 0 && target < _screens.length && mounted) {
      setState(() => _currentIndex = target);
      ReadingSessionStore.instance.tabNavigationRequest.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        final isDark = AppThemeController.instance.isDarkMode;
        final navSurface = isDark ? AppColors.darkSurface : AppColors.surface;
        final navDivider = isDark ? AppColors.darkDivider : AppColors.divider;
        final activePillColor = isDark
            ? AppColors.darkPrimarySurface
            : const Color(0xFFE2EBE5);
        final activeIconColor =
            isDark ? AppColors.darkPrimary : AppColors.primary;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navSurface,
              border: Border(
                top: BorderSide(
                  color: navDivider,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.layers_outlined,
                    activeIcon: Icons.layers_rounded,
                    label: 'Feed',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Explore',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'Read',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Journey',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.emoji_events_outlined,
                    activeIcon: Icons.emoji_events_rounded,
                    label: 'Ranks',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    activePillColor: activePillColor,
                    activeIconColor: activeIconColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activePillColor,
    required Color activeIconColor,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final inactiveTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.tabInactive;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active pill indicator around the icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? activePillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 21,
                color: isSelected
                    ? activeIconColor
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.iconDefault),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeIconColor : inactiveTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

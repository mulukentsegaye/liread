import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../analytics/presentation/reading_journey_screen.dart';
import '../../feed/presentation/discover_feed_screen.dart';
import '../../leaderboard/data/reading_session_store.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../profile/presentation/reader_profile_screen.dart';
import '../../timer/presentation/reading_timer_screen.dart';

/// Root scaffold with bottom navigation hosting the five main tabs:
/// Feed, Read, Journey, Ranks (Leaderboard), and Profile.
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

  // All five main app screens: Feed, Read, Journey, Ranks, Profile.
  final List<Widget> _screens = const [
    DiscoverFeedScreen(),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 12),
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
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Read',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Journey',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events_rounded,
                label: 'Ranks',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active pill indicator around the icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE2EBE5) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.iconDefault,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.tabInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

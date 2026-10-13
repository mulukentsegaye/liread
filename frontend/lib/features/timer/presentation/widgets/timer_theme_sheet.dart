import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/timer_theme_model.dart';

/// Modal bottom sheet for browsing and switching counter themes
/// tailored specifically to the app's Light Mode and Dark Mode.
class TimerThemeSheet extends StatefulWidget {
  final CounterThemeId currentThemeId;
  final ValueChanged<CounterThemeId> onThemeSelected;

  const TimerThemeSheet({
    super.key,
    required this.currentThemeId,
    required this.onThemeSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required CounterThemeId currentThemeId,
    required ValueChanged<CounterThemeId> onThemeSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TimerThemeSheet(
        currentThemeId: currentThemeId,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  State<TimerThemeSheet> createState() => _TimerThemeSheetState();
}

class _TimerThemeSheetState extends State<TimerThemeSheet> {
  late bool _showDarkThemes;

  @override
  void initState() {
    super.initState();
    // Default to the current app mode (or the selected theme's dark/light nature)
    final isAppDark = AppThemeController.instance.isDarkMode;
    final isCurrentThemeDark = CounterThemeConfig.byId(widget.currentThemeId).isDark;
    _showDarkThemes = isAppDark || isCurrentThemeDark;
  }

  @override
  Widget build(BuildContext context) {
    final isAppDark = AppThemeController.instance.isDarkMode;
    final themesToShow = CounterThemeConfig.getThemesForMode(_showDarkThemes);

    final sheetBg = isAppDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary = isAppDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isAppDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isAppDark ? AppColors.darkDivider : AppColors.divider;
    final cardBg = isAppDark ? AppColors.darkBackground : AppColors.background;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row with App Mode Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Counter Theme',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showDarkThemes
                        ? 'Dark mode timer counter aesthetics'
                        : 'Light mode timer counter aesthetics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),

              // Quick App Mode Toggle Chip
              InkWell(
                onTap: () {
                  AppThemeController.instance.toggleThemeMode();
                  final nextIsDark = AppThemeController.instance.isDarkMode;
                  setState(() => _showDarkThemes = nextIsDark);
                  // Automatically switch timer theme to a matching one for the new mode
                  widget.onThemeSelected(CounterThemeConfig.defaultForMode(nextIsDark).id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAppDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 15,
                        color: isAppDark ? const Color(0xFF65927D) : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAppDark ? 'Dark App' : 'Light App',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Mode Tab Bar (Light Themes | Dark Themes) ─────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showDarkThemes = false);
                      if (isAppDark) {
                        AppThemeController.instance.setThemeMode(ThemeMode.light);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showDarkThemes ? sheetBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_showDarkThemes
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 15,
                            color: !_showDarkThemes
                                ? (isAppDark ? AppColors.darkPrimary : AppColors.primary)
                                : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Light Themes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: !_showDarkThemes
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !_showDarkThemes
                                  ? (isAppDark ? AppColors.darkPrimary : AppColors.primary)
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showDarkThemes = true);
                      if (!isAppDark) {
                        AppThemeController.instance.setThemeMode(ThemeMode.dark);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showDarkThemes ? sheetBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _showDarkThemes
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            size: 15,
                            color: _showDarkThemes
                                ? (isAppDark ? AppColors.darkPrimary : AppColors.primary)
                                : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dark Themes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: _showDarkThemes
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _showDarkThemes
                                  ? (isAppDark ? AppColors.darkPrimary : AppColors.primary)
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Theme Tiles List ──────────────────────────────
          ...themesToShow.map((theme) {
            final isSelected = theme.id == widget.currentThemeId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  widget.onThemeSelected(theme.id);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAppDark ? const Color(0xFF1F2B24) : const Color(0xFFEDF2EE))
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isAppDark ? AppColors.darkPrimary : AppColors.primary)
                          : dividerColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Preview Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            if (theme.glowColors.isNotEmpty && theme.isDark)
                              BoxShadow(
                                color: theme.glowColors.last.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          theme.themeIcon,
                          color: theme.accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme.tagLine,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: isAppDark ? AppColors.darkPrimary : AppColors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

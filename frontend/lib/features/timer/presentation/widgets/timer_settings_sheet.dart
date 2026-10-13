import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/timer_theme_model.dart';

/// Modal bottom sheet for configuring reading session settings (goal, app mode, counter theme, etc.).
class TimerSettingsSheet extends StatefulWidget {
  final int currentGoalMinutes;
  final ValueChanged<int> onGoalChanged;
  final CounterThemeId currentThemeId;
  final ValueChanged<CounterThemeId>? onThemeChanged;

  const TimerSettingsSheet({
    super.key,
    required this.currentGoalMinutes,
    required this.onGoalChanged,
    this.currentThemeId = CounterThemeId.sageOrganic,
    this.onThemeChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentGoalMinutes,
    required ValueChanged<int> onGoalChanged,
    CounterThemeId currentThemeId = CounterThemeId.sageOrganic,
    ValueChanged<CounterThemeId>? onThemeChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TimerSettingsSheet(
        currentGoalMinutes: currentGoalMinutes,
        onGoalChanged: onGoalChanged,
        currentThemeId: currentThemeId,
        onThemeChanged: onThemeChanged,
      ),
    );
  }

  @override
  State<TimerSettingsSheet> createState() => _TimerSettingsSheetState();
}

class _TimerSettingsSheetState extends State<TimerSettingsSheet> {
  late int _selectedGoal;
  late CounterThemeId _selectedThemeId;
  bool _soundEnabled = true;
  bool _keepScreenOn = true;

  final List<int> _goals = [15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoalMinutes;
    _selectedThemeId = widget.currentThemeId;
  }

  @override
  Widget build(BuildContext context) {
    final isAppDark = AppThemeController.instance.isDarkMode;
    final themesToShow = CounterThemeConfig.getThemesForMode(isAppDark);

    final sheetBg = isAppDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary = isAppDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isAppDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isAppDark ? AppColors.darkDivider : AppColors.divider;
    final cardBg = isAppDark ? AppColors.darkBackground : AppColors.background;
    final accentPrimary = isAppDark ? AppColors.darkPrimary : AppColors.primary;

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

          Text(
            'Session Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // ── App Mode Toggle ──────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accentPrimary,
            secondary: Icon(
              isAppDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: accentPrimary,
              size: 22,
            ),
            title: Text(
              'App Dark Mode',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              isAppDark
                  ? 'Dark UI with glowing night counter themes'
                  : 'Clean light UI with airy counter themes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            value: isAppDark,
            onChanged: (val) {
              AppThemeController.instance.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              final defaultTheme = CounterThemeConfig.defaultForMode(val);
              setState(() => _selectedThemeId = defaultTheme.id);
              widget.onThemeChanged?.call(defaultTheme.id);
            },
          ),
          const SizedBox(height: 12),

          // ── Daily Goal section ───────────────────────────
          Text(
            'SESSION GOAL',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _goals.map((goal) {
              final isSelected = goal == _selectedGoal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedGoal = goal);
                      widget.onGoalChanged(goal);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accentPrimary : cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? accentPrimary : dividerColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${goal}m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Counter Theme section ────────────────────────
          Text(
            isAppDark ? 'DARK COUNTER THEMES' : 'LIGHT COUNTER THEMES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: themesToShow.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final theme = themesToShow[index];
                final isSelected = theme.id == _selectedThemeId;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedThemeId = theme.id);
                    widget.onThemeChanged?.call(theme.id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isAppDark ? const Color(0xFF1F2B24) : const Color(0xFFEDF2EE))
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentPrimary : dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.isDark ? Colors.white30 : Colors.black12,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            theme.themeIcon,
                            size: 15,
                            color: theme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              theme.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              theme.isDark ? 'Dark glow' : 'Light clean',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accentPrimary,
            title: Text(
              'Chime when goal reached',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              'Gentle notification upon completion',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: accentPrimary,
            title: Text(
              'Keep screen awake',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              'Prevent device from sleeping during reading',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            value: _keepScreenOn,
            onChanged: (v) => setState(() => _keepScreenOn = v),
          ),
        ],
      ),
    );
  }
}

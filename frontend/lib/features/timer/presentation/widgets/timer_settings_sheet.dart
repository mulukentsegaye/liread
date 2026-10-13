import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/timer_theme_model.dart';

/// Modal bottom sheet for configuring reading session settings (goal, counter theme, ambient, etc.).
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
            'Session Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Daily Goal section
          Text(
            'SESSION GOAL',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
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
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${goal}m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Counter Theme section
          Text(
            'COUNTER THEME',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CounterThemeConfig.allThemes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final theme = CounterThemeConfig.allThemes[index];
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
                      color: isSelected ? const Color(0xFFEDF2EE) : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
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
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              theme.isDark ? 'Dark glow' : 'Light clean',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
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
          const SizedBox(height: 20),

          // Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text(
              'Chime when goal reached',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Gentle notification upon completion',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text(
              'Keep screen awake',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Prevent device from sleeping during reading',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _keepScreenOn,
            onChanged: (v) => setState(() => _keepScreenOn = v),
          ),
        ],
      ),
    );
  }
}

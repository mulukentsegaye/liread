import 'package:flutter/material.dart';

/// Available themes for the Reading Timer counter.
enum CounterThemeId {
  sageOrganic,
  obsidianEmber,
  ceramicFrost,
  midnightAurora,
  solarSandstone,
}

/// Configuration defining the visual aesthetics of a timer counter theme.
class CounterThemeConfig {
  final CounterThemeId id;
  final String name;
  final String tagLine;
  final Color cardBackground;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final bool isDark;
  final List<Color> glowColors;
  final Color tickColor;
  final Color activeTickColor;
  final Color needleColor;
  final Color ringTrackColor;
  final Color ringProgressColor;
  final IconData themeIcon;

  const CounterThemeConfig({
    required this.id,
    required this.name,
    required this.tagLine,
    required this.cardBackground,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.isDark,
    required this.glowColors,
    required this.tickColor,
    required this.activeTickColor,
    required this.needleColor,
    required this.ringTrackColor,
    required this.ringProgressColor,
    required this.themeIcon,
  });

  /// 1. Sage Organic (Classic serene earthy aesthetic)
  static const CounterThemeConfig sageOrganic = CounterThemeConfig(
    id: CounterThemeId.sageOrganic,
    name: 'Sage Classic',
    tagLine: 'Gentle, mindful reading pace',
    cardBackground: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF1A1A1A),
    secondaryTextColor: Color(0xFF6B6B6B),
    accentColor: Color(0xFF557A68),
    isDark: false,
    glowColors: [Color(0xFFE2EBE5), Color(0xFFE8EEEA)],
    tickColor: Color(0xFFD3DDD6),
    activeTickColor: Color(0xFF557A68),
    needleColor: Color(0xFF2D4A3E),
    ringTrackColor: Color(0xFFE2E9E4),
    ringProgressColor: Color(0xFF557A68),
    themeIcon: Icons.spa_outlined,
  );

  /// 2. Obsidian Ember (Directly inspired by the glowing dark gauge from the user image)
  static const CounterThemeConfig obsidianEmber = CounterThemeConfig(
    id: CounterThemeId.obsidianEmber,
    name: 'Obsidian Ember',
    tagLine: 'Molten amber glow on deep glass',
    cardBackground: Color(0xFF101214),
    primaryTextColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF9E9E9E),
    accentColor: Color(0xFFFF7A00),
    isDark: true,
    glowColors: [
      Color(0x00FF4500),
      Color(0x33FF4500),
      Color(0x88FF6600),
      Color(0xD9FF8500),
      Color(0xFFFFB020),
    ],
    tickColor: Color(0x38FFFFFF),
    activeTickColor: Color(0xFFFF9500),
    needleColor: Color(0xFFFFFFFF),
    ringTrackColor: Color(0x22FFFFFF),
    ringProgressColor: Color(0xFFFF8500),
    themeIcon: Icons.local_fire_department_rounded,
  );

  /// 3. Ceramic Frost (Directly inspired by the pure minimalist white gauge from the user image)
  static const CounterThemeConfig ceramicFrost = CounterThemeConfig(
    id: CounterThemeId.ceramicFrost,
    name: 'Ceramic Frost',
    tagLine: 'Sculpted pearl glass & precision ticks',
    cardBackground: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF14171A),
    secondaryTextColor: Color(0xFF757E88),
    accentColor: Color(0xFF263238),
    isDark: false,
    glowColors: [
      Color(0x00E0E6ED),
      Color(0x22CBD5E1),
      Color(0x55E2E8F0),
    ],
    tickColor: Color(0xFFCBD5E1),
    activeTickColor: Color(0xFF1E293B),
    needleColor: Color(0xFF0F172A),
    ringTrackColor: Color(0xFFE2E8F0),
    ringProgressColor: Color(0xFF1E293B),
    themeIcon: Icons.wb_sunny_outlined,
  );

  /// 4. Midnight Aurora (Luminous cosmic night reading mode)
  static const CounterThemeConfig midnightAurora = CounterThemeConfig(
    id: CounterThemeId.midnightAurora,
    name: 'Midnight Aurora',
    tagLine: 'Cool cosmic emerald for nighttime reads',
    cardBackground: Color(0xFF0C101B),
    primaryTextColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF8B9CB2),
    accentColor: Color(0xFF00E5FF),
    isDark: true,
    glowColors: [
      Color(0x0000E5FF),
      Color(0x3300C9FF),
      Color(0x7700E5FF),
      Color(0xCC00F5A0),
    ],
    tickColor: Color(0x3300E5FF),
    activeTickColor: Color(0xFF00F5A0),
    needleColor: Color(0xFFE0F7FA),
    ringTrackColor: Color(0x2200E5FF),
    ringProgressColor: Color(0xFF00E5FF),
    themeIcon: Icons.dark_mode_outlined,
  );

  /// 5. Warm Papyrus (Rich antiquarian book lover aesthetic)
  static const CounterThemeConfig solarSandstone = CounterThemeConfig(
    id: CounterThemeId.solarSandstone,
    name: 'Warm Papyrus',
    tagLine: 'Sepia bookshop & golden hour warmth',
    cardBackground: Color(0xFFF6F0E6),
    primaryTextColor: Color(0xFF2C221E),
    secondaryTextColor: Color(0xFF7D6B63),
    accentColor: Color(0xFFB85D36),
    isDark: false,
    glowColors: [
      Color(0x00C86D44),
      Color(0x22D47E53),
      Color(0x66E49063),
    ],
    tickColor: Color(0xFFDBCBB8),
    activeTickColor: Color(0xFFB85D36),
    needleColor: Color(0xFF4A352B),
    ringTrackColor: Color(0xFFE3D6C5),
    ringProgressColor: Color(0xFFB85D36),
    themeIcon: Icons.auto_stories_outlined,
  );

  static const List<CounterThemeConfig> allThemes = [
    sageOrganic,
    obsidianEmber,
    ceramicFrost,
    midnightAurora,
    solarSandstone,
  ];

  static CounterThemeConfig byId(CounterThemeId id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => sageOrganic,
    );
  }
}

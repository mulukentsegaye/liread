import 'package:flutter/material.dart';

/// Available themes for the Reading Timer counter.
enum CounterThemeId {
  // Light mode themes
  sageOrganic,
  ceramicFrost,
  solarSandstone,
  linenMinimal,

  // Dark mode themes
  obsidianEmber,
  midnightAurora,
  obsidianSage,
  charcoalMinimal,
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

  // ══════════════════════════════════════════════════════════
  // LIGHT COUNTER THEMES (For App Light Mode)
  // ══════════════════════════════════════════════════════════

  /// 1. Sage Organic (Classic serene earthy circular counter)
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

  /// 2. Ceramic Frost (Light mode arched gauge from the user image)
  static const CounterThemeConfig ceramicFrost = CounterThemeConfig(
    id: CounterThemeId.ceramicFrost,
    name: 'Ceramic Frost',
    tagLine: 'Sculpted pearl glass & precision graduated ticks',
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

  /// 3. Warm Papyrus (Golden hour sepia bookshop warmth)
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

  /// 4. Linen Minimal (Clean porcelain with sage-slate ticks)
  static const CounterThemeConfig linenMinimal = CounterThemeConfig(
    id: CounterThemeId.linenMinimal,
    name: 'Linen Minimal',
    tagLine: 'Pure airy white with subtle sage-slate accents',
    cardBackground: Color(0xFFFAFAF9),
    primaryTextColor: Color(0xFF1C1917),
    secondaryTextColor: Color(0xFF78716C),
    accentColor: Color(0xFF4D7C5D),
    isDark: false,
    glowColors: [
      Color(0x00E7E5E4),
      Color(0x22D6D3D1),
      Color(0x44E7E5E4),
    ],
    tickColor: Color(0xFFE7E5E4),
    activeTickColor: Color(0xFF4D7C5D),
    needleColor: Color(0xFF292524),
    ringTrackColor: Color(0xFFE7E5E4),
    ringProgressColor: Color(0xFF4D7C5D),
    themeIcon: Icons.layers_outlined,
  );

  // ══════════════════════════════════════════════════════════
  // DARK COUNTER THEMES (For App Dark Mode)
  // ══════════════════════════════════════════════════════════

  /// 5. Obsidian Ember (Dark mode glowing amber gauge from the user image)
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

  /// 6. Midnight Aurora (Cool cosmic emerald night reading mode)
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

  /// 7. Obsidian Sage (Dark glass with glowing sage green horizon)
  static const CounterThemeConfig obsidianSage = CounterThemeConfig(
    id: CounterThemeId.obsidianSage,
    name: 'Obsidian Sage',
    tagLine: 'Luminous sage glow on dark obsidian glass',
    cardBackground: Color(0xFF111417),
    primaryTextColor: Color(0xFFF2F5F3),
    secondaryTextColor: Color(0xFFA2B0A7),
    accentColor: Color(0xFF65927D),
    isDark: true,
    glowColors: [
      Color(0x0065927D),
      Color(0x3365927D),
      Color(0x7765927D),
      Color(0xCC84B39C),
    ],
    tickColor: Color(0x33FFFFFF),
    activeTickColor: Color(0xFF7CB297),
    needleColor: Color(0xFFE8F0EB),
    ringTrackColor: Color(0x22FFFFFF),
    ringProgressColor: Color(0xFF65927D),
    themeIcon: Icons.eco_outlined,
  );

  /// 8. Charcoal Minimal (Matte black titanium with crisp silver ticks)
  static const CounterThemeConfig charcoalMinimal = CounterThemeConfig(
    id: CounterThemeId.charcoalMinimal,
    name: 'Charcoal Minimal',
    tagLine: 'Stealth matte black with surgical silver ticks',
    cardBackground: Color(0xFF14171A),
    primaryTextColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF88929A),
    accentColor: Color(0xFFD1D5DB),
    isDark: true,
    glowColors: [
      Color(0x00374151),
      Color(0x224B5563),
      Color(0x556B7280),
    ],
    tickColor: Color(0x2EFFFFFF),
    activeTickColor: Color(0xFFFFFFFF),
    needleColor: Color(0xFFFFFFFF),
    ringTrackColor: Color(0x22FFFFFF),
    ringProgressColor: Color(0xFFE5E7EB),
    themeIcon: Icons.hdr_strong_outlined,
  );

  static const List<CounterThemeConfig> lightThemes = [
    sageOrganic,
    ceramicFrost,
    solarSandstone,
    linenMinimal,
  ];

  static const List<CounterThemeConfig> darkThemes = [
    obsidianEmber,
    midnightAurora,
    obsidianSage,
    charcoalMinimal,
  ];

  static const List<CounterThemeConfig> allThemes = [
    sageOrganic,
    ceramicFrost,
    solarSandstone,
    linenMinimal,
    obsidianEmber,
    midnightAurora,
    obsidianSage,
    charcoalMinimal,
  ];

  /// Returns counter themes suited for the given app mode [isDark].
  static List<CounterThemeConfig> getThemesForMode(bool isDark) {
    return isDark ? darkThemes : lightThemes;
  }

  /// Default counter theme for the given app mode [isDark].
  static CounterThemeConfig defaultForMode(bool isDark) {
    return isDark ? obsidianEmber : sageOrganic;
  }

  static CounterThemeConfig byId(CounterThemeId id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => sageOrganic,
    );
  }
}

import 'package:flutter/material.dart';

/// Readers Hub color palette — sage-green organic tones
/// supporting both Light Mode and Dark Mode.
class AppColors {
  AppColors._();

  // ── Light Theme Primary ──────────────────────────────────
  static const Color primary = Color(0xFF2D4A3E);
  static const Color primaryLight = Color(0xFF3E6355);
  static const Color primarySurface = Color(0xFFE8EEEA);

  // ── Light Theme Backgrounds ──────────────────────────────
  static const Color background = Color(0xFFF8F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bookCardBackground = Color(0xFFF0ECE5);
  static const Color quoteCardBackground = Color(0xFFE9EFEB);
  static const Color bookCoverBackground = Color(0xFFE4DFD6);

  // ── Light Theme Text ─────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Light Theme UI Elements ──────────────────────────────
  static const Color divider = Color(0xFFEAEAEA);
  static const Color iconDefault = Color(0xFF8E8E93);
  static const Color iconActive = Color(0xFF2D4A3E);
  static const Color starActive = Color(0xFF2D4A3E);
  static const Color tabInactive = Color(0xFFAEAEB2);

  // ── Dark Theme Colors ────────────────────────────────────
  static const Color darkBackground = Color(0xFF101316);
  static const Color darkSurface = Color(0xFF181C20);
  static const Color darkBookCardBackground = Color(0xFF20262B);
  static const Color darkQuoteCardBackground = Color(0xFF16241D);
  static const Color darkBookCoverBackground = Color(0xFF252B31);

  static const Color darkTextPrimary = Color(0xFFF2F4F6);
  static const Color darkTextSecondary = Color(0xFFA2ABB4);
  static const Color darkTextTertiary = Color(0xFF68737E);
  static const Color darkTextOnPrimary = Color(0xFFFFFFFF);

  static const Color darkPrimary = Color(0xFF608F79);
  static const Color darkPrimaryLight = Color(0xFF76A58F);
  static const Color darkPrimarySurface = Color(0xFF1B2B23);

  static const Color darkDivider = Color(0xFF262C32);
  static const Color darkIconDefault = Color(0xFF727E8A);
  static const Color darkIconActive = Color(0xFF608F79);
  static const Color darkStarActive = Color(0xFF608F79);
  static const Color darkTabInactive = Color(0xFF68737E);

  /// Helper to resolve color dynamically based on dark/light context.
  static Color resolve(BuildContext context, {required Color light, required Color dark}) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

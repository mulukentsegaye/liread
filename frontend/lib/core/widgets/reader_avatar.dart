import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Universal avatar widget for Liread readers.
/// Supports:
/// 1. Remote HTTP/HTTPS image URLs (Supabase storage, Gravatar, Google OAuth)
/// 2. Base64 Data URLs ('data:image/jpeg;base64,...' or 'data:image/png;base64,...') uploaded on Web or Mobile
/// 3. SVG initial data URLs ('data:image/svg+xml,...')
/// 4. Monogram initials fallback on tranquil sage background
class ReaderAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? initials;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Border? border;

  const ReaderAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
    this.border,
  });

  String get _effectiveInitials {
    if (initials != null && initials!.trim().isNotEmpty) {
      return initials!.trim();
    }
    final clean = name.trim();
    if (clean.isEmpty) return 'R';
    final parts = clean.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallback = _buildFallback(context, size);

    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return fallback;
    }

    final raw = avatarUrl!.trim();

    // 1. Check for Base64 Data URL: data:image/png;base64,... or data:image/jpeg;base64,...
    if (raw.startsWith('data:image/') && raw.contains(';base64,')) {
      try {
        final commaIdx = raw.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = raw.substring(commaIdx + 1);
          final bytes = base64Decode(base64Data);
          return _wrapWithBorder(
            ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
          );
        }
      } catch (_) {
        return fallback;
      }
    }

    // 2. Check for SVG initial data URL from web (monogram fallback)
    if (raw.startsWith('data:image/svg+xml')) {
      return fallback;
    }

    // 3. Check for standard HTTP or HTTPS URLs
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _wrapWithBorder(
        ClipOval(
          child: Image.network(
            raw,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      );
    }

    // Default to initials
    return fallback;
  }

  Widget _wrapWithBorder(Widget child) {
    if (border == null) return child;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: child,
    );
  }

  Widget _buildFallback(BuildContext context, double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primarySurface);

    return _wrapWithBorder(
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _effectiveInitials,
          style: textStyle ??
              GoogleFonts.plusJakartaSans(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
        ),
      ),
    );
  }
}

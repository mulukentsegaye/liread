import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/error_handler.dart';

enum AlertType {
  error,
  warning,
  info,
  success,
}

/// Standardized, elegant alert banner for LiRead forms, dialogs, and sheets.
class AppAlertBanner extends StatelessWidget {
  final String message;
  final String? title;
  final AlertType type;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;

  const AppAlertBanner({
    super.key,
    required this.message,
    this.title,
    this.type = AlertType.error,
    this.onDismiss,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color primaryColor;
    Color bgColor;
    Color borderColor;
    IconData icon;

    switch (type) {
      case AlertType.error:
        primaryColor = const Color(0xFFDC2626); // Crimson red
        bgColor = isDark ? const Color(0xFF2C1515) : const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFF87171).withValues(alpha: isDark ? 0.35 : 0.45);
        icon = Icons.error_outline_rounded;
        break;
      case AlertType.warning:
        primaryColor = const Color(0xFFD97706); // Amber
        bgColor = isDark ? const Color(0xFF2B1F0D) : const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.35 : 0.45);
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.info:
        primaryColor = AppColors.primary;
        bgColor = isDark ? AppColors.darkPrimarySurface : const Color(0xFFF0FDF4);
        borderColor = AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.35);
        icon = Icons.info_outline_rounded;
        break;
      case AlertType.success:
        primaryColor = const Color(0xFF10B981); // Emerald
        bgColor = isDark ? const Color(0xFF0D251A) : const Color(0xFFECFDF5);
        borderColor = const Color(0xFF34D399).withValues(alpha: isDark ? 0.35 : 0.45);
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standardized SnackBar alerts and toast notifications for LiRead.
class AppAlert {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AlertType type = AlertType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case AlertType.error:
        bgColor = const Color(0xFF991B1B); // Rich deep crimson
        iconColor = const Color(0xFFFCA5A5);
        icon = Icons.error_outline_rounded;
        break;
      case AlertType.warning:
        bgColor = const Color(0xFF92400E); // Deep amber
        iconColor = const Color(0xFFFDE68A);
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.info:
        bgColor = const Color(0xFF1E293B); // Deep slate
        iconColor = const Color(0xFF93C5FD);
        icon = Icons.info_outline_rounded;
        break;
      case AlertType.success:
        bgColor = const Color(0xFF065F46); // Forest emerald
        iconColor = const Color(0xFFA7F3D0);
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: duration,
        action: action,
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showError(
    BuildContext context,
    dynamic error, {
    String? defaultMessage,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final formatted = AppErrorHandler.format(error, defaultMessage: defaultMessage);
    show(
      context,
      message: formatted,
      type: AlertType.error,
      duration: duration,
      action: action,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      type: AlertType.success,
      duration: duration,
      action: action,
    );
  }
}

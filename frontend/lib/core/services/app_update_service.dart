import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'supabase_service.dart';

/// Information about a remote application update available on Telegram.
class AppUpdateInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForced;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isForced = false,
  });
}

/// Service that checks Supabase when online to determine if a new APK version exists,
/// and alerts the user with direct redirection to Telegram to download the new build.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String currentAppVersion = '1.2.3';
  static const String defaultTelegramUrl = 'https://t.me/lireadbooksbot';
  static const String _dismissedKey = 'liread_update_dismissed_time';

  /// Compare semantic version numbers (e.g. 1.2.4 > 1.2.3)
  bool isNewerVersion(String current, String remote) {
    try {
      final curClean = current.split('+')[0].trim();
      final remClean = remote.split('+')[0].trim();

      final curParts = curClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final remParts = remClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (curParts.length < 3) {
        curParts.add(0);
      }
      while (remParts.length < 3) {
        remParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (remParts[i] > curParts[i]) return true;
        if (remParts[i] < curParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check whether installed version is lower than minimum mandatory version
  bool isVersionBelowMinimum(String current, String minimum) {
    return isNewerVersion(current, minimum);
  }

  /// Query Supabase for latest release metadata. Fails silently if offline or table not present.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final client = SupabaseService.instance.client;
    if (client == null) return null;

    try {
      final res = await client
          .from('app_versions')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;

      final latestVer = (res['latest_version'] as String?)?.trim() ?? currentAppVersion;
      final minVer = (res['min_supported_version'] as String?)?.trim() ?? '1.0.0';
      final dlUrl = (res['download_url'] as String?)?.trim() ?? defaultTelegramUrl;
      final notes = (res['release_notes'] as String?)?.trim() ??
          'A new version of Liread is available with stability improvements and new features.';

      final isNewer = isNewerVersion(currentAppVersion, latestVer);
      if (!isNewer) return null;

      final isForced = isVersionBelowMinimum(currentAppVersion, minVer);

      return AppUpdateInfo(
        latestVersion: latestVer,
        minSupportedVersion: minVer,
        downloadUrl: dlUrl,
        releaseNotes: notes,
        isForced: isForced,
      );
    } catch (e) {
      debugPrint('App update check notice (safe bypass): $e');
      return null;
    }
  }

  /// Open Telegram deep link directly or fallback to web URL
  Future<bool> openDownloadUrl(String url) async {
    final cleanUrl = url.trim().isEmpty ? defaultTelegramUrl : url.trim();

    if (cleanUrl.contains('t.me/') || cleanUrl.startsWith('@')) {
      final domain = cleanUrl
          .replaceAll('https://t.me/', '')
          .replaceAll('http://t.me/', '')
          .replaceAll('t.me/', '')
          .replaceAll('@', '')
          .split('/')[0]
          .split('?')[0];

      if (domain.isNotEmpty) {
        final tgNativeUri = Uri.parse('tg://resolve?domain=$domain');
        try {
          if (await canLaunchUrl(tgNativeUri)) {
            return await launchUrl(tgNativeUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }
    }

    final webUri = Uri.parse(cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl');
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open update download URL: $e');
      return false;
    }
  }

  /// Check online for an update and present the update prompt if available
  Future<void> checkAndPromptUpdate(BuildContext context, {bool manual = false}) async {
    final updateInfo = await checkForUpdate();

    if (!context.mounted) return;

    if (updateInfo == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are using the latest version of Liread (v$currentAppVersion).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Check if dismissed recently (within 24 hours) for optional updates
    if (!manual && !updateInfo.isForced) {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissed = prefs.getInt(_dismissedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cooldown = 24 * 60 * 60 * 1000; // 24 hours
      if (now - lastDismissed < cooldown) {
        return;
      }
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (dlgContext) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }

  /// Record dismissal timestamp to snooze notifications for 24h
  Future<void> snoozeUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dismissedKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

/// Alert dialog presenting the new version and Telegram download action.
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.resolve(
      context,
      light: AppColors.surface,
      dark: AppColors.darkSurface,
    );
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !updateInfo.isForced,
      child: Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Version Badge Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_download_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Available',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${updateInfo.latestVersion}',
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              updateInfo.isForced ? '• Required' : '• Recommended',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: updateInfo.isForced
                                    ? Colors.orange.shade700
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Release notes / What's new container
              Text(
                'WHAT\'S NEW',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.resolve(
                    context,
                    light: const Color(0xFFF6F8F6),
                    dark: const Color(0xFF1B231F),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (!updateInfo.isForced) ...[
                    Expanded(
                      flex: 4,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          AppUpdateService.instance.snoozeUpdate();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Later',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 6,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        AppUpdateService.instance.openDownloadUrl(updateInfo.downloadUrl);
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Get on Telegram',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'open_library_service.dart';

class TelegramBotService {
  TelegramBotService._();
  static final TelegramBotService instance = TelegramBotService._();

  static const String _prefKey = 'liread_telegram_bot_name';
  static const String defaultBotName = 'lireadbooksbot';

  /// Get currently configured bot username (without @).
  Future<String> getBotUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final clean = saved.trim().replaceAll('@', '');
        // Migrate legacy bot names to the official lireadbooksbot
        if (clean.toLowerCase() == 'booksfinderbot') {
          await prefs.setString(_prefKey, defaultBotName);
          return defaultBotName;
        }
        return clean;
      }
    } catch (_) {}
    return defaultBotName;
  }

  /// Save custom bot username.
  Future<void> setBotUsername(String botName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, botName.trim().replaceAll('@', ''));
    } catch (_) {}
  }

  /// Open Telegram Bot and send book search/command.
  Future<bool> launchBotWithBook(OpenLibraryBook book) async {
    final bot = await getBotUsername();
    final cleanKey = (book.workKey ?? book.id).replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final startParam = 'book_${cleanKey.length > 55 ? cleanKey.substring(0, 55) : cleanKey}';

    // 1. Try native Telegram deep link
    final nativeUri = Uri.parse('tg://resolve?domain=$bot&start=$startParam');
    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Telegram native launch error: $e');
    }

    // 2. Fallback to Telegram Web / Universal Link
    final webUri = Uri.parse('https://t.me/$bot?start=$startParam');
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Telegram web launch error: $e');
      return false;
    }
  }

  /// Share book card directly to Telegram chat, bot, or saved messages.
  Future<bool> shareBookToTelegram(OpenLibraryBook book) async {
    final workUrl = book.workKey != null ? 'https://openlibrary.org${book.workKey}' : '';
    final message = '📚 Looking for book:\n"${book.title}" by ${book.author}\n\nPlease send this book file if available.';

    final shareUri = Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent(workUrl)}&text=${Uri.encodeComponent(message)}',
    );

    try {
      return await launchUrl(shareUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Telegram share error: $e');
      return false;
    }
  }
}

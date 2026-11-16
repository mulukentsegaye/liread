import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Formatter that turns technical runtime exceptions, network failures,
/// and database errors into human-friendly, standard guidance.
class AppErrorHandler {
  /// Translates technical exceptions or raw error strings into clean, user-friendly text.
  static String format(dynamic error, {String? defaultMessage}) {
    if (error == null) {
      return defaultMessage ?? 'Something went wrong. Please check your information and try again.';
    }

    // 1. Supabase AuthException
    if (error is AuthException) {
      return _mapAuthMessage(error.message, defaultMessage);
    }

    // 2. Supabase PostgrestException
    if (error is PostgrestException) {
      return _mapPostgrestMessage(error.message, error.details, defaultMessage);
    }

    // 3. Network / Socket / HTTP Errors
    if (error is SocketException ||
        error is HttpException ||
        error.runtimeType.toString().contains('SocketException') ||
        error.runtimeType.toString().contains('ClientException') ||
        error.runtimeType.toString().contains('TimeoutException')) {
      return 'Unable to reach the server. Please check your internet connection and try again.';
    }

    // 4. String error analysis
    final raw = error.toString().trim();
    return _mapStringError(raw, defaultMessage);
  }

  static String _mapAuthMessage(String msg, String? fallback) {
    final lower = msg.toLowerCase().trim();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email or password')) {
      return 'Incorrect email address or password. Please verify your details and try again.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for the confirmation link.';
    }

    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'An account with this email address already exists. Please sign in instead.';
    }

    if (lower.contains('password should be at least') ||
        lower.contains('password must be at least') ||
        lower.contains('weak password')) {
      return 'Password must be at least 6 characters long.';
    }

    if (lower.contains('unable to validate email') ||
        lower.contains('invalid format') ||
        lower.contains('invalid email')) {
      return 'Please enter a valid email address (e.g. reader@example.com).';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit')) {
      return 'Too many attempts in a short time. Please wait a minute and try again.';
    }

    if (lower.contains('user not found')) {
      return 'No account was found with this email. Please check your email or create an account.';
    }

    if (lower.contains('signup is disabled') || lower.contains('signups not allowed')) {
      return 'New account registrations are temporarily paused. Please check back later.';
    }

    if (lower.contains('token has expired') || lower.contains('token expired')) {
      return 'This verification link has expired. Please request a new one.';
    }

    if (lower.contains('database error') || lower.contains('internal server error')) {
      return 'Our servers are experiencing a brief interruption. Please try again shortly.';
    }

    // If message is a clean, readable English sentence without code structures
    if (!msg.contains('{') &&
        !msg.contains(':') &&
        !msg.contains('Exception') &&
        !msg.contains('error_') &&
        msg.length < 120) {
      return msg;
    }

    return fallback ?? 'Unable to sign in. Please verify your details and try again.';
  }

  static String _mapPostgrestMessage(String msg, dynamic details, String? fallback) {
    final combined = '$msg ${details ?? ''}'.toLowerCase();

    if (combined.contains('duplicate key') || combined.contains('unique constraint')) {
      if (combined.contains('username') || combined.contains('profiles_username')) {
        return 'This username is already taken. Please choose another one.';
      }
      if (combined.contains('email')) {
        return 'An account with this email address already exists.';
      }
      return 'This entry already exists. Please choose a different value.';
    }

    return fallback ?? 'Unable to complete your request. Please try again in a few moments.';
  }

  static String _mapStringError(String raw, String? fallback) {
    final lower = raw.toLowerCase();

    // Check if it's an AuthException format: AuthException(message: ..., statusCode: ...)
    final authMatch = RegExp(r'message:\s*([^,)]+)', caseSensitive: false).firstMatch(raw);
    if (authMatch != null) {
      final extracted = authMatch.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        return _mapAuthMessage(extracted, fallback);
      }
    }

    // Check for common network phrases
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('handshakeexception')) {
      return 'Unable to reach the server. Please check your internet connection and try again.';
    }

    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'The connection timed out. Please check your internet connection and try again.';
    }

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Incorrect email address or password. Please verify your details and try again.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for the confirmation link.';
    }

    if (lower.contains('user already registered') || lower.contains('user already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (lower.contains('unable to validate email') || lower.contains('invalid email')) {
      return 'Please enter a valid email address (e.g. reader@example.com).';
    }

    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a minute before trying again.';
    }

    // Strip technical class prefixes
    String cleaned = raw
        .replaceAll(RegExp(r'^(Exception|AuthException|PostgrestException|ClientException):\s*', caseSensitive: false), '')
        .trim();

    // If cleaned string still looks like a technical error trace, use fallback
    if (cleaned.contains('statusCode:') ||
        cleaned.contains('error_description') ||
        cleaned.contains('Trace:') ||
        cleaned.contains('{') ||
        cleaned.startsWith('AuthException') ||
        cleaned.length > 150) {
      return fallback ?? 'Something went wrong. Please check your details and try again.';
    }

    if (cleaned.isNotEmpty) {
      return cleaned;
    }

    return fallback ?? 'Something went wrong. Please check your details and try again.';
  }

  /// Helper to validate email format before submitting
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(trimmed);
  }
}

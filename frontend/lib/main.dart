import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/co_reading_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fast offline cache pre-warm so profile, stats, and session are instantly available
  try {
    await SupabaseService.instance.preWarmOfflineStorage();
  } catch (e) {
    debugPrint('Offline cache pre-warm notice: $e');
  }

  // Light status bar icons on light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Render UI immediately so offline APK opens in <100ms
  runApp(const LireadApp());

  // Non-blocking background sync with Supabase and live co-reading presence
  unawaited(
    SupabaseService.instance.initialize().then((_) {
      CoReadingService.instance.initChannel();
    }).catchError((e) {
      debugPrint('Background Supabase init notice: $e');
    }),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/co_reading_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend service and live co-reading presence channel
  try {
    await SupabaseService.instance.initialize();
    CoReadingService.instance.initChannel();
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  // Light status bar icons on light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const LireadApp());
}

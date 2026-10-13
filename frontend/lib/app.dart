import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/main_navigation_shell.dart';

class ReadersHubApp extends StatelessWidget {
  const ReadersHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Readers Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppThemeController.instance.themeMode,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

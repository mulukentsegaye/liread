import 'package:flutter/material.dart';

import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/main_navigation_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class LireadApp extends StatelessWidget {
  final Widget? homeOverride;

  const LireadApp({super.key, this.homeOverride});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Liread',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppThemeController.instance.themeMode,
          home: homeOverride ?? const _RootAuthGate(),
        );
      },
    );
  }
}

class _RootAuthGate extends StatefulWidget {
  const _RootAuthGate();

  @override
  State<_RootAuthGate> createState() => _RootAuthGateState();
}

class _RootAuthGateState extends State<_RootAuthGate> {
  bool _checking = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasActive = await SupabaseService.instance.hasActiveSession();
    if (mounted) {
      setState(() {
        _hasSession = hasActive;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasSession) {
      return const MainNavigationShell();
    }

    return const OnboardingScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../navigation/presentation/main_navigation_shell.dart';

/// Onboarding and Welcome screen for Liread.
/// Introduces the platform's core pillars and provides Sign Up, Sign In, and Guest access.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      icon: Icons.auto_stories_rounded,
      tagline: 'DAILY RITUALS',
      title: 'A Mindful Sanctuary\nfor Readers',
      description:
          'Cultivate intentional reading habits, track active minutes, and focus deeply with calming ambient soundscapes.',
    ),
    _OnboardingSlide(
      icon: Icons.local_library_rounded,
      tagline: 'TIMELESS LITERATURE',
      title: 'Timeless Classics\nat Your Fingertips',
      description:
          'Access verified public domain masterpieces, organize your reading shelves, and discover resonant books.',
    ),
    _OnboardingSlide(
      icon: Icons.format_quote_rounded,
      tagline: 'READING CIRCLE',
      title: 'Between Pages,\nInspired Together',
      description:
          'Share meaningful passages, celebrate daily streaks, and connect with a community that values deep reading.',
    ),
  ];

  void _onEnterApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  void _showAuthSheet({required bool isSignUp}) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool modeSignUp = isSignUp;
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final surfaceColor = AppColors.resolve(
              ctx,
              light: AppColors.surface,
              dark: AppColors.darkSurface,
            );

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Text(
                      modeSignUp ? 'Join LiRead' : 'Welcome Back',
                      style: GoogleFonts.newsreader(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeSignUp
                          ? 'Create your account to sync habits and join the community.'
                          : 'Sign in to access your bookshelf, streaks, and saved quotes.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    if (modeSignUp) ...[
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Jane Austen',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'e.g. jane_reads',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'reader@example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final email = emailCtrl.text.trim();
                                final password = passCtrl.text;
                                if (email.isEmpty || password.isEmpty) {
                                  setSheetState(() {
                                    errorMessage = 'Please provide both email and password.';
                                  });
                                  return;
                                }

                                setSheetState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                });

                                try {
                                  if (modeSignUp) {
                                    final username = userCtrl.text.trim();
                                    final fullName = nameCtrl.text.trim();
                                    if (username.isEmpty) {
                                      setSheetState(() {
                                        errorMessage = 'Please choose a username.';
                                        isLoading = false;
                                      });
                                      return;
                                    }

                                    final res = await SupabaseService.instance.signUp(
                                      email,
                                      password,
                                      username,
                                      fullName.isNotEmpty ? fullName : username,
                                    );
                                    if (res == null && !SupabaseService.instance.isInitialized) {
                                      // Local guest setup fallback
                                      await SupabaseService.instance.setGuestMode(
                                        name: fullName.isNotEmpty ? fullName : username,
                                        handle: username,
                                      );
                                    }
                                  } else {
                                    final res = await SupabaseService.instance.signIn(email, password);
                                    if (res == null && !SupabaseService.instance.isInitialized) {
                                      setSheetState(() {
                                        errorMessage = 'Cannot reach backend. Exploring as guest.';
                                      });
                                      await SupabaseService.instance.setGuestMode();
                                    }
                                  }

                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  _onEnterApp();
                                } catch (e) {
                                  setSheetState(() {
                                    isLoading = false;
                                    errorMessage = e.toString().replaceFirst('Exception: ', '');
                                  });
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                modeSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          setSheetState(() {
                            modeSignUp = !modeSignUp;
                            errorMessage = null;
                          });
                        },
                        child: Text(
                          modeSignUp
                              ? 'Already have an account? Sign In'
                              : 'New to LiRead? Create an account',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.resolve(
      context,
      light: AppColors.background,
      dark: AppColors.darkBackground,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Brand Bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Liread',
                        style: GoogleFonts.newsreader(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      await SupabaseService.instance.setGuestMode();
                      _onEnterApp();
                    },
                    child: Text(
                      'Explore as Guest',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides Carousel ──────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.tagline,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.newsreader(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Page Dots ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 36),

            // ── Call to Actions ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showAuthSheet(isSignUp: true),
                      child: const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showAuthSheet(isSignUp: false),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String tagline;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.tagline,
    required this.title,
    required this.description,
  });
}

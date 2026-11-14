import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';
import 'package:readers_hub/core/theme/theme_controller.dart';
import 'package:readers_hub/features/auth/presentation/sign_in_screen.dart';
import 'package:readers_hub/features/auth/presentation/sign_up_screen.dart';
import 'package:readers_hub/features/leaderboard/data/reading_session_store.dart';
import 'package:readers_hub/features/navigation/presentation/main_navigation_shell.dart';
import 'package:readers_hub/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('Dedicated Sign In and Sign Up screens render properly and support transitions', (WidgetTester tester) async {
    // 1. Render Onboarding Screen
    await tester.pumpWidget(const LireadApp(homeOverride: OnboardingScreen()));
    await tester.pump();

    // Verify Brand title & Onboarding CTAs
    expect(find.text('Liread'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Explore as Guest'), findsOneWidget);

    // Tap "Sign In" to push dedicated SignInScreen
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your sanctuary to access your bookshelf, streaks, and saved passages.'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Scroll to and tap "Create an account" link at bottom of SignInScreen
    final createAccountLink = find.text('Create an account');
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Create an Account'), findsWidgets);
    expect(find.text('Join the sanctuary to cultivate daily reading habits and share resonant passages.'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Scroll to and tap "Sign In" link at bottom of SignUpScreen
    final signInLink = find.text('Sign In');
    await tester.ensureVisible(signInLink);
    await tester.tap(signInLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('App renders 4 streamlined tabs: Feed, Explore, Read, and Profile with Journey', (WidgetTester tester) async {
    ReadingSessionStore.instance.reset();
    AppThemeController.instance.resetForTesting();
    await tester.pumpWidget(const LireadApp(homeOverride: MainNavigationShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify Feed header & 4 bottom navigation items
    expect(find.text('Between pages'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify Feed sub-tabs (Community Feed & Reading Circle)
    expect(find.text('Community Feed'), findsOneWidget);
    expect(find.text('Reading Circle'), findsOneWidget);

    // Switch to 'Reading Circle' sub-tab inside Feed
    await tester.tap(find.text('Reading Circle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reading circle'), findsOneWidget);
    expect(find.text('Daily rank'), findsOneWidget);
    expect(find.text('Weekly rank'), findsOneWidget);
    expect(find.text('Yearly rank'), findsOneWidget);

    // 2. Tap on the 'Explore' tab
    await tester.tap(find.text('Explore'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Search Open Library & curated bookshelves'), findsOneWidget);
    expect(find.text('Open Library'), findsOneWidget);
    expect(find.text('Search title, author, or subject...'), findsOneWidget);
    expect(find.text('BOOK OF THE WEEK'), findsOneWidget);

    // 3. Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsNWidgets(2));
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text('Finish & save'), findsOneWidget);
    expect(find.text('A little every day'), findsOneWidget);

    // Verify Counter Theme pill and test switching light themes
    expect(find.text('Theme: Sage Classic'), findsOneWidget);

    await tester.tap(find.text('Theme: Sage Classic'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Counter Theme'), findsOneWidget);
    expect(find.text('Ceramic Frost'), findsOneWidget);

    await tester.tap(find.text('Ceramic Frost'));
    await tester.pumpAndSettle();
    expect(find.text('Theme: Ceramic Frost'), findsOneWidget);

    // 4. Tap on the 'Profile' tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Your corner'), findsOneWidget);
    expect(find.text('The reader behind the pages.'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Bookshelf'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Saved notes'), findsOneWidget);

    // Tap on the 'Journey' sub-tab within Profile
    await tester.tap(find.text('Journey'));
    await tester.pumpAndSettle();

    expect(find.text('Your journey'), findsOneWidget);
    expect(find.text('Small moments. Meaningful progress.'), findsOneWidget);
    expect(find.text('Books finished'), findsOneWidget);
    expect(find.text('Time well spent'), findsOneWidget);
    expect(find.text('A steady rhythm'), findsOneWidget);
    expect(find.text('7-day reading streak'), findsOneWidget);
    expect(find.text('Thoughtful reader'), findsOneWidget);
  });
}

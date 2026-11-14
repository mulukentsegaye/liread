import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';
import 'package:readers_hub/core/theme/theme_controller.dart';
import 'package:readers_hub/features/explore/data/open_library_service.dart';
import 'package:readers_hub/features/explore/presentation/widgets/book_details_sheet.dart';
import 'package:readers_hub/features/leaderboard/data/reading_session_store.dart';
import 'package:readers_hub/features/navigation/presentation/main_navigation_shell.dart';
import 'package:readers_hub/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders welcome slides and authentication options', (WidgetTester tester) async {
    await tester.pumpWidget(const LireadApp(homeOverride: OnboardingScreen()));

    // Verify Brand title
    expect(find.text('Liread'), findsOneWidget);

    // Verify Onboarding slide 1 content
    expect(find.text('DAILY RITUALS'), findsOneWidget);
    expect(find.text('A Mindful Sanctuary\nfor Readers'), findsOneWidget);

    // Verify CTAs
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Explore as Guest'), findsOneWidget);

    // Tap "Sign In" to open auth modal
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('App renders Feed, Explore, Read timer with theme switching, Journey, Ranks, and Profile tabs', (WidgetTester tester) async {
    ReadingSessionStore.instance.reset();
    AppThemeController.instance.resetForTesting();
    await tester.pumpWidget(const LireadApp(homeOverride: MainNavigationShell()));

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // 1. Verify the Feed header renders
    expect(find.text('Between pages'), findsOneWidget);

    // Verify all 6 bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Ranks'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 2. Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await settle();

    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsNWidgets(2));
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text('Finish & save'), findsOneWidget);
    expect(find.text('A little every day'), findsOneWidget);

    // Verify Counter Theme pill and test switching light themes
    expect(find.text('Theme: Sage Classic'), findsOneWidget);

    // Tap theme pill to open theme sheet (defaults to Light Themes tab in light mode)
    await tester.tap(find.text('Theme: Sage Classic'));
    await settle();

    expect(find.text('Counter Theme'), findsOneWidget);
    expect(find.text('Ceramic Frost'), findsOneWidget);
    expect(find.text('Warm Papyrus'), findsOneWidget);
    expect(find.text('Linen Minimal'), findsOneWidget);

    // Select Ceramic Frost theme (light mode theme)
    await tester.tap(find.text('Ceramic Frost'));
    await settle();

    // Verify theme changed to Ceramic Frost
    expect(find.text('Theme: Ceramic Frost'), findsOneWidget);

    // Now test switching to Dark Themes tab
    await tester.tap(find.text('Theme: Ceramic Frost'));
    await settle();

    await tester.tap(find.text('Dark Themes'));
    await settle();

    expect(find.text('Obsidian Ember'), findsOneWidget);
    expect(find.text('Midnight Aurora'), findsOneWidget);
    expect(find.text('Obsidian Sage'), findsOneWidget);
    expect(find.text('Charcoal Minimal'), findsOneWidget);

    // Select Obsidian Ember dark theme
    await tester.tap(find.text('Obsidian Ember'));
    await settle();

    // Verify theme changed to Obsidian Ember and the new squircle counter rendered
    expect(find.text('Theme: Obsidian Ember'), findsOneWidget);
    expect(find.text('And Pages'), findsOneWidget);

    // 4. Tap on the 'Journey' tab
    await tester.tap(find.text('Journey'));
    await settle();

    expect(find.text('Your journey'), findsOneWidget);
    expect(find.text('Small moments. Meaningful progress.'), findsOneWidget);
    expect(find.text('Books finished'), findsOneWidget);
    expect(find.text('Time well spent'), findsOneWidget);
    expect(find.text('A steady rhythm'), findsOneWidget);
    expect(find.text('7-day reading streak'), findsOneWidget);
    expect(find.text('Thoughtful reader'), findsOneWidget);

    // 5. Tap on the 'Ranks' tab (Leaderboard)
    await tester.tap(find.text('Ranks'));
    await settle();

    expect(find.text('Reading circle'), findsOneWidget);
    expect(find.text('Every page counts. Inspired together.'), findsOneWidget);
    expect(find.text('Daily rank'), findsOneWidget);
    expect(find.text('Weekly rank'), findsOneWidget);
    expect(find.text('Yearly rank'), findsOneWidget);
    expect(find.text('YOUR STANDING'), findsOneWidget);
    expect(find.text('All readers'), findsOneWidget);

    // Switch between Weekly rank and Yearly rank
    await tester.tap(find.text('Weekly rank'));
    await settle();
    expect(find.text('This week'), findsWidgets);

    await tester.tap(find.text('Yearly rank'));
    await settle();
    expect(find.text('This year'), findsWidgets);

    // 6. Tap on the 'Profile' tab
    await tester.tap(find.text('Profile'));
    await settle();

    expect(find.text('Your corner'), findsOneWidget);
    expect(find.text('The reader behind the pages.'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('On my shelf'), findsOneWidget);
    expect(find.text('Saved passages'), findsOneWidget);
    expect(find.text('My reading circles'), findsOneWidget);

    // 7. Tap on the 'Explore' tab
    await tester.tap(find.text('Explore'));
    await settle();

    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Search Open Library & curated bookshelves'), findsOneWidget);
    expect(find.text('Search title, author, or subject...'), findsOneWidget);
    expect(find.text('BOOK OF THE WEEK'), findsOneWidget);
  });

  testWidgets('BookDetailsSheet renders Direct Download and Telegram Bot sections', (WidgetTester tester) async {
    const testBook = OpenLibraryBook(
      id: '/works/OL12345W',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      iaId: 'prideprejudice00aust',
      ebookAccess: 'public',
      hasFulltext: true,
      firstPublishYear: 1813,
      workKey: '/works/OL12345W',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BookDetailsSheet(book: testBook),
        ),
      ),
    );
    await tester.pump();

    // Verify Direct eBook Download card
    expect(find.text('Direct eBook Download'), findsOneWidget);
    expect(find.text('Public domain · DRM-free full text'), findsOneWidget);
    expect(find.text('EPUB'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Download EPUB (1-Click)'), findsOneWidget);

    // Verify Telegram Bot section
    expect(find.text('Get via Telegram Bot'), findsOneWidget);
    expect(find.text('Send to Telegram Bot'), findsOneWidget);
    expect(find.text('Share Card'), findsOneWidget);
    expect(find.text('@BooksFinderBot'), findsOneWidget);
  });
}

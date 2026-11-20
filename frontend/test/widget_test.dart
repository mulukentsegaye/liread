import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';
import 'package:readers_hub/core/services/app_update_service.dart';
import 'package:readers_hub/core/theme/theme_controller.dart';
import 'package:readers_hub/core/utils/error_handler.dart';
import 'package:readers_hub/core/widgets/app_alert.dart';
import 'package:readers_hub/core/widgets/reader_avatar.dart';
import 'package:readers_hub/features/explore/data/open_library_service.dart';
import 'package:readers_hub/features/explore/data/telegram_bot_service.dart';
import 'package:readers_hub/features/explore/presentation/widgets/book_details_sheet.dart';
import 'package:readers_hub/features/feed/domain/post_model.dart';
import 'package:readers_hub/features/feed/presentation/widgets/feed_post_header.dart';
import 'package:readers_hub/features/leaderboard/data/reading_session_store.dart';
import 'package:readers_hub/features/navigation/presentation/main_navigation_shell.dart';
import 'package:readers_hub/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  testWidgets('App renders consolidated 4 tabs: Feed (with Live banner & Reading Circle), Explore, Read timer, and Profile', (WidgetTester tester) async {
    ReadingSessionStore.instance.reset();
    AppThemeController.instance.resetForTesting();
    await tester.pumpWidget(const LireadApp(homeOverride: MainNavigationShell()));

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // 1. Verify the Feed header and brand render
    expect(find.text('Between pages'), findsOneWidget);
    expect(find.text('LIREAD'), findsOneWidget);
    expect(find.text('Community Feed'), findsOneWidget);
    expect(find.text('Reading Circle'), findsOneWidget);

    // Verify Live Co-Reading banner on Feed
    expect(find.text('Live Co-Reading'), findsOneWidget);

    // Verify Settings icon in header
    expect(find.byIcon(Icons.settings_outlined), findsWidgets);

    // Verify the 4 bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 2. Switch to Reading Circle tab inside Feed
    await tester.tap(find.text('Reading Circle'));
    await settle();

    // Verify Leaderboard rendered inside Reading Circle tab
    expect(find.text('Daily rank'), findsOneWidget);
    expect(find.text('Weekly rank'), findsOneWidget);
    expect(find.text('Yearly rank'), findsOneWidget);
    expect(find.text('YOUR STANDING'), findsOneWidget);

    // Switch between Weekly rank and Yearly rank
    await tester.tap(find.text('Weekly rank'));
    await settle();
    expect(find.text('This week'), findsWidgets);

    await tester.tap(find.text('Yearly rank'));
    await settle();
    expect(find.text('This year'), findsWidgets);

    // 3. Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await settle();

    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsWidgets);
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

    // 4. Tap on the 'Explore' tab
    await tester.tap(find.text('Explore'));
    await settle();

    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Search Open Library & curated bookshelves'), findsOneWidget);
    expect(find.text('Search title, author, or subject...'), findsOneWidget);
    expect(find.text('BOOK OF THE WEEK'), findsOneWidget);

    // 5. Tap on the 'Profile' tab
    await tester.tap(find.text('Profile'));
    await settle();

    expect(find.text('Your corner'), findsOneWidget);
    expect(find.text('The reader behind the pages.'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('On my shelf'), findsOneWidget);
    expect(find.text('Saved passages'), findsOneWidget);
    expect(find.text('My reading circles'), findsOneWidget);
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

    // Verify Minimalist Telegram section
    expect(find.text('Get via Telegram'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('@BooksFinderBot'), findsNothing);
    expect(find.text('@LireadBooksBot'), findsNothing);
    expect(find.text('@lireadbooksbot'), findsNothing);
    expect(find.text('Share Card'), findsNothing);
  });

  test('TelegramBotService defaults to lireadbooksbot and migrates legacy usernames', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('liread_telegram_bot_name');
    final botName = await TelegramBotService.instance.getBotUsername();
    expect(botName, 'lireadbooksbot');

    // Test legacy migration
    await prefs.setString('liread_telegram_bot_name', 'BooksFinderBot');
    final migrated = await TelegramBotService.instance.getBotUsername();
    expect(migrated, 'lireadbooksbot');
  });

  test('AppErrorHandler translates technical auth and network errors to friendly messages', () {
    // 1. Invalid login credentials AuthException
    const authErr = AuthException('Invalid login credentials', statusCode: '400');
    expect(
      AppErrorHandler.format(authErr),
      'Incorrect email address or password. Please verify your details and try again.',
    );

    // 2. Technical string with AuthException format
    const strErr = 'AuthException(message: Invalid login credentials, statusCode: 400)';
    expect(
      AppErrorHandler.format(strErr),
      'Incorrect email address or password. Please verify your details and try again.',
    );

    // 3. User already exists
    const userErr = AuthException('User already registered', statusCode: '400');
    expect(
      AppErrorHandler.format(userErr),
      'An account with this email address already exists. Please sign in instead.',
    );

    // 4. Invalid email format
    const emailErr = AuthException('Unable to validate email address: invalid format', statusCode: '400');
    expect(
      AppErrorHandler.format(emailErr),
      'Please enter a valid email address (e.g. reader@example.com).',
    );

    // 5. Network lookup error
    const netErr = 'SocketException: Failed host lookup: xyz.supabase.co';
    expect(
      AppErrorHandler.format(netErr),
      'Unable to reach the server. Please check your internet connection and try again.',
    );

    // 6. Email validation helper
    expect(AppErrorHandler.isValidEmail('reader@example.com'), isTrue);
    expect(AppErrorHandler.isValidEmail('invalid-email'), isFalse);
    expect(AppErrorHandler.isValidEmail(''), isFalse);
  });

  testWidgets('AppAlertBanner renders user-friendly alert with dismiss action', (WidgetTester tester) async {
    bool dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAlertBanner(
            title: 'Sign In Notice',
            message: 'Incorrect email address or password. Please verify your details.',
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('Sign In Notice'), findsOneWidget);
    expect(find.text('Incorrect email address or password. Please verify your details.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    // Tap dismiss
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
  });

  test('AppUpdateService compares semantic versions correctly', () {
    final service = AppUpdateService.instance;

    // Newer patch version
    expect(service.isNewerVersion('1.2.3', '1.2.4'), isTrue);
    // Newer minor version
    expect(service.isNewerVersion('1.2.3', '1.3.0'), isTrue);
    // Newer major version
    expect(service.isNewerVersion('1.2.3', '2.0.0'), isTrue);

    // Same version
    expect(service.isNewerVersion('1.2.3', '1.2.3'), isFalse);
    // Older patch version
    expect(service.isNewerVersion('1.2.3', '1.2.2'), isFalse);
    // Older minor version
    expect(service.isNewerVersion('1.2.3', '1.1.9'), isFalse);
    // Older major version
    expect(service.isNewerVersion('2.0.0', '1.9.9'), isFalse);
  });

  testWidgets('FeedPostHeader renders ReaderAvatar with avatarUrl and author details', (WidgetTester tester) async {
    const avatarUrl = 'https://example.com/avatar.jpg';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedPostHeader(
            userName: 'Aman',
            userInitials: 'A',
            avatarUrl: avatarUrl,
            actionText: 'Finished a book',
            timeAgo: '34d ago',
          ),
        ),
      ),
    );

    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Finished a book · 34d ago'), findsOneWidget);
    expect(find.byType(ReaderAvatar), findsOneWidget);

    final avatarWidget = tester.widget<ReaderAvatar>(find.byType(ReaderAvatar));
    expect(avatarWidget.avatarUrl, equals(avatarUrl));
    expect(avatarWidget.name, equals('Aman'));
    expect(avatarWidget.initials, equals('A'));
  });

  test('FeedPost copyWith preserves avatarUrl when likes or bookmarks change', () {
    const post = FeedPost(
      id: 'post-1',
      userName: 'Aman',
      userInitials: 'A',
      avatarUrl: 'https://example.com/aman.png',
      actionText: 'Finished a book',
      timeAgo: '2h ago',
      type: PostType.quote,
      likes: 1,
      isLiked: false,
    );

    final updated = post.copyWith(likes: 2, isLiked: true);
    expect(updated.avatarUrl, equals('https://example.com/aman.png'));
    expect(updated.likes, equals(2));
    expect(updated.isLiked, isTrue);
  });
}

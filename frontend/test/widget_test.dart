import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';
import 'package:readers_hub/features/leaderboard/data/reading_session_store.dart';

void main() {
  testWidgets('App renders Feed, Read timer, Journey, Ranks leaderboard, and Profile tabs', (WidgetTester tester) async {
    ReadingSessionStore.instance.reset();
    await tester.pumpWidget(const ReadersHubApp());

    // 1. Verify the Feed header renders
    expect(find.text('Between pages'), findsOneWidget);

    // Verify all 5 bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Ranks'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 2. Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsNWidgets(2));
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text('Finish & save'), findsOneWidget);
    expect(find.text('A little every day'), findsOneWidget);

    // 3. Tap on the 'Journey' tab
    await tester.tap(find.text('Journey'));
    await tester.pumpAndSettle();

    expect(find.text('Your journey'), findsOneWidget);
    expect(find.text('Small moments. Meaningful progress.'), findsOneWidget);
    expect(find.text('Books finished'), findsOneWidget);
    expect(find.text('Time well spent'), findsOneWidget);
    expect(find.text('A steady rhythm'), findsOneWidget);
    expect(find.text('7-day reading streak'), findsOneWidget);
    expect(find.text('Thoughtful reader'), findsOneWidget);

    // 4. Tap on the 'Ranks' tab (Leaderboard)
    await tester.tap(find.text('Ranks'));
    await tester.pumpAndSettle();

    expect(find.text('Reading circle'), findsOneWidget);
    expect(find.text('Every page counts. Inspired together.'), findsOneWidget);
    expect(find.text('Daily rank'), findsOneWidget);
    expect(find.text('Weekly rank'), findsOneWidget);
    expect(find.text('Yearly rank'), findsOneWidget);
    expect(find.text('YOUR STANDING'), findsOneWidget);
    expect(find.text('All readers'), findsOneWidget);

    // Switch between Weekly rank and Yearly rank
    await tester.tap(find.text('Weekly rank'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsWidgets);

    await tester.tap(find.text('Yearly rank'));
    await tester.pumpAndSettle();
    expect(find.text('This year'), findsWidgets);

    // 5. Tap on the 'Profile' tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Your corner'), findsOneWidget);
    expect(find.text('The reader behind the pages.'), findsOneWidget);
    expect(find.text('Emma Laurent'), findsWidgets);
    expect(find.text('@emma.reads'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('On my shelf'), findsOneWidget);
    expect(find.text('Saved passages'), findsOneWidget);
    expect(find.text('My reading circles'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';

void main() {
  testWidgets('App renders Feed, Read timer, Journey, and Profile tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadersHubApp());

    // 1. Verify the Feed header renders
    expect(find.text('Between pages'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 2. Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsNWidgets(2));
    expect(find.text('Pause session'), findsOneWidget);
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

    // 4. Tap on the 'Profile' tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Your corner'), findsOneWidget);
    expect(find.text('The reader behind the pages.'), findsOneWidget);
    expect(find.text('Emma Laurent'), findsOneWidget);
    expect(find.text('@emma.reads'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('On my shelf'), findsOneWidget);
    expect(find.text('Saved passages'), findsOneWidget);
    expect(find.text('My reading circles'), findsOneWidget);
  });
}

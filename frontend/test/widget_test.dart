import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';

void main() {
  testWidgets('App renders the discover feed and switches to reading timer', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadersHubApp());

    // Verify the feed header renders
    expect(find.text('Between pages'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap on the 'Read' tab
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    // Verify the Reading timer header and controls render
    expect(find.text('A moment to read'), findsOneWidget);
    expect(find.text('One page. One breath. At your pace.'), findsOneWidget);
    expect(find.text('Before the coffee gets cold'), findsNWidgets(2));
    expect(find.text('Pause session'), findsOneWidget);
    expect(find.text('Finish & save'), findsOneWidget);
    expect(find.text('A little every day'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:readers_hub/app.dart';

void main() {
  testWidgets('App renders the discover feed', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadersHubApp());

    // Verify the feed header renders
    expect(find.text('Between pages'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

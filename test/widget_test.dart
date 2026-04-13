import 'package:flutter_test/flutter_test.dart';
import 'package:barka_app/main.dart';

void main() {
  testWidgets('Barka app loads Home page successfully', (WidgetTester tester) async {
    
    // Build the app
    await tester.pumpWidget(const BarkaApp());

    // Let the UI settle
    await tester.pumpAndSettle();

    // Check if app loads (Home page should appear)
    expect(find.byType(BarkaApp), findsOneWidget);
  });
}
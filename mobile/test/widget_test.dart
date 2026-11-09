import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('DocuMind app smoke test', (WidgetTester tester) async {
    // Build the DocumentIntelligenceApp and trigger a frame.
    await tester.pumpWidget(const DocumentIntelligenceApp());
    await tester.pumpAndSettle();

    // Verify that the title text DocuMind AI is present on dashboard
    expect(find.text('DocuMind AI'), findsOneWidget);
  });
}

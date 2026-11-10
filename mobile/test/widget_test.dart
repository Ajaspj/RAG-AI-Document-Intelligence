import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('DocuMind app smoke test and navigation verification', (WidgetTester tester) async {
    // Build the DocumentIntelligenceApp and trigger frames
    await tester.pumpWidget(const DocumentIntelligenceApp());
    await tester.pumpAndSettle();

    // Verify app brand is present
    expect(find.text('DocuMind AI'), findsOneWidget);
    expect(find.text('Good to see you 👋'), findsOneWidget);

    // Verify all 4 bottom navigation tabs are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify Overview Stat Cards
    expect(find.text('Total Files'), findsOneWidget);
    expect(find.text('Processed'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('AI Queries'), findsOneWidget);

    // Test Navigation: Tap "Documents" tab
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    // Verify Documents screen is displayed
    expect(find.text('My Documents'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(4));

    // Test Navigation: Tap "AI Chat" tab
    await tester.tap(find.text('AI Chat'));
    await tester.pumpAndSettle();

    // Verify AI Chat screen is displayed
    expect(find.text('DocuMind Assistant'), findsOneWidget);
    expect(find.text('Suggested Questions'), findsOneWidget);

    // Test Navigation: Tap "Profile" tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Profile screen is displayed
    expect(find.text('Account & Settings'), findsOneWidget);
    expect(find.text('Document Storage'), findsOneWidget);

    // Return to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Good to see you 👋'), findsOneWidget);
  });
}

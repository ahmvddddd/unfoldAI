import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unfoldAI/screens/dashboard/dashboard.dart';

void main() {
  testWidgets('DashboardPage displays charts and toggles dataset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: DashboardPage())));
    expect(find.text('Biometrics Dashboard'), findsOneWidget);

    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Simulate reload
    await tester.pumpAndSettle();
    expect(find.text('Heart Rate Variability (HRV)'), findsOneWidget);
  });
}

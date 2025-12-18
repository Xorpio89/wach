import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wach_flutter/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WachApp(),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify app name is displayed
    expect(find.text('W.A.C.H.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Klaert eine Frage, bevor am Code weitergesucht wird: blendet eine
/// Meldung im Testumfeld ueberhaupt von selbst aus?
///
/// Ohne diese Kontrolle laesst sich ein Fehler in der App nicht von einer
/// Eigenheit der Testumgebung unterscheiden.
void main() {
  testWidgets('eine Meldung ohne Screenwechsel blendet aus', (tester) async {
    late ScaffoldMessengerState messenger;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            messenger = ScaffoldMessenger.of(context);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 6),
        content: Text('Hinweis'),
      ),
    );
    await tester.pump();
    expect(find.text('Hinweis'), findsOneWidget);

    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Hinweis'), findsNothing);
  });
}

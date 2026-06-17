import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idle_rpg/main.dart';

void main() {
  testWidgets('App boots into the server-driven battle (dumb client)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const IdleRpgApp());
    await tester.pump();

    // With no server reachable in the test, the dumb client shows its
    // connecting state (it never simulates combat locally).
    expect(find.text('CONNECTING TO SERVER'), findsOneWidget);

    // Tear down so the polling timer is cancelled before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}

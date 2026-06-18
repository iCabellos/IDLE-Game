import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idle_rpg/core/game/combat_service.dart';
import 'package:idle_rpg/main.dart';

void main() {
  testWidgets('App boots with the always-on combat panel pinned in the shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(const IdleRpgApp());
    await tester.pump();

    // No server in the test: the persistent panel shows its connecting state.
    expect(find.text('CONNECTING…'), findsOneWidget);

    // Stop the shared poller and tear down so no timers leak.
    CombatService.instance.stop();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

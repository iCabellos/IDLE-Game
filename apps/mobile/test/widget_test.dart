import 'package:flutter_test/flutter_test.dart';

import 'package:idle_rpg/main.dart';

void main() {
  testWidgets('App boots to the title screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IdleRpgApp());
    // The title screen runs looping sprite animations, so settle would never
    // finish — pump a few fixed frames instead.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Idle RPG'), findsOneWidget);
    expect(find.text('CONECTAR CON STEAM'), findsOneWidget);
  });
}

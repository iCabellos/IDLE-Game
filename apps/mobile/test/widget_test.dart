import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idle_rpg/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IdleRpgApp());
    await tester.pumpAndSettle();

    expect(find.text('Idle RPG'), findsOneWidget);
    expect(find.text('Conectar con Steam'), findsOneWidget);
  });
}

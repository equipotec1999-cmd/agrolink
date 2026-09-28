import 'package:agrolink/shared/widgets/agro_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AgroButton responde al toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgroButton(label: 'Entrar', onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}

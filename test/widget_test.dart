import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_iot/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileIotApp());
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_innis/main.dart';

void main() {
  testWidgets('VetCare muestra la pantalla de acceso', (WidgetTester tester) async {
    await tester.pumpWidget(const VetCareApp());
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}

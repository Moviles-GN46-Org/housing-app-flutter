import 'package:flutter_test/flutter_test.dart';
import 'package:housing_app_flutter/main.dart'; // Asegura tu ruta aquí

void main() {
  testWidgets('La app compila e inicializa Firebase', (WidgetTester tester) async {
    // Construimos nuestra nueva app CasAndesApp en lugar de MyApp
    await tester.pumpWidget(const CasAndesApp());

    // Verificamos que el texto que pusimos en el main esté en pantalla
    expect(find.textContaining('Firebase Conectado'), findsOneWidget);
  });
}
import 'package:alim/app/app.dart';
import 'package:alim/app/di.dart';
import 'package:alim_engine_mock/alim_engine_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester,
      {required bool autoAuthenticate}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          engineProvider.overrideWith((ref) {
            final engine = MockMessagingEngine(
              autoAuthenticate: autoAuthenticate,
              replyDelay: Duration.zero,
            );
            ref.onDispose(engine.dispose);
            engine.start();
            return engine;
          }),
        ],
        child: const AlimApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('autenticado: muestra la lista de chats semilla',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    expect(find.text('ALIM'), findsOneWidget);
    expect(find.text('Equipo ALIM'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('sin sesión: redirige al flujo de autenticación',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: false);

    expect(find.text('Inicia sesión'), findsOneWidget);
  });

  testWidgets('abrir un chat muestra sus mensajes y permite escribir',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('¿O sea que puedo rediseñar mi burbuja en runtime?'),
      findsWidgets,
    );

    await tester.enterText(find.byType(TextField), 'hola desde el test');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('hola desde el test'), findsOneWidget);
  });
}

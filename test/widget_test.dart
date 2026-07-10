import 'package:alim/app/app.dart';
import 'package:alim/app/di.dart';
import 'package:alim_engine_mock/alim_engine_mock.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
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

  testWidgets('Dev Mode: aplicar el preset Tinta cambia el tema en caliente',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    ThemeData appTheme() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    final defaultBubbleRadius =
        appTheme().extension<AlimBubbleStyle>()!.radius;
    expect(defaultBubbleRadius, 16);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo Desarrollador'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tinta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // El tema compilado cambió sin reiniciar: hot-apply verificado.
    expect(appTheme().extension<AlimBubbleStyle>()!.radius, 6);
    expect(find.textContaining('Tema aplicado'), findsOneWidget);
  });
}

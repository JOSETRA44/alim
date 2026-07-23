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

  testWidgets('long-press sobre un mensaje propio permite borrarlo',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'mensaje a borrar');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('mensaje a borrar'), findsOneWidget);

    // Long-press sobre la burbuja propia → menú → borrar.
    await tester.longPress(find.text('mensaje a borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar para todos'));
    await tester.pumpAndSettle();

    expect(find.text('mensaje a borrar'), findsNothing);
  });

  testWidgets('long-press sobre un mensaje propio permite editarlo',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'testo con herror');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.longPress(find.text('testo con herror'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    // El diálogo trae el texto actual; lo corrijo y guardo.
    await tester.enterText(
        find.byType(TextField).last, 'texto sin error');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('texto sin error'), findsOneWidget);
    expect(find.text('testo con herror'), findsNothing);
    expect(find.textContaining('editado'), findsOneWidget);
  });

  testWidgets('Dev Mode: aplicar el preset Tinta cambia el tema en caliente',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    const key = BubbleContextKey(
        isOutgoing: true, isRead: false, isGroup: false, isFailed: false);
    ThemeData appTheme() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(appTheme().extension<AlimBubbleTheme>()!.resolve(key).radius, 16);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo Desarrollador'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tinta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // El tema compilado cambió sin reiniciar: hot-apply verificado.
    expect(appTheme().extension<AlimBubbleTheme>()!.resolve(key).radius, 6);
    expect(find.textContaining('Tema aplicado'), findsOneWidget);
  });

  testWidgets('preset Expresivo: layout de bloques renderiza la burbuja',
      (tester) async {
    await pumpApp(tester, autoAuthenticate: true);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo Desarrollador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expresivo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // go('/dev') deja la pila ['/', '/dev']: un back vuelve a chats.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipo ALIM'));
    await tester.pumpAndSettle();

    // El layout custom muestra la etiqueta 'tú' en los mensajes salientes.
    expect(find.text('tú'), findsWidgets);
    expect(find.text('Zarpamos con el Hito 1 🚀'), findsOneWidget);
  });
}

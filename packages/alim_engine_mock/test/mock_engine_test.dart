import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_mock/alim_engine_mock.dart';
import 'package:test/test.dart';

void main() {
  group('MockMessagingEngine auth', () {
    test('autoAuthenticate deja el motor en AuthReady', () async {
      final engine = MockMessagingEngine();
      await engine.start();
      expect(engine.currentAuthState, isA<AuthReady>());
      await engine.dispose();
    });

    test('flujo manual: teléfono -> código -> ready', () async {
      final engine = MockMessagingEngine(autoAuthenticate: false);
      await engine.start();
      expect(engine.currentAuthState, isA<AuthWaitingPhoneNumber>());

      await engine.submitPhoneNumber('+34600111222');
      expect(engine.currentAuthState, isA<AuthWaitingCode>());

      await engine.submitCode('12345');
      expect(engine.currentAuthState, isA<AuthReady>());
      await engine.dispose();
    });

    test('código 11111 exige 2FA y la contraseña "alim" autentica', () async {
      final engine = MockMessagingEngine(autoAuthenticate: false);
      await engine.start();
      await engine.submitPhoneNumber('+34600111222');
      await engine.submitCode('11111');
      expect(engine.currentAuthState, isA<AuthWaitingPassword>());

      await engine.submitPassword('nope');
      final failed = engine.currentAuthState;
      expect(failed, isA<AuthWaitingPassword>());
      expect((failed as AuthWaitingPassword).error, isNotNull);

      await engine.submitPassword('alim');
      expect(engine.currentAuthState, isA<AuthReady>());
      await engine.dispose();
    });

    test('teléfono inválido reporta error sin avanzar', () async {
      final engine = MockMessagingEngine(autoAuthenticate: false);
      await engine.start();
      await engine.submitPhoneNumber('123');
      final state = engine.currentAuthState;
      expect(state, isA<AuthWaitingPhoneNumber>());
      expect((state as AuthWaitingPhoneNumber).error, isNotNull);
      await engine.dispose();
    });
  });

  group('MockMessagingEngine mensajes', () {
    test('los chats semilla se emiten ordenados (pinned primero)', () async {
      final engine = MockMessagingEngine();
      await engine.start();
      final chats = await engine.chats.first;
      expect(chats, isNotEmpty);
      expect(chats.first.isPinned, isTrue);
      await engine.dispose();
    });

    test('sendText añade el mensaje y llega una respuesta automática',
        () async {
      final engine = MockMessagingEngine(replyDelay: Duration.zero);
      await engine.start();

      await engine.sendText('c-ada', 'hola Ada');
      var messages = await engine.watchMessages('c-ada').first;
      expect(messages.last.content.preview, 'hola Ada');
      expect(messages.last.isOutgoing, isTrue);

      // Deja correr el Timer(Duration.zero) de la respuesta.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      messages = await engine.watchMessages('c-ada').first;
      expect(messages.last.isOutgoing, isFalse);
      await engine.dispose();
    });

    test('markChatRead pone el contador a cero', () async {
      final engine = MockMessagingEngine();
      await engine.start();
      await engine.markChatRead('c-equipo');
      final chats = await engine.chats.first;
      final team = chats.singleWhere((c) => c.id == 'c-equipo');
      expect(team.unreadCount, 0);
      await engine.dispose();
    });

    test('tras dispose los comandos fallan y los timers no revientan',
        () async {
      final engine = MockMessagingEngine(replyDelay: Duration.zero);
      await engine.start();
      await engine.sendText('c-ada', 'último');
      await engine.dispose();
      expect(() => engine.sendText('c-ada', 'x'), throwsA(anything));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });
}

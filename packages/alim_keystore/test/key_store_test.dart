import 'dart:convert';

import 'package:alim_keystore/alim_keystore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Almacén seguro falso: un Map. Permite ejercitar [SecureKeyStore] sin
/// tocar DPAPI/Keystore reales.
class FakeSecureStorage extends FlutterSecureStorage {
  const FakeSecureStorage(this.slots);

  final Map<String, String> slots;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      slots[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      slots.remove(key);
    } else {
      slots[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    slots.remove(key);
  }
}

void main() {
  test('la clave se genera una vez y es estable entre llamadas', () async {
    final store = SecureKeyStore(FakeSecureStorage({}));

    final first = await store.keyFor('tdlib');
    final second = await store.keyFor('tdlib');

    expect(first.length, 32);
    expect(second, first,
        reason: 'una clave distinta dejaría la BD anterior ilegible');
  });

  test('cada propósito tiene su propia clave', () async {
    final store = SecureKeyStore(FakeSecureStorage({}));

    final tdlib = await store.keyFor('tdlib');
    final drift = await store.keyFor('drift');

    expect(tdlib, isNot(drift));
  });

  test('dos almacenes distintos generan claves distintas (es aleatoria)',
      () async {
    final a = await SecureKeyStore(FakeSecureStorage({})).keyFor('tdlib');
    final b = await SecureKeyStore(FakeSecureStorage({})).keyFor('tdlib');

    expect(a, isNot(b), reason: 'la clave no puede ser constante');
  });

  test('un slot corrupto se regenera en vez de usar una clave inválida',
      () async {
    final slots = {'alim.dbkey.tdlib': base64Encode([1, 2, 3])}; // 3 bytes
    final store = SecureKeyStore(FakeSecureStorage(slots));

    final key = await store.keyFor('tdlib');

    expect(key.length, 32);
    expect(base64Decode(slots['alim.dbkey.tdlib']!).length, 32);
  });

  test('forget borra la clave del almacén', () async {
    final slots = <String, String>{};
    final store = SecureKeyStore(FakeSecureStorage(slots));

    await store.keyFor('tdlib');
    expect(slots, isNotEmpty);

    await store.forget('tdlib');
    expect(slots, isEmpty);
  });
}

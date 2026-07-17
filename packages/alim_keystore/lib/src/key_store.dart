import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:alim_core/alim_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén de claves de cifrado de las BD locales.
///
/// Contrato: [keyFor] es idempotente — la primera llamada para un
/// [purpose] genera una clave aleatoria y la persiste; las siguientes
/// devuelven exactamente la misma. Si la clave se pierde (el usuario
/// resetea el almacén del SO, reinstala, etc.) los datos cifrados con ella
/// son irrecuperables por diseño: hay que volver a iniciar sesión.
abstract interface class SecretKeyStore {
  /// Clave de 32 bytes asociada a [purpose] (p. ej. `tdlib`, `drift`).
  Future<Uint8List> keyFor(String purpose);

  /// Olvida la clave de [purpose]. Se llama al cerrar sesión: sin la clave,
  /// lo que quede en disco es ruido.
  Future<void> forget(String purpose);
}

/// Implementación de producción sobre el almacén seguro del SO.
class SecureKeyStore implements SecretKeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static final _log = AlimLogger('SecureKeyStore');
  static const _keyLengthBytes = 32;

  final FlutterSecureStorage _storage;

  String _slot(String purpose) => 'alim.dbkey.$purpose';

  @override
  Future<Uint8List> keyFor(String purpose) async {
    final slot = _slot(purpose);
    final existing = await _storage.read(key: slot);
    if (existing != null) {
      final decoded = base64Decode(existing);
      if (decoded.length == _keyLengthBytes) return decoded;
      // Slot corrupto: se regenera en vez de arrancar con una clave inválida.
      _log.warning('clave de "$purpose" corrupta; se regenera');
    }

    final key = _generateKey();
    await _storage.write(key: slot, value: base64Encode(key));
    _log.info('clave de "$purpose" generada');
    return key;
  }

  @override
  Future<void> forget(String purpose) => _storage.delete(key: _slot(purpose));

  static Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256)),
    );
  }
}

/// Almacén en memoria para tests: misma semántica, sin tocar el SO.
class InMemoryKeyStore implements SecretKeyStore {
  final Map<String, Uint8List> _keys = {};

  @override
  Future<Uint8List> keyFor(String purpose) async => _keys.putIfAbsent(
        purpose,
        () => Uint8List.fromList(List<int>.filled(32, 7)),
      );

  @override
  Future<void> forget(String purpose) async => _keys.remove(purpose);
}

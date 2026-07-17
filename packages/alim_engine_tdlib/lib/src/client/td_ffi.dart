import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _CreateClientIdC = Int32 Function();
typedef _CreateClientIdD = int Function();
typedef _SendC = Void Function(Int32 clientId, Pointer<Utf8> request);
typedef _SendD = void Function(int clientId, Pointer<Utf8> request);
typedef _ReceiveC = Pointer<Utf8> Function(Double timeout);
typedef _ReceiveD = Pointer<Utf8> Function(double timeout);
typedef _ExecuteC = Pointer<Utf8> Function(Pointer<Utf8> request);
typedef _ExecuteD = Pointer<Utf8> Function(Pointer<Utf8> request);

/// Bindings crudos a la interfaz JSON de `tdjson` (API moderna por
/// client id). Cada isolate abre su propia instancia; la librería nativa
/// subyacente es única por proceso.
///
/// Contratos de la API C:
/// - `td_send` es thread-safe (se llama desde el isolate principal).
/// - `td_receive` solo debe ejecutarse desde un hilo a la vez (el isolate
///   receptor dedicado).
/// - Los strings devueltos pertenecen a TDLib: se copian a Dart y NUNCA se
///   liberan; solo son válidos hasta la siguiente llamada en ese hilo.
class TdFfi {
  TdFfi._(DynamicLibrary lib)
      : createClientId = lib
            .lookupFunction<_CreateClientIdC, _CreateClientIdD>(
                'td_create_client_id'),
        _send = lib.lookupFunction<_SendC, _SendD>('td_send'),
        _receive = lib.lookupFunction<_ReceiveC, _ReceiveD>('td_receive'),
        _execute = lib.lookupFunction<_ExecuteC, _ExecuteD>('td_execute');

  static TdFfi open() => TdFfi._(_openLibrary());

  static DynamicLibrary _openLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('tdjson.dll');
    if (Platform.isAndroid) return DynamicLibrary.open('libtdjson.so');
    if (Platform.isLinux) return DynamicLibrary.open('libtdjson.so');
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('libtdjson.dylib');
    }
    throw UnsupportedError(
        'TDLib no soportado en ${Platform.operatingSystem}');
  }

  final int Function() createClientId;
  final _SendD _send;
  final _ReceiveD _receive;
  final _ExecuteD _execute;

  void send(int clientId, String request) {
    final native = request.toNativeUtf8();
    try {
      _send(clientId, native);
    } finally {
      malloc.free(native);
    }
  }

  /// Bloquea hasta [timeout] segundos. Null si no hubo eventos.
  String? receive(double timeout) {
    final result = _receive(timeout);
    return result == nullptr ? null : result.toDartString();
  }

  /// Peticiones síncronas (solo los métodos marcados como "can be called
  /// synchronously" en la documentación de TDLib).
  String? execute(String request) {
    final native = request.toNativeUtf8();
    try {
      final result = _execute(native);
      return result == nullptr ? null : result.toDartString();
    } finally {
      malloc.free(native);
    }
  }
}

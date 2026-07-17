import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:alim_core/alim_core.dart';

import 'td_client.dart';
import 'td_ffi.dart';

/// Transporte FFI real.
///
/// Diseño de hilos (ver doc de [TdFfi]):
/// - el isolate PRINCIPAL llama a `td_send`/`td_execute` (thread-safe);
/// - un isolate RECEPTOR dedicado ejecuta el loop bloqueante `td_receive`
///   con timeout corto y cede el event loop en cada vuelta, de modo que la
///   orden de parada llegue en <500ms (cero isolates zombie).
class TdFfiClient implements TdClient {
  TdFfiClient();

  static final _log = AlimLogger('TdFfiClient');

  late final TdFfi _ffi;
  late final int clientId;

  final _updates = StreamController<TdObject>.broadcast();
  final Map<int, Completer<TdObject>> _pending = {};
  int _extraSeq = 0;

  Isolate? _receiverIsolate;
  SendPort? _receiverControl;
  StreamSubscription<Object?>? _eventsSub;
  final _receiverExited = Completer<void>();

  bool _started = false;
  bool _closed = false;

  @override
  Stream<TdObject> get updates => _updates.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _ffi = TdFfi.open();
    // Solo errores al log nativo; la app tiene su propio logging.
    _ffi.execute(
        jsonEncode({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': 1}));
    clientId = _ffi.createClientId();

    final events = ReceivePort();
    final controlReady = Completer<SendPort>();
    _eventsSub = events.listen((message) {
      if (message is SendPort) {
        controlReady.complete(message);
      } else if (message is String) {
        _dispatch(message);
      } else if (message == null) {
        if (!_receiverExited.isCompleted) _receiverExited.complete();
      }
    });

    _receiverIsolate = await Isolate.spawn(
      _receiveLoop,
      events.sendPort,
      debugName: 'alim-tdlib-receiver',
    );
    _receiverControl = await controlReady.future;

    // El cliente nativo se activa con su primera petición.
    post({'@type': 'getOption', 'name': 'version'});
    _log.info('cliente TDLib #$clientId arrancado');
  }

  @override
  Future<TdObject> send(TdObject request) {
    if (_closed) {
      throw const EngineException('Transporte TDLib cerrado', code: 'CLOSED');
    }
    final extra = ++_extraSeq;
    final completer = Completer<TdObject>();
    _pending[extra] = completer;
    _ffi.send(clientId, jsonEncode({...request, '@extra': extra}));
    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _pending.remove(extra);
        throw EngineException(
          'TDLib no respondió a ${request['@type']}',
          code: 'TIMEOUT',
        );
      },
    );
  }

  @override
  void post(TdObject request) {
    if (_closed) return;
    _ffi.send(clientId, jsonEncode(request));
  }

  /// Cierra un cliente nativo huérfano de una sesión previa del MISMO
  /// proceso (hot-restart). Enviar a un id inexistente es inocuo.
  void closeStaleClient(int staleClientId) {
    _ffi.send(staleClientId, jsonEncode({'@type': 'close'}));
    _log.info('close enviado al cliente huérfano #$staleClientId');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    // Cierre ordenado del cliente nativo; el loop receptor se detiene aparte.
    _ffi.send(clientId, jsonEncode({'@type': 'close'}));
    _receiverControl?.send('stop');
    try {
      await _receiverExited.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      _log.warning('el receptor no salió a tiempo; kill forzado');
      _receiverIsolate?.kill(priority: Isolate.immediate);
    }
    await _eventsSub?.cancel();
    _receiverIsolate = null;

    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(
            const EngineException('Transporte cerrado', code: 'CLOSED'));
      }
    }
    _pending.clear();
    await _updates.close();
    _log.info('cliente TDLib #$clientId cerrado');
  }

  void _dispatch(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) return;
    // La API moderna multiplexa todos los clientes del proceso: se filtra
    // lo que no sea nuestro (p. ej. un cliente huérfano de hot-restart).
    if (decoded['@client_id'] != clientId) return;

    final extra = decoded['@extra'];
    if (extra is int) {
      final completer = _pending.remove(extra);
      if (completer == null || completer.isCompleted) return;
      if (decoded['@type'] == 'error') {
        completer.completeError(TdRequestException(
          decoded['message'] as String? ?? 'error TDLib',
          tdCode: decoded['code'] as int?,
        ));
      } else {
        completer.complete(decoded);
      }
      return;
    }
    if (!_updates.isClosed) _updates.add(decoded);
  }

  /// Entry point del isolate receptor.
  static Future<void> _receiveLoop(SendPort events) async {
    final ffi = TdFfi.open();
    final control = ReceivePort();
    events.send(control.sendPort);

    var stop = false;
    control.listen((message) {
      if (message == 'stop') stop = true;
    });

    while (!stop) {
      // Bloquea este hilo ≤500ms; luego cede el event loop para que la
      // orden de parada del puerto de control pueda procesarse.
      final raw = ffi.receive(0.5);
      if (raw != null) events.send(raw);
      await Future<void>.delayed(Duration.zero);
    }
    control.close();
    events.send(null);
  }
}

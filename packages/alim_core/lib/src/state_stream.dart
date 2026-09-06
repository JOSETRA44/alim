import 'dart:async';

/// Stream con valor actual: cada suscriptor recibe el último valor al
/// suscribirse y luego las actualizaciones (semántica BehaviorSubject,
/// sin depender de rxdart).
///
/// Es la primitiva reactiva estándar de los motores de ALIM: la UI puede
/// suscribirse en cualquier momento sin perder el estado vigente.
class StateStream<T> {
  StateStream(this._value, {this.onIdle});

  /// Se invoca cuando el ÚLTIMO oyente cancela su suscripción. Permite
  /// liberar recursos asociados al stream (p. ej. cerrar un chat en TDLib)
  /// sin que la UI tenga que acordarse de pedirlo.
  ///
  /// Ojo: un rebuild de la UI puede cancelar y volver a suscribirse en el
  /// mismo frame, así que quien lo use debe aplicar un margen antes de
  /// liberar de verdad y volver a comprobar [hasListeners].
  final void Function()? onIdle;

  T _value;
  bool _closed = false;
  final Set<MultiStreamController<T>> _listeners = {};

  T get value => _value;

  /// true si alguien sigue suscrito.
  bool get hasListeners => _listeners.isNotEmpty;

  set value(T next) {
    if (_closed) return;
    _value = next;
    for (final listener in List.of(_listeners)) {
      listener.add(next);
    }
  }

  late final Stream<T> stream = Stream.multi((controller) {
    if (_closed) {
      controller.close();
      return;
    }
    controller.add(_value);
    _listeners.add(controller);
    controller.onCancel = () {
      _listeners.remove(controller);
      if (_listeners.isEmpty && !_closed) onIdle?.call();
    };
  });

  void close() {
    if (_closed) return;
    _closed = true;
    for (final listener in List.of(_listeners)) {
      listener.close();
    }
    _listeners.clear();
  }
}

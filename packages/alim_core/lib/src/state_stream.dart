import 'dart:async';

/// Stream con valor actual: cada suscriptor recibe el último valor al
/// suscribirse y luego las actualizaciones (semántica BehaviorSubject,
/// sin depender de rxdart).
///
/// Es la primitiva reactiva estándar de los motores de ALIM: la UI puede
/// suscribirse en cualquier momento sin perder el estado vigente.
class StateStream<T> {
  StateStream(this._value);

  T _value;
  bool _closed = false;
  final Set<MultiStreamController<T>> _listeners = {};

  T get value => _value;

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
    controller.onCancel = () => _listeners.remove(controller);
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

import 'dart:async';

/// Cancellation belongs to a single user operation, including its repair calls.
class AiCancellation {
  static final Object _zoneKey = Object();
  final Completer<void> _cancelled = Completer<void>();

  static AiCancellation? get current =>
      Zone.current[_zoneKey] as AiCancellation?;
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }

  Future<T> run<T>(Future<T> Function() action) =>
      runZoned(action, zoneValues: {_zoneKey: this});
}

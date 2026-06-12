class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const OperationCanceledException();
    }
  }
}

class OperationCanceledException implements Exception {
  final String message;
  const OperationCanceledException([this.message = 'Operation was cancelled.']);

  @override
  String toString() => 'OperationCanceledException: $message';
}

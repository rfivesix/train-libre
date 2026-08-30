import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../../core/media/meal_image_processor.dart';

enum PreProcessStatus {
  idle,
  processing,
  completed,
  cancelled,
  error,
}

class PreProcessState {
  final File file;
  final PreProcessStatus status;
  final double progress;
  final String? base64Data;
  final String? error;

  const PreProcessState({
    required this.file,
    this.status = PreProcessStatus.idle,
    this.progress = 0.0,
    this.base64Data,
    this.error,
  });

  PreProcessState copyWith({
    PreProcessStatus? status,
    double? progress,
    String? base64Data,
    String? error,
  }) {
    return PreProcessState(
      file: file,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      base64Data: base64Data ?? this.base64Data,
      error: error ?? this.error,
    );
  }
}

/// Helper service to handle local pre-processing and background encoding of images
/// as soon as photos are captured or selected.
class PhotoPreProcessor {
  final Map<String, ValueNotifier<PreProcessState>> _notifiers = {};
  final Map<String, bool> _cancelTokens = {};

  ValueNotifier<PreProcessState> getNotifier(File file) {
    final key = file.path;
    if (!_notifiers.containsKey(key)) {
      _notifiers[key] = ValueNotifier(PreProcessState(file: file));
    }
    return _notifiers[key]!;
  }

  /// Initiates background processing for a list of images.
  void processImages(List<File> files) {
    for (final file in files) {
      final notifier = getNotifier(file);
      if (notifier.value.status == PreProcessStatus.completed ||
          notifier.value.status == PreProcessStatus.processing) {
        continue;
      }
      _startBackgroundProcess(file);
    }
  }

  /// Cancels background processing and disposes notifier for a given file.
  void cancelAndRemove(File file) {
    final key = file.path;
    _cancelTokens[key] = true;
    MealImageProcessor.instance.evict(file);
    final notifier = _notifiers[key];
    if (notifier != null) {
      notifier.value = notifier.value.copyWith(
        status: PreProcessStatus.cancelled,
      );
      notifier.dispose();
      _notifiers.remove(key);
    }
  }

  /// Cancels all ongoing tasks and cleans up.
  void dispose() {
    for (final key in _notifiers.keys) {
      _cancelTokens[key] = true;
      _notifiers[key]?.dispose();
    }
    _notifiers.clear();
    _cancelTokens.clear();
  }

  /// Waits until all images in the list have finished processing (or failed/cancelled).
  Future<void> waitForCompletion(List<File> files) async {
    final pending = files.where((f) {
      final notifier = _notifiers[f.path];
      if (notifier == null) return false;
      return notifier.value.status == PreProcessStatus.processing ||
          notifier.value.status == PreProcessStatus.idle;
    }).toList();

    if (pending.isEmpty) return;

    final completer = Completer<void>();
    void checkDone() {
      final allDone = pending.every((f) {
        final st = _notifiers[f.path]?.value.status;
        return st == PreProcessStatus.completed ||
            st == PreProcessStatus.error ||
            st == PreProcessStatus.cancelled;
      });
      if (allDone && !completer.isCompleted) {
        completer.complete();
      }
    }

    final listeners = <VoidCallback>[];
    for (final f in pending) {
      final notifier = getNotifier(f);
      void listener() => checkDone();
      notifier.addListener(listener);
      listeners.add(listener);
    }

    checkDone();
    await completer.future;

    for (var i = 0; i < pending.length; i++) {
      _notifiers[pending[i].path]?.removeListener(listeners[i]);
    }
  }

  void _startBackgroundProcess(File file) async {
    final key = file.path;
    _cancelTokens[key] = false;
    final notifier = getNotifier(file);

    notifier.value = notifier.value.copyWith(
      status: PreProcessStatus.processing,
      progress: 0.1,
    );

    try {
      if (_cancelTokens[key] == true) return;

      notifier.value = notifier.value.copyWith(progress: 0.5);

      // Scale and encode through the shared processor rather than encoding the
      // raw file here. This used to produce a base64 string nobody read —
      // `AiService` encoded the original a second time when the request went
      // out — so the work was done twice and the larger of the two payloads
      // was the one actually uploaded. Now both sides share one cached result.
      final prepared =
          await MealImageProcessor.instance.prepareForAnalysis(file);
      if (_cancelTokens[key] == true) return;

      notifier.value = notifier.value.copyWith(
        status: PreProcessStatus.completed,
        progress: 1.0,
        base64Data: prepared.base64,
      );
    } catch (e) {
      if (_cancelTokens[key] == true) return;
      notifier.value = notifier.value.copyWith(
        status: PreProcessStatus.error,
        error: e.toString(),
      );
    }
  }
}

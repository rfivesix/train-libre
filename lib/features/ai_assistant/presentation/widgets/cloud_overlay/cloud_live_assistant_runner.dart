import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../application/assistant_chat_service.dart';
import '../../../data/assistant_history_repository.dart';
import 'cloud_loading_animation_controller.dart';

/// Manages submitting live AI assistant prompts, streaming token chunks, and data-access approvals.
class CloudLiveAssistantRunner {
  AssistantChatService? _assistant;
  StreamSubscription<String>? _liveResponseSubscription;
  Future<void>? _activeGenerationCancellation;

  AssistantChatService? get assistant => _assistant;
  Future<void>? get activeGenerationCancellation =>
      _activeGenerationCancellation;

  void setAssistant(AssistantChatService assistant) {
    _assistant = assistant;
  }

  Future<AssistantSubmission?> submitPrompt({
    required String prompt,
    required String? conversationId,
    required String locale,
    required DateTime now,
  }) async {
    final service = _assistant;
    if (service == null) return null;
    return service.submit(
      prompt,
      conversationId: conversationId,
      now: now,
      locale: locale,
    );
  }

  void streamBufferedAnswer({
    required String accessId,
    required String question,
    required String locale,
    required CloudLoadingAnimationController loadingCloud,
    required bool Function() isStillActive,
    required void Function(String text) onAppendText,
    required Future<bool> Function(AssistantAccessRecord access)
        onAdditionalAccess,
    required void Function(Object error) onError,
    required VoidCallback onDone,
  }) {
    final service = _assistant;
    if (service == null) return;

    cancelActiveResponseSubscription();

    final bufferedChunks = <String>[];
    var dismissingCloud = false;
    var streamDone = false;
    Object? streamError;

    Future<void> flushAfterCloudDismiss() async {
      if (dismissingCloud) return;
      dismissingCloud = true;
      try {
        await loadingCloud.hide();
      } finally {
        dismissingCloud = false;
      }
      if (!isStillActive()) return;

      if (bufferedChunks.isNotEmpty) {
        final combined = bufferedChunks.join();
        bufferedChunks.clear();
        onAppendText(combined);
      }
      if (streamError != null) {
        onError(streamError!);
      } else if (streamDone) {
        onDone();
      }
    }

    _liveResponseSubscription = service
        .approveAndAnswer(accessId, question,
            locale: locale, onAdditionalAccess: onAdditionalAccess)
        .listen(
      (chunk) {
        if (!isStillActive()) return;
        if (loadingCloud.isVisible || dismissingCloud) {
          bufferedChunks.add(chunk);
          unawaited(flushAfterCloudDismiss());
          return;
        }
        onAppendText(chunk);
      },
      onError: (Object error) {
        if (!isStillActive()) return;
        streamError = error;
        if (loadingCloud.isVisible || dismissingCloud) {
          unawaited(flushAfterCloudDismiss());
          return;
        }
        onError(error);
      },
      onDone: () {
        if (!isStillActive()) return;
        streamDone = true;
        if (loadingCloud.isVisible || dismissingCloud) {
          unawaited(flushAfterCloudDismiss());
          return;
        }
        onDone();
      },
    );
  }

  Future<AssistantMessage?> denyAccess({
    required String accessId,
    required String locale,
  }) async {
    final service = _assistant;
    if (service == null) return null;
    return service.deny(accessId, locale: locale);
  }

  void cancelActiveResponseSubscription() {
    final subscription = _liveResponseSubscription;
    _liveResponseSubscription = null;
    if (subscription != null) {
      _activeGenerationCancellation =
          subscription.cancel().catchError((Object _) {});
    }
  }

  void dispose() {
    cancelActiveResponseSubscription();
  }
}

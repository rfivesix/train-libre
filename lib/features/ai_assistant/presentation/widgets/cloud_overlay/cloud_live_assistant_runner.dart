import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../application/assistant_chat_service.dart';
import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_change_proposal.dart';
import '../../../domain/assistant_progress_status.dart';
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
    List<File> imageFiles = const [],
  }) async {
    final service = _assistant;
    if (service == null) return null;
    return service.submit(
      prompt,
      conversationId: conversationId,
      now: now,
      locale: locale,
      imageFiles: imageFiles,
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
    required void Function(AssistantProgressStatus status) onProgressStatus,
    required void Function(String messageId, AssistantChangeProposal proposal)
    onProposalAvailable,
    required void Function(Object error) onError,
    required VoidCallback onDone,
  }) {
    final service = _assistant;
    if (service == null) return;

    cancelActiveResponseSubscription();

    Future<void>? cloudHide;
    var streamDone = false;
    Object? streamError;
    var terminalCallbackPending = false;

    Future<void> hideCloud() =>
        cloudHide ??= loadingCloud.hide(waitForEnter: false);

    void finishAfterCloudHide(VoidCallback callback) {
      if (terminalCallbackPending) return;
      terminalCallbackPending = true;
      if (loadingCloud.isVisible || cloudHide != null) {
        unawaited(
          hideCloud().whenComplete(() {
            if (isStillActive()) callback();
          }),
        );
      } else {
        callback();
      }
    }

    _liveResponseSubscription = service
        .approveAndAnswer(
          accessId,
          question,
          locale: locale,
          onAdditionalAccess: onAdditionalAccess,
          onProgressStatus: onProgressStatus,
          onProposalAvailable: onProposalAvailable,
        )
        .listen(
          (chunk) {
            if (!isStillActive()) return;
            if (loadingCloud.isVisible && chunk.isNotEmpty) {
              // Start revealing the answer as soon as the model emits it. The
              // loading orb can reverse out while the streamed text appears.
              unawaited(hideCloud());
            }
            onAppendText(chunk);
          },
          onError: (Object error) {
            if (!isStillActive()) return;
            streamError = error;
            finishAfterCloudHide(() => onError(streamError!));
          },
          onDone: () {
            if (!isStillActive()) return;
            streamDone = true;
            finishAfterCloudHide(() {
              if (streamError != null) {
                onError(streamError!);
              } else if (streamDone) {
                onDone();
              }
            });
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

  Future<String?> resolveProposal({
    required String messageId,
    required bool approved,
    required String locale,
  }) async {
    final service = _assistant;
    if (service == null) return null;
    return service.resolveProposal(
      messageId,
      approved: approved,
      locale: locale,
    );
  }

  Future<bool> supersedeProposal(String messageId) async {
    final service = _assistant;
    if (service == null) return false;
    return service.supersedeProposal(messageId);
  }

  void cancelActiveResponseSubscription() {
    final subscription = _liveResponseSubscription;
    _liveResponseSubscription = null;
    if (subscription != null) {
      _activeGenerationCancellation = subscription.cancel().catchError(
        (Object _) {},
      );
    }
  }

  void dispose() {
    cancelActiveResponseSubscription();
  }
}

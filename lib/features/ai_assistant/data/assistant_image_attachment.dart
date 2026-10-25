import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/media/meal_image_processor.dart';

/// Local image attached to one persisted user message.
class AssistantMessageAttachment {
  const AssistantMessageAttachment({
    required this.id,
    required this.messageId,
    required this.filePath,
    required this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String filePath;
  final String mimeType;
  final DateTime createdAt;

  File get file => File(filePath);
}

/// Ready-to-send image bytes for the selected chat model.
class AssistantImagePayload {
  const AssistantImagePayload({required this.mimeType, required this.base64});

  final String mimeType;
  final String base64;
}

/// Owns private on-device copies for chat attachments and their provider payloads.
class AssistantImageAttachmentStore {
  AssistantImageAttachmentStore._();

  static final instance = AssistantImageAttachmentStore._();
  static const _uuid = Uuid();

  Future<List<({String filePath, String mimeType})>> persist(
    List<File> sources,
  ) async {
    if (sources.isEmpty) return const [];
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'assistant_attachments'));
    await directory.create(recursive: true);

    final saved = <({String filePath, String mimeType})>[];
    File? inProgress;
    try {
      for (final source in sources.take(4)) {
        if (!await source.exists()) {
          throw FileSystemException(
              'Chat image is no longer available', source.path);
        }
        final target = File(p.join(directory.path, '${_uuid.v4()}.jpg'));
        inProgress = target;
        final scaled = await MealImageProcessor.instance.downscale(
          sourcePath: source.path,
          targetPath: target.path,
          maxEdge: MealImageProcessor.storageMaxEdge,
          quality: MealImageProcessor.storageQuality,
        );
        if (!scaled) {
          final sourceMime = lookupMimeType(source.path) ?? 'image/jpeg';
          final extension = p.extension(source.path);
          final original = File(
            p.join(directory.path,
                '${p.basenameWithoutExtension(target.path)}$extension'),
          );
          if (await target.exists()) await target.delete();
          await source.copy(original.path);
          saved.add((filePath: original.path, mimeType: sourceMime));
          inProgress = null;
        } else {
          saved.add((filePath: target.path, mimeType: 'image/jpeg'));
          inProgress = null;
        }
      }
    } catch (_) {
      if (inProgress != null && await inProgress.exists()) {
        await inProgress.delete();
      }
      await deleteFiles([
        for (final item in saved)
          AssistantMessageAttachment(
            id: '',
            messageId: '',
            filePath: item.filePath,
            mimeType: item.mimeType,
            createdAt: DateTime.now(),
          ),
      ]);
      rethrow;
    }
    return saved;
  }

  Future<List<AssistantImagePayload>> prepare(
    Iterable<AssistantMessageAttachment> attachments,
  ) async {
    final payloads = <AssistantImagePayload>[];
    for (final attachment in attachments) {
      if (!await attachment.file.exists()) continue;
      final prepared =
          await MealImageProcessor.instance.prepareForAnalysis(attachment.file);
      payloads.add(AssistantImagePayload(
        mimeType: attachment.mimeType,
        base64: prepared.base64,
      ));
    }
    return payloads;
  }

  Future<void> deleteFiles(
      Iterable<AssistantMessageAttachment> attachments) async {
    for (final attachment in attachments) {
      try {
        final file = attachment.file;
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // A missing attachment must not block deleting its chat history.
      }
    }
  }
}

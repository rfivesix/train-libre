import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/media/app_media_store.dart';
import '../../../core/media/meal_image_processor.dart';
import '../../../data/drift_database.dart';

/// Local image attached to one persisted user message.
class AssistantMessageAttachment {
  const AssistantMessageAttachment({
    required this.id,
    required this.messageId,
    required this.filePath,
    this.thumbPath,
    required this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String filePath;
  final String? thumbPath;
  final String mimeType;
  final DateTime createdAt;

  File get file => _resolve(filePath);

  File? get previewFile => thumbPath == null ? null : _resolve(thumbPath!);

  /// Shows the full attachment when available and its backed-up preview after
  /// a restore that intentionally carried previews rather than original photos.
  File get displayFile {
    final original = file;
    if (original.existsSync()) return original;
    final preview = previewFile;
    return preview != null && preview.existsSync() ? preview : original;
  }

  static File _resolve(String path) =>
      AppMediaStore.instance.resolveSync(path) ?? File(path);
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

  Future<List<({String filePath, String? thumbPath, String mimeType})>> persist(
    List<File> sources,
  ) async {
    if (sources.isEmpty) return const [];
    final saved = <StoredMedia>[];
    try {
      for (final source in sources.take(4)) {
        if (!await source.exists()) {
          throw FileSystemException(
            'Chat image is no longer available',
            source.path,
          );
        }
        final media = await AppMediaStore.instance.save(
          source,
          domain: MediaDomain.assistantChats,
        );
        if (media == null) {
          throw FileSystemException('Could not save chat image', source.path);
        }
        saved.add(media);
      }
    } catch (_) {
      await AppMediaStore.instance.deleteAll([
        for (final item in saved) item.path,
      ]);
      rethrow;
    }
    return [
      for (var index = 0; index < saved.length; index++)
        (
          filePath: saved[index].path,
          thumbPath: saved[index].thumbPath,
          mimeType: lookupMimeType(saved[index].path) ?? 'image/jpeg',
        ),
    ];
  }

  Future<List<AssistantImagePayload>> prepare(
    Iterable<AssistantMessageAttachment> attachments,
  ) async {
    final payloads = <AssistantImagePayload>[];
    for (final attachment in attachments) {
      final file = attachment.displayFile;
      if (!await file.exists()) continue;
      final prepared = await MealImageProcessor.instance.prepareForAnalysis(
        file,
      );
      payloads.add(
        AssistantImagePayload(
          mimeType: attachment.mimeType,
          base64: prepared.base64,
        ),
      );
    }
    return payloads;
  }

  Future<void> deleteFiles(
    Iterable<AssistantMessageAttachment> attachments,
  ) async {
    await AppMediaStore.instance.deleteAll([
      for (final attachment in attachments) attachment.filePath,
      for (final attachment in attachments) attachment.thumbPath,
    ]);
  }

  /// Moves attachments written by older app versions out of their absolute
  /// container paths and creates a preview where the source is still present.
  /// Relative media paths survive app-container changes and are backup-safe.
  Future<void> ensureRelativeStorage(AppDatabase database) async {
    await AppMediaStore.instance.ensureInitialized();
    final rows = await database.customSelect('''
      SELECT id, file_path, thumb_path
      FROM assistant_message_attachments
    ''').get();
    for (final row in rows) {
      final id = row.read<String>('id');
      final storedPath = row.read<String>('file_path');
      final storedThumbPath = row.read<String?>('thumb_path');
      var existingFile =
          AppMediaStore.instance.resolveSync(storedPath) ?? File(storedPath);
      if (!await existingFile.exists() &&
          p.isAbsolute(storedPath) &&
          p.basename(p.dirname(storedPath)) == 'assistant_attachments') {
        final support = await getApplicationSupportDirectory();
        final legacyCandidate = File(
          p.join(support.path, 'assistant_attachments', p.basename(storedPath)),
        );
        if (await legacyCandidate.exists()) existingFile = legacyCandidate;
      }
      if (!await existingFile.exists()) {
        final fallbackThumbPath = storedThumbPath?.isNotEmpty == true
            ? storedThumbPath
            : AppMediaStore.thumbPathFor(storedPath);
        if (fallbackThumbPath == null) continue;
        final fallbackThumb = await AppMediaStore.instance.resolve(
          fallbackThumbPath,
        );
        if (fallbackThumb != null && await fallbackThumb.exists()) {
          await database.customStatement(
            'UPDATE assistant_message_attachments SET thumb_path = ? WHERE id = ?',
            [fallbackThumbPath, id],
          );
        }
        continue;
      }

      final alreadyInMediaStore =
          !p.isAbsolute(storedPath) &&
          p.isWithin(MediaDomain.assistantChats.folder, storedPath);
      if (alreadyInMediaStore) {
        var thumbPath = storedThumbPath;
        if (thumbPath == null || thumbPath.isEmpty) {
          thumbPath = AppMediaStore.thumbPathFor(storedPath);
        }
        if (thumbPath != null) {
          final thumbFile = await AppMediaStore.instance.resolve(thumbPath);
          if (thumbFile != null && !await thumbFile.exists()) {
            await MealImageProcessor.instance.downscale(
              sourcePath: existingFile.path,
              targetPath: thumbFile.path,
              maxEdge: MealImageProcessor.thumbMaxEdge,
              quality: MealImageProcessor.thumbQuality,
            );
          }
          await database.customStatement(
            'UPDATE assistant_message_attachments SET thumb_path = ? WHERE id = ?',
            [thumbPath, id],
          );
        }
        continue;
      }

      final media = await AppMediaStore.instance.save(
        existingFile,
        domain: MediaDomain.assistantChats,
      );
      if (media == null) continue;
      await database.customStatement(
        'UPDATE assistant_message_attachments SET file_path = ?, thumb_path = ? WHERE id = ?',
        [media.path, media.thumbPath, id],
      );
      try {
        await existingFile.delete();
      } on FileSystemException {
        // Keep the old source if cleanup fails; the new relative copy is active.
      }
    }
  }
}

import 'package:flutter/services.dart';

class SafPickedDirectory {
  const SafPickedDirectory({required this.treeUri, required this.displayPath});

  final String treeUri;
  final String displayPath;
}

class SafStorageService {
  SafStorageService._();

  static final SafStorageService instance = SafStorageService._();

  static const MethodChannel _channel = MethodChannel('trainlibre.storage/saf');

  Future<SafPickedDirectory?> pickDirectory() async {
    final raw = await _channel.invokeMethod<dynamic>('pickDirectory');
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final treeUri = (map['treeUri'] as String?)?.trim();
    final displayPath = (map['displayPath'] as String?)?.trim();
    if (treeUri == null ||
        treeUri.isEmpty ||
        displayPath == null ||
        displayPath.isEmpty) {
      return null;
    }
    return SafPickedDirectory(treeUri: treeUri, displayPath: displayPath);
  }

  /// Copies the local file at [sourcePath] into the picked tree.
  ///
  /// Takes a path rather than the bytes: an auto-backup archive carries the
  /// meal previews and can run to tens of megabytes, and pushing that through
  /// the method channel would copy it twice in memory for no reason.
  Future<String?> writeFileToTree({
    required String treeUri,
    required String fileName,
    required String sourcePath,
    String mimeType = 'application/zip',
  }) async {
    final raw = await _channel.invokeMethod<dynamic>(
      'writeFileToTree',
      <String, dynamic>{
        'treeUri': treeUri,
        'fileName': fileName,
        'sourcePath': sourcePath,
        'mimeType': mimeType,
      },
    );
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return map['displayPath'] as String?;
  }

  Future<void> pruneAutoBackupsInTree({
    required String treeUri,
    required String filePrefix,
    required int retention,
  }) async {
    await _channel.invokeMethod<dynamic>(
      'pruneAutoBackupsInTree',
      <String, dynamic>{
        'treeUri': treeUri,
        'filePrefix': filePrefix,
        'retention': retention,
      },
    );
  }
}

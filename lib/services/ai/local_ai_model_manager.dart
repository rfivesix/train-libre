import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a curated on-device local vision model.
class LocalAiModelDefinition {
  final String id;
  final String name;
  final String tag;
  final String description;
  final int sizeBytes;
  final String fileName;
  final String downloadUrl;
  final String? mmprojFileName;
  final String? mmprojDownloadUrl;
  final int mmprojSizeBytes;
  final bool isRecommended;

  const LocalAiModelDefinition({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.sizeBytes,
    required this.fileName,
    required this.downloadUrl,
    this.mmprojFileName,
    this.mmprojDownloadUrl,
    this.mmprojSizeBytes = 0,
    this.isRecommended = false,
  });

  String get formattedSize {
    final total = sizeBytes + mmprojSizeBytes;
    final gb = total / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }
}

/// Download state for a model.
class LocalModelDownloadState {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;

  const LocalModelDownloadState({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });
}

/// Manages local AI model files, downloads from Hugging Face, deletion, and selection.
class LocalAiModelManager extends ChangeNotifier {
  LocalAiModelManager._();
  static final LocalAiModelManager instance = LocalAiModelManager._();

  static const String _prefSelectedModelKey = 'local_ai_selected_model';

  /// Curated models available for on-device execution.
  static const List<LocalAiModelDefinition> availableModels = [
    LocalAiModelDefinition(
      id: 'qwen-3-vl-4b',
      name: 'Qwen-3-VL (4B)',
      tag: 'Empfohlen · Vision',
      description:
          'Alibaba Qwen-3 Vision (4B) – Höchste Präzision bei Nährwerten, Zutaten und Portionsgrößen.',
      sizeBytes: 2497281664, // ~2.33 GB
      fileName: 'Qwen3VL-4B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct-GGUF/resolve/main/Qwen3VL-4B-Instruct-Q4_K_M.gguf',
      mmprojFileName: 'mmproj-Qwen3VL-4B-Instruct-Q8_0.gguf',
      mmprojDownloadUrl:
          'https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-4B-Instruct-Q8_0.gguf',
      mmprojSizeBytes: 453974304, // ~433 MB
      isRecommended: true,
    ),
    LocalAiModelDefinition(
      id: 'qwen-2.5-vl-3b',
      name: 'Qwen-2.5-VL (3B)',
      tag: 'Kompakt · Vision',
      description:
          'Alibaba Qwen-2.5 Vision (3B) – Sehr schnell und ressourcensparend auf mobilen Geräten.',
      sizeBytes: 1929901056, // ~1.80 GB
      fileName: 'Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf',
      mmprojFileName: 'mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf',
      mmprojDownloadUrl:
          'https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf',
      mmprojSizeBytes: 844757728, // ~805 MB
    ),
    LocalAiModelDefinition(
      id: 'smolvlm-2.2b',
      name: 'SmolVLM (2.2B)',
      tag: 'Leichtgewicht',
      description:
          'Hugging Face SmolVLM – Extrem geringer Speicher- und RAM-Bedarf für schnelle Scans.',
      sizeBytes: 1112602656, // ~1.04 GB
      fileName: 'SmolVLM2-2.2B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/SmolVLM2-2.2B-Instruct-Q4_K_M.gguf',
      mmprojFileName: 'mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf',
      mmprojDownloadUrl:
          'https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf',
      mmprojSizeBytes: 592523200, // ~565 MB
    ),
  ];

  final Map<String, LocalModelDownloadState> _downloadStates = {};
  final Map<String, HttpClientRequest> _activeRequests = {};
  final Map<String, HttpClient> _activeClients = {};
  final Set<String> _cancelledModelIds = {};
  final Set<String> _downloadedModelIds = {};
  bool _initialized = false;
  String _selectedModelId = 'qwen-3-vl-4b';

  bool get isInitialized => _initialized;
  String get selectedModelId => _selectedModelId;

  LocalAiModelDefinition get selectedModel {
    return availableModels.firstWhere(
      (m) => m.id == _selectedModelId,
      orElse: () => availableModels.first,
    );
  }

  LocalModelDownloadState? getDownloadState(String modelId) =>
      _downloadStates[modelId];

  bool isDownloading(String modelId) => _downloadStates.containsKey(modelId);

  bool isDownloaded(String modelId) => _downloadedModelIds.contains(modelId);

  /// Checks whether the model files actually exist on disk and meet size criteria.
  Future<bool> ensureDownloaded(String modelId) async {
    await _refreshDownloadedModels();
    return isDownloaded(modelId);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedModelId =
          prefs.getString(_prefSelectedModelKey) ?? 'qwen-3-vl-4b';

      await _refreshDownloadedModels();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[LocalAiModelManager] Initialization error: $e');
    }
  }

  Future<Directory> _getModelDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final modelDir = Directory('${baseDir.path}/local_ai_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  Future<File> getModelFile(String modelId) async {
    final def = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => availableModels.first,
    );
    final dir = await _getModelDirectory();
    return File('${dir.path}/${def.fileName}');
  }

  Future<File?> getProjectorFile(String modelId) async {
    final def = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => availableModels.first,
    );
    if (def.mmprojFileName == null) return null;
    final dir = await _getModelDirectory();
    return File('${dir.path}/${def.mmprojFileName}');
  }

  Future<void> _refreshDownloadedModels() async {
    _downloadedModelIds.clear();
    for (final model in availableModels) {
      final file = await getModelFile(model.id);
      final hasBase = await file.exists() && await file.length() > 1024 * 1024;
      if (!hasBase) continue;

      if (model.mmprojFileName != null) {
        final proj = await getProjectorFile(model.id);
        final hasProj =
            proj != null && await proj.exists() && await proj.length() > 1024 * 1024;
        if (hasProj) {
          _downloadedModelIds.add(model.id);
        }
      } else {
        _downloadedModelIds.add(model.id);
      }
    }
  }

  Future<void> selectModel(String modelId) async {
    _selectedModelId = modelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSelectedModelKey, modelId);
    notifyListeners();
  }

  /// Downloads a single file via streaming HTTP, updating progress.
  Future<bool> _downloadFile({
    required HttpClient client,
    required String modelId,
    required String downloadUrl,
    required String targetFileName,
    required int fileExpectedBytes,
    required int previouslyReceivedBytes,
    required int totalCombinedBytes,
  }) async {
    final dir = await _getModelDirectory();
    final tempFile = File('${dir.path}/$targetFileName.tmp');
    final finalFile = File('${dir.path}/$targetFileName');

    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    IOSink? sink;
    try {
      final uri = Uri.parse(downloadUrl);
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;
      _activeRequests[modelId] = request;

      final response = await request.close();
      if (_cancelledModelIds.contains(modelId)) return false;

      if (response.statusCode != 200) {
        throw HttpException('HTTP status ${response.statusCode} for $downloadUrl');
      }

      var fileReceived = 0;
      sink = tempFile.openWrite();

      await for (final chunk in response) {
        if (_cancelledModelIds.contains(modelId)) break;
        sink.add(chunk);
        fileReceived += chunk.length;
        final totalReceived = previouslyReceivedBytes + fileReceived;
        _downloadStates[modelId] = LocalModelDownloadState(
          progress: (totalReceived / totalCombinedBytes).clamp(0.0, 1.0),
          receivedBytes: totalReceived,
          totalBytes: totalCombinedBytes,
        );
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (_cancelledModelIds.contains(modelId)) {
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
        return false;
      }

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);
      return true;
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Starts downloading the model (and its vision projector if present).
  Future<bool> startDownload(String modelId) async {
    if (isDownloading(modelId)) return false;

    final def = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ArgumentError('Model $modelId not found'),
    );

    final totalCombinedBytes = def.sizeBytes + def.mmprojSizeBytes;
    final client = HttpClient();
    client.autoUncompress = true;
    client.userAgent = 'TrainLibre/1.5 (Mobile; On-Device-AI)';
    _activeClients[modelId] = client;
    _cancelledModelIds.remove(modelId);

    try {
      _downloadStates[modelId] = LocalModelDownloadState(
        progress: 0.0,
        receivedBytes: 0,
        totalBytes: totalCombinedBytes,
      );
      notifyListeners();

      // Stage 1: Download Base Model GGUF
      final baseSuccess = await _downloadFile(
        client: client,
        modelId: modelId,
        downloadUrl: def.downloadUrl,
        targetFileName: def.fileName,
        fileExpectedBytes: def.sizeBytes,
        previouslyReceivedBytes: 0,
        totalCombinedBytes: totalCombinedBytes,
      );

      if (!baseSuccess || _cancelledModelIds.contains(modelId)) {
        _cleanupCancelled(modelId, def);
        return false;
      }

      // Stage 2: Download Vision Projector GGUF (if model has mmproj)
      if (def.mmprojDownloadUrl != null && def.mmprojFileName != null) {
        final projSuccess = await _downloadFile(
          client: client,
          modelId: modelId,
          downloadUrl: def.mmprojDownloadUrl!,
          targetFileName: def.mmprojFileName!,
          fileExpectedBytes: def.mmprojSizeBytes,
          previouslyReceivedBytes: def.sizeBytes,
          totalCombinedBytes: totalCombinedBytes,
        );

        if (!projSuccess || _cancelledModelIds.contains(modelId)) {
          _cleanupCancelled(modelId, def);
          return false;
        }
      }

      _downloadStates.remove(modelId);
      _activeRequests.remove(modelId);
      _activeClients.remove(modelId);
      _downloadedModelIds.add(modelId);
      notifyListeners();
      return true;
    } catch (e) {
      _cleanupCancelled(modelId, def);
      debugPrint('[LocalAiModelManager] Download error for $modelId: $e');
      if (_cancelledModelIds.contains(modelId)) {
        return false;
      }
      rethrow;
    } finally {
      try {
        client.close(force: true);
      } catch (_) {}
      _activeClients.remove(modelId);
    }
  }

  void _cleanupCancelled(String modelId, LocalAiModelDefinition def) async {
    _downloadStates.remove(modelId);
    _activeRequests.remove(modelId);
    _activeClients.remove(modelId);
    _cancelledModelIds.remove(modelId);
    try {
      final dir = await _getModelDirectory();
      final baseTmp = File('${dir.path}/${def.fileName}.tmp');
      if (await baseTmp.exists()) await baseTmp.delete();
      if (def.mmprojFileName != null) {
        final projTmp = File('${dir.path}/${def.mmprojFileName}.tmp');
        if (await projTmp.exists()) await projTmp.delete();
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Cancels an in-progress download and cleans up temporary files immediately.
  Future<void> cancelDownload(String modelId) async {
    _cancelledModelIds.add(modelId);
    _downloadStates.remove(modelId);
    notifyListeners();

    final req = _activeRequests.remove(modelId);
    req?.abort();

    final client = _activeClients.remove(modelId);
    try {
      client?.close(force: true);
    } catch (_) {}

    try {
      final def = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await _getModelDirectory();
      final baseTmp = File('${dir.path}/${def.fileName}.tmp');
      if (await baseTmp.exists()) await baseTmp.delete();
      if (def.mmprojFileName != null) {
        final projTmp = File('${dir.path}/${def.mmprojFileName}.tmp');
        if (await projTmp.exists()) await projTmp.delete();
      }
    } catch (_) {}

    notifyListeners();
  }

  /// Deletes a downloaded model to immediately free up device storage.
  Future<void> deleteModel(String modelId) async {
    try {
      final file = await getModelFile(modelId);
      if (await file.exists()) {
        await file.delete();
      }
      final proj = await getProjectorFile(modelId);
      if (proj != null && await proj.exists()) {
        await proj.delete();
      }
      _downloadedModelIds.remove(modelId);
      notifyListeners();
    } catch (e) {
      debugPrint('[LocalAiModelManager] Deletion error for $modelId: $e');
      rethrow;
    }
  }

  /// Computes the total storage used by all downloaded models.
  Future<int> getTotalLocalStorageBytes() async {
    int total = 0;
    for (final model in availableModels) {
      final file = await getModelFile(model.id);
      if (await file.exists()) {
        total += await file.length();
      }
      final proj = await getProjectorFile(model.id);
      if (proj != null && await proj.exists()) {
        total += await proj.length();
      }
    }
    return total;
  }
}


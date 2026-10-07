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
  final bool isRecommended;

  const LocalAiModelDefinition({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.sizeBytes,
    required this.fileName,
    required this.downloadUrl,
    this.isRecommended = false,
  });

  String get formattedSize {
    final gb = sizeBytes / (1024 * 1024 * 1024);
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
      sizeBytes: 2576980377, // ~2.58 GB
      fileName: 'qwen-3-vl-4b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct-GGUF/resolve/main/qwen-3-vl-4b-instruct-q4_k_m.gguf',
      isRecommended: true,
    ),
    LocalAiModelDefinition(
      id: 'qwen-2.5-vl-3b',
      name: 'Qwen-2.5-VL (3B)',
      tag: 'Kompakt · Vision',
      description:
          'Alibaba Qwen-2.5 Vision (3B) – Sehr schnell und ressourcensparend auf mobilen Geräten.',
      sizeBytes: 2040109465, // ~2.04 GB
      fileName: 'qwen2.5-vl-3b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/qwen2.5-vl-3b-instruct-q4_k_m.gguf',
    ),
    LocalAiModelDefinition(
      id: 'smolvlm-2.2b',
      name: 'SmolVLM (2.2B)',
      tag: 'Leichtgewicht',
      description:
          'Hugging Face SmolVLM – Extrem geringer Speicher- und RAM-Bedarf für schnelle Scans.',
      sizeBytes: 1503238553, // ~1.50 GB
      fileName: 'smolvlm-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/HuggingFaceTB/SmolVLM-Instruct-GGUF/resolve/main/smolvlm-instruct-q4_k_m.gguf',
    ),
  ];

  final Map<String, LocalModelDownloadState> _downloadStates = {};
  final Map<String, HttpClientRequest> _activeRequests = {};
  final Set<String> _downloadedModelIds = {};
  bool _initialized = false;
  String _selectedModelId = 'qwen-3-vl-4b';

  bool get isInitialized => _initialized;
  String get selectedModelId => _selectedModelId;

  LocalModelDownloadState? getDownloadState(String modelId) =>
      _downloadStates[modelId];

  bool isDownloading(String modelId) => _downloadStates.containsKey(modelId);

  bool isDownloaded(String modelId) => _downloadedModelIds.contains(modelId);

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

  Future<void> _refreshDownloadedModels() async {
    _downloadedModelIds.clear();
    for (final model in availableModels) {
      final file = await getModelFile(model.id);
      if (await file.exists() && await file.length() > 1024 * 1024) {
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

  /// Starts downloading the model from Hugging Face.
  Future<void> startDownload(String modelId) async {
    if (isDownloading(modelId)) return;

    final def = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ArgumentError('Model $modelId not found'),
    );

    final dir = await _getModelDirectory();
    final tempFile = File('${dir.path}/${def.fileName}.tmp');
    final finalFile = File('${dir.path}/${def.fileName}');

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = HttpClient();
    client.autoUncompress = true;

    try {
      _downloadStates[modelId] = LocalModelDownloadState(
        progress: 0.0,
        receivedBytes: 0,
        totalBytes: def.sizeBytes,
      );
      notifyListeners();

      final uri = Uri.parse(def.downloadUrl);
      final request = await client.getUrl(uri);
      _activeRequests[modelId] = request;

      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP status ${response.statusCode}');
      }

      final contentLength = response.contentLength > 0
          ? response.contentLength
          : def.sizeBytes;
      var received = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        _downloadStates[modelId] = LocalModelDownloadState(
          progress: (received / contentLength).clamp(0.0, 1.0),
          receivedBytes: received,
          totalBytes: contentLength,
        );
        notifyListeners();
      }

      await sink.flush();
      await sink.close();

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      _downloadStates.remove(modelId);
      _activeRequests.remove(modelId);
      _downloadedModelIds.add(modelId);
      notifyListeners();
    } catch (e) {
      _downloadStates.remove(modelId);
      _activeRequests.remove(modelId);
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      notifyListeners();
      debugPrint('[LocalAiModelManager] Download error for $modelId: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Cancels an in-progress download and cleans up temporary files.
  Future<void> cancelDownload(String modelId) async {
    final req = _activeRequests.remove(modelId);
    req?.abort();
    _downloadStates.remove(modelId);

    try {
      final def = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await _getModelDirectory();
      final tempFile = File('${dir.path}/${def.fileName}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
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
    }
    return total;
  }
}

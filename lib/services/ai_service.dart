// lib/services/ai_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/media/meal_image_processor.dart';
import 'ai_meal_validation.dart';
import 'ai_meal_context.dart';
import 'ai_matching_language_service.dart';
import 'package:uuid/uuid.dart';
import 'telemetry/telemetry_service.dart';
import 'telemetry/telemetry_buckets.dart';
import '../features/depth_scan/domain/models/depth_scale_facts.dart';

part 'ai/ai_models.dart';
part 'ai/ai_prompts.dart';
part 'ai/ai_network.dart';
part 'ai/ai_parsing.dart';

typedef DynamicModelIdsLoader = Future<Set<String>?> Function(
  AiProvider provider,
);
typedef AiHttpGet = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

/// Provider-agnostic AI service for meal analysis.
///
/// Uses a BYOK architecture with per-provider API keys stored in native
/// encrypted storage (Keychain / Keystore) via [FlutterSecureStorage].
class AiService {
  AiService._({
    FlutterSecureStorage? secureStorage,
    DynamicModelIdsLoader? dynamicModelIdsLoader,
    AiHttpGet? httpGet,
  })  : _secureStorage = secureStorage ?? deviceOnlySecureStorage,
        _dynamicModelIdsLoader = dynamicModelIdsLoader,
        _httpGet = httpGet ?? http.get;
  static final AiService instance = AiService._();

  @visibleForTesting
  factory AiService.forTesting({
    FlutterSecureStorage? secureStorage,
    DynamicModelIdsLoader? dynamicModelIdsLoader,
    AiHttpGet? httpGet,
  }) {
    return AiService._(
      secureStorage: secureStorage,
      dynamicModelIdsLoader: dynamicModelIdsLoader,
      httpGet: httpGet,
    );
  }

  final FlutterSecureStorage _secureStorage;
  final DynamicModelIdsLoader? _dynamicModelIdsLoader;
  final AiHttpGet _httpGet;

  /// Keychain items default to `kSecAttrAccessibleWhenUnlocked`, which Apple
  /// copies into device and iCloud backups and restores onto whatever device
  /// the backup is applied to. BYOK credentials must not travel that way, so
  /// everything this service stores is written `…ThisDeviceOnly`.
  ///
  /// Anything reading or deleting these items must use the same options —
  /// `kSecAttrAccessible` is part of the keychain lookup query, so a mismatch
  /// silently finds nothing.
  static const IOSOptions deviceOnlyIosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );
  static const MacOsOptions deviceOnlyMacOsOptions = MacOsOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  static const FlutterSecureStorage deviceOnlySecureStorage =
      FlutterSecureStorage(
    iOptions: deviceOnlyIosOptions,
    mOptions: deviceOnlyMacOsOptions,
  );

  /// The options items were stored with before [deviceOnlySecureStorage]; kept
  /// so [migrateSecureStorageToDeviceOnly] can find and move them.
  static const FlutterSecureStorage _legacySecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(),
    mOptions: MacOsOptions(),
  );

  // Secure storage keys per provider
  static const _keyPrefix = 'ai_api_key_';
  static const _providerKey = 'ai_selected_provider';
  static const _modelPrefix = 'ai_selected_model_';
  static const _customBaseUrlKey = 'ai_custom_base_url';
  static const _customModelKey = 'ai_custom_model';
  static const _timeoutKey = 'ai_timeout_seconds';

  static const selectedProviderStorageKey = _providerKey;

  static String selectedModelStorageKeyFor(AiProvider provider) =>
      '$_modelPrefix${provider.name}';

  static String apiKeyStorageKeyFor(AiProvider provider) =>
      '$_keyPrefix${provider.name}';

  static const Map<AiProvider, AiProviderMetadata> _providerRegistry = {
    AiProvider.openai: AiProviderMetadata(
      provider: AiProvider.openai,
      displayName: 'OpenAI',
      keyHint: 'sk-...',
      defaultModel: 'gpt-5.4',
      rankingHints: [
        'gpt-5.4',
        'gpt-5.4-pro',
        'gpt-5.4-mini',
        'gpt-5.4-nano',
        'gpt-5-mini',
        'gpt-5',
        'gpt-4.1',
        'gpt-4o',
      ],
      emergencyFallbackModels: [
        'gpt-5.4',
        'gpt-5.4-mini',
        'gpt-4.1',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.gemini: AiProviderMetadata(
      provider: AiProvider.gemini,
      displayName: 'Google Gemini',
      keyHint: 'AIza...',
      defaultModel: 'gemini-pro-latest',
      rankingHints: [
        'gemini-pro-latest',
        'gemini-flash-latest',
        'gemini-flash-lite-latest',
        'gemini-2.5-pro',
        'gemini-2.5-flash',
      ],
      emergencyFallbackModels: [
        'gemini-pro-latest',
        'gemini-flash-latest',
        'gemini-2.5-flash',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.anthropic: AiProviderMetadata(
      provider: AiProvider.anthropic,
      displayName: 'Anthropic Claude',
      keyHint: 'sk-ant-...',
      defaultModel: 'claude-opus-4-6',
      rankingHints: [
        'claude-opus-4-6',
        'claude-sonnet-4-6',
        'claude-haiku-4-5',
      ],
      emergencyFallbackModels: [
        'claude-opus-4-6',
        'claude-sonnet-4-6',
        'claude-3-7-sonnet-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.mistral: AiProviderMetadata(
      provider: AiProvider.mistral,
      displayName: 'Mistral',
      keyHint: 'mistral-...',
      defaultModel: 'mistral-large-3',
      rankingHints: [
        'mistral-large-3',
        'mistral-medium-3.1',
        'mistral-small-4',
        'pixtral-large-latest',
      ],
      emergencyFallbackModels: [
        'mistral-large-3',
        'mistral-medium-3.1',
        'pixtral-large-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.xai: AiProviderMetadata(
      provider: AiProvider.xai,
      displayName: 'xAI Grok',
      keyHint: 'xai-...',
      defaultModel: 'grok-4.20-0309-reasoning',
      rankingHints: [
        'grok-4.20-0309-reasoning',
        'grok-4.20-0309-non-reasoning',
        'grok-4-1-fast-reasoning',
        'grok-4-1-fast-non-reasoning',
      ],
      emergencyFallbackModels: [
        'grok-4.20-0309-reasoning',
        'grok-4-1-fast-reasoning',
        'grok-2-vision-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.ollama: AiProviderMetadata(
      provider: AiProvider.ollama,
      displayName: 'Ollama',
      keyHint: 'Not required',
      defaultModel: 'llama3',
      rankingHints: [
        'llama3',
        'llava',
        'mistral',
        'phi3',
      ],
      emergencyFallbackModels: [
        'llama3',
        'llava',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: false,
    ),
    AiProvider.custom: AiProviderMetadata(
      provider: AiProvider.custom,
      displayName: 'Custom OpenAI Compatible',
      keyHint: 'API Key (if required)',
      defaultModel: 'custom-model',
      rankingHints: [],
      emergencyFallbackModels: [
        'custom-model',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: false,
    ),
  };

  // ---------------------------------------------------------------------------
  // Custom Provider Fields (Ollama & Custom BaseURL / Custom Model)
  // ---------------------------------------------------------------------------

  /// Reads the custom base URL.
  Future<String?> getCustomBaseUrl() async {
    return _secureStorage.read(key: _customBaseUrlKey);
  }

  /// Stores the custom base URL.
  Future<void> setCustomBaseUrl(String? url) async {
    if (url == null) {
      await _secureStorage.delete(key: _customBaseUrlKey);
    } else {
      await _secureStorage.write(key: _customBaseUrlKey, value: url);
    }
  }

  /// Reads the custom model name.
  Future<String?> getCustomModel() async {
    return _secureStorage.read(key: _customModelKey);
  }

  /// Stores the custom model name.
  Future<void> setCustomModel(String? model) async {
    if (model == null) {
      await _secureStorage.delete(key: _customModelKey);
    } else {
      await _secureStorage.write(key: _customModelKey, value: model);
    }
  }

  /// Reads the AI request timeout in seconds.
  Future<int> getAiTimeoutSeconds() async {
    final value = await _secureStorage.read(key: _timeoutKey);
    if (value == null || value.isEmpty) return 60;
    return int.tryParse(value) ?? 60;
  }

  /// Stores the AI request timeout in seconds.
  Future<void> setAiTimeoutSeconds(int seconds) async {
    await _secureStorage.write(key: _timeoutKey, value: seconds.toString());
  }

  // ---------------------------------------------------------------------------
  // Key Management
  // ---------------------------------------------------------------------------

  /// Every key this service owns, used by the device-only migration.
  static List<String> get _allStorageKeys => [
        for (final provider in AiProvider.values) apiKeyStorageKeyFor(provider),
        for (final provider in AiProvider.values)
          selectedModelStorageKeyFor(provider),
        _providerKey,
        _customBaseUrlKey,
        _customModelKey,
        _timeoutKey,
      ];

  /// Moves keychain items written before [deviceOnlyAppleOptions] existed onto
  /// the device-only accessibility class, so they stop being included in iOS
  /// device and iCloud backups.
  ///
  /// Runs once per install and is a no-op on non-Apple platforms and on fresh
  /// installs. Each item is deleted before being rewritten: `SecItemAdd`
  /// rejects a duplicate service/account pair, and the plugin's delete ignores
  /// the accessibility attribute, so it removes the backup-eligible item that
  /// the new-options read cannot see.
  static Future<void> migrateSecureStorageToDeviceOnly() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    final prefs = await SharedPreferences.getInstance();
    const migrationFlag = 'ai_secure_storage_device_only_v1';
    if (prefs.getBool(migrationFlag) ?? false) return;

    for (final key in _allStorageKeys) {
      try {
        final legacyValue = await _legacySecureStorage.read(key: key);
        if (legacyValue == null) continue;
        await _legacySecureStorage.delete(key: key);
        await deviceOnlySecureStorage.write(key: key, value: legacyValue);
      } catch (e) {
        debugPrint('Device-only keychain migration failed for $key: $e');
        return; // Retry on the next launch rather than half-migrating.
      }
    }

    await prefs.setBool(migrationFlag, true);
  }

  /// Reads the stored API key for the given [provider].
  Future<String?> getApiKey(AiProvider provider) async {
    return _secureStorage.read(key: apiKeyStorageKeyFor(provider));
  }

  /// Stores the API key for the given [provider] securely.
  Future<void> setApiKey(AiProvider provider, String key) async {
    await _secureStorage.write(key: apiKeyStorageKeyFor(provider), value: key);
  }

  /// Deletes the stored API key for the given [provider].
  Future<void> deleteApiKey(AiProvider provider) async {
    await _secureStorage.delete(key: apiKeyStorageKeyFor(provider));
  }

  List<AiProviderMetadata> getSupportedProviders() =>
      _providerRegistry.values.toList(growable: false);

  AiProviderMetadata getProviderMetadata(AiProvider provider) =>
      _providerRegistry[provider]!;

  /// Returns the currently selected provider (default: OpenAI).
  Future<AiProvider> getSelectedProvider() async {
    final value = await _secureStorage.read(key: _providerKey);
    if (value == null || value.isEmpty) return AiProvider.openai;
    for (final provider in AiProvider.values) {
      if (provider.name == value) return provider;
    }
    return AiProvider.openai;
  }

  /// Persists the selected provider.
  Future<void> setSelectedProvider(AiProvider provider) async {
    await _secureStorage.write(key: _providerKey, value: provider.name);
  }

  Future<String> getSelectedModel(AiProvider provider) async {
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      final customModel = await getCustomModel();
      if (customModel != null && customModel.isNotEmpty) return customModel;
      return getProviderMetadata(provider).defaultModel;
    }
    final selected = await _secureStorage.read(
      key: selectedModelStorageKeyFor(provider),
    );
    final meta = getProviderMetadata(provider);
    if (selected == null || selected.isEmpty) return meta.defaultModel;
    return selected;
  }

  Future<void> setSelectedModel(AiProvider provider, String model) async {
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      await setCustomModel(model);
      return;
    }
    final resolvedModel = switch (provider) {
      AiProvider.openai => _normalizeOpenAiModelId(model),
      AiProvider.gemini => _normalizeGeminiModelId(model),
      _ => model,
    };
    await _secureStorage.write(
      key: selectedModelStorageKeyFor(provider),
      value: resolvedModel,
    );
  }

  /// How many live models the picker shows at most.
  ///
  /// A cap is still worth having — a provider that ever returns hundreds of
  /// ids would turn the dropdown into a wall — but the old value of 10 was
  /// small enough that the ranking had to be right or a model became
  /// *unreachable*. After the modality filter OpenAI returns roughly 20-40
  /// chat-capable ids, so 50 shows all of them today while keeping a bound on
  /// a pathological response. Ranking now only decides the order you scroll
  /// in, not what exists.
  static const int maxModelOptions = 50;

  /// The model list plus the reason it may be a fallback.
  ///
  /// Prefer this over [getModelOptions] wherever the user can see the result:
  /// it carries [AiModelListResult.error], which is the difference between
  /// "your key is wrong" and "this provider only has three models".
  Future<AiModelListResult> loadModelOptions(AiProvider provider) async {
    // Live provider model APIs are the primary source of truth.
    // Hardcoded metadata is used only for family/ranking hints + tiny fallback.
    final fetch = await _loadDynamicModelIds(provider);
    final dynamicIds = fetch.ids;
    if (dynamicIds != null && dynamicIds.isNotEmpty) {
      final ranked = _rankProviderModels(
        provider: provider,
        dynamicModels: dynamicIds.toList(growable: false),
      );
      final capped = ranked.take(maxModelOptions).toList(growable: false);
      if (capped.isNotEmpty) {
        return AiModelListResult(
          options: capped
              .map((m) => AiModelOption(id: m, label: m))
              .toList(growable: false),
          isFallback: false,
        );
      }
    }

    // A 200 whose list came back empty is its own failure: everything was
    // filtered away, or the provider answered with nothing.
    final error =
        fetch.error ?? const AiModelListError(AiModelListErrorKind.response);
    if (kDebugMode && !error.isBenign) {
      debugPrint(
        'AiService: falling back to the built-in model list for '
        '${provider.name} — $error',
      );
    }

    // Emergency fallback only: keep this small and intentionally conservative.
    final fallback = _safeEmergencyFallback(provider);
    return AiModelListResult(
      options: fallback
          .map(
            (m) => AiModelOption(
              id: m,
              label: m,
              isFallback: true,
            ),
          )
          .toList(growable: false),
      isFallback: true,
      error: error,
    );
  }

  Future<List<AiModelOption>> getModelOptions(AiProvider provider) async {
    return (await loadModelOptions(provider)).options;
  }

  /// Resolves persisted model selection against the final allowed model list
  /// (dynamic if available, otherwise emergency fallback) and auto-heals storage.
  Future<String> resolveAndPersistSelectedModel(AiProvider provider) async {
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      return getSelectedModel(provider);
    }
    final options = await getModelOptions(provider);
    final selected = await getSelectedModel(provider);
    if (options.isNotEmpty && options.any((m) => m.id == selected)) {
      return selected;
    }
    final meta = getProviderMetadata(provider);
    final resolved = options.isNotEmpty ? options.first.id : meta.defaultModel;
    await setSelectedModel(provider, resolved);
    return resolved;
  }

  List<String> _safeEmergencyFallback(AiProvider provider) {
    final meta = getProviderMetadata(provider);
    final fallback = meta.emergencyFallbackModels;
    if (fallback.isEmpty) return [meta.defaultModel];
    return fallback;
  }

  List<String> _rankProviderModels({
    required AiProvider provider,
    required List<String> dynamicModels,
  }) {
    final uniqueModels = dynamicModels.toSet().toList(growable: false);
    uniqueModels.sort((a, b) {
      final scoreA = _providerModelScore(provider, a);
      final scoreB = _providerModelScore(provider, b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      // tie-break: lexical descending tends to keep newer semantic/date variants first
      return b.compareTo(a);
    });

    return uniqueModels;
  }

  /// Orders one model id against its siblings without knowing a single model
  /// name.
  ///
  /// The previous version handed fixed bonuses to literal ids (`gpt-5.4`,
  /// `gpt-5.4-pro`, …). Those are stale on the morning of the next release:
  /// the new flagship scores below the model it replaces and, with a short
  /// list, drops off the end of the picker entirely. So the score is built
  /// from three signals that age on their own:
  ///
  ///  1. **Version** (weight 10000) — the family version parsed out of the id.
  ///     Dominant, so a newer generation always outranks an older one no
  ///     matter what it is called.
  ///  2. **Capability tier** (weight 100) — `pro`/`large`/`opus` above the
  ///     plain name above `mini`/`nano`. Vocabulary that has survived every
  ///     naming change so far across all five providers.
  ///  3. **Staleness penalties** — dated snapshots, `preview`, `legacy`,
  ///     `deprecated`.
  ///
  /// [AiProviderMetadata.rankingHints] survives only as a last tiebreak
  /// (weight < 100), so it can order equals but can never hold a newer model
  /// down.
  int _providerModelScore(AiProvider provider, String modelId) {
    final id = modelId.toLowerCase();

    var score = (_modelVersionValue(id) * 10000).round();
    score += _modelTierScore(id) * 100;

    // Tiebreak only: a curated preference among models of the same generation
    // and tier. Deliberately smaller than one tier step.
    final hints = getProviderMetadata(provider).rankingHints;
    final hintIndex = hints.indexWhere((h) => h.toLowerCase() == id);
    if (hintIndex != -1) {
      score += 60 - (hintIndex * 2).clamp(0, 50);
    }

    // Pinned snapshots duplicate a rolling id that is already in the list.
    if (_looksLikeDatedSnapshot(id)) score -= 150;
    if (id.contains('deprecated') || id.contains('legacy')) score -= 1000000;
    if (id.contains('preview') || id.contains('experimental')) score -= 120;
    if (id.contains('latest')) score += 50;

    return score;
  }

  /// The family version encoded in a model id, as a comparable number.
  ///
  /// `gpt-5.4` → 5.4, `gpt-4o-mini` → 4, `o3` → 3, `claude-opus-4-6` → 4.6,
  /// `gemini-2.5-pro` → 2.5, `mistral-large-3` → 3.
  ///
  /// Takes the *first* version-shaped token and ignores 4-digit-or-longer runs,
  /// so date stamps (`grok-4.20-0309`, `-2026-03-01`) and serial suffixes
  /// (`-001`) do not masquerade as versions.
  double _modelVersionValue(String id) {
    final withoutDates = id.replaceAll(RegExp(r'\d{4,}'), '');
    final match = RegExp(r'(?<![0-9.])(\d{1,3})(?:[.\-](\d{1,2}))?(?![0-9])')
        .firstMatch(withoutDates);
    if (match == null) {
      return 0.0;
    }
    final major = int.tryParse(match.group(1)!) ?? 0;
    final minor = int.tryParse(match.group(2) ?? '') ?? 0;
    return major + (minor / 100.0);
  }

  /// Capability tier from vocabulary every provider reuses across generations.
  ///
  /// A model that names no tier is the family's plain flagship and sits in the
  /// middle, above the cheap variants and below an explicit `pro`.
  int _modelTierScore(String id) {
    const topTier = ['-pro', 'large', 'opus', 'ultra', 'max', 'heavy'];
    const midTier = ['medium', 'sonnet', 'fast', 'turbo'];
    const lowTier = ['mini', 'small', 'haiku', 'flash'];
    // `lite` sits here rather than with the low tier so `flash-lite` lands
    // below plain `flash`, which is what it costs and what it is.
    const bottomTier = ['nano', 'tiny', 'micro', 'lite'];

    if (bottomTier.any(id.contains)) return 0;
    if (lowTier.any(id.contains)) return 1;
    if (topTier.any(id.contains)) return 4;
    if (midTier.any(id.contains)) return 2;
    return 3;
  }

  bool _looksLikeDatedSnapshot(String id) {
    return RegExp(r'-\d{4}-\d{2}-\d{2}$').hasMatch(id) ||
        RegExp(r'-\d{8}$').hasMatch(id);
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  /// Analyzes one or more meal images and returns suggested food items.
  /// [depthMap] is appended after the photos and described by [depthMapLegend];
  /// both must be given together or not at all, since a false-colour image with
  /// no scale tells the model nothing.
  Future<AiMealCandidate> analyzeImages(
    List<File> images, {
    String? textHint,
    String? languageCode,
    AiMatchingContext? matchingContext,
    DepthScaleFacts? depthFacts,
    File? depthMap,
    String? depthMapLegend,
  }) async {
    final userContent =
        textHint ?? 'Analyze this meal and identify all food components.';
    final attachDepthMap = depthMap != null &&
        depthMapLegend != null &&
        depthMapLegend.trim().isNotEmpty;

    final prompt = _AiPrompts.buildSystemPrompt(
      languageCode: languageCode,
      appLanguage: matchingContext?.appLanguage,
      catalogLanguage: matchingContext?.catalogLanguage,
      depthFacts: depthFacts,
      depthMapLegend: attachDepthMap ? depthMapLegend : null,
    );

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      systemPrompt: prompt,
      images: attachDepthMap ? [...images, depthMap] : images,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
  }

  /// Analyzes a text-only meal description and returns an AI suggested meal candidate.
  Future<AiMealCandidate> analyzeText(
    String description, {
    String? languageCode,
    AiMatchingContext? matchingContext,
  }) async {
    final prompt = _AiPrompts.buildSystemPrompt(
      languageCode: languageCode,
      appLanguage: matchingContext?.appLanguage,
      catalogLanguage: matchingContext?.catalogLanguage,
    );

    final raw = await _callSelectedProviderRaw(
      userContent: description,
      systemPrompt: prompt,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
  }

  /// Turns a raw dictation transcript into bullets, correcting mishearings.
  ///
  /// Returns null when there is nothing to tidy or the provider is unavailable
  /// — dictation has to keep working without an API key, so every failure here
  /// falls back to the locally cleaned transcript rather than surfacing.
  Future<VoiceTranscriptSummary?> tidyVoiceTranscript(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return null;

    final stopwatch = Stopwatch()..start();
    try {
      // Capped well below the configured request timeout. Tidying is a nicety
      // on top of a transcript the user can already read and send; holding them
      // on a spinner for a minute to get it would be a bad trade.
      final raw = await _callSelectedProviderRaw(
        userContent: trimmed,
        systemPrompt: _AiPrompts.buildVoiceTidyPrompt(),
        temperature: 0.1,
      ).timeout(const Duration(seconds: 15));
      stopwatch.stop();
      final summary = _parseVoiceSummary(raw, stopwatch.elapsed);
      if (summary == null || summary.isEmpty) return null;
      return summary;
    } catch (e) {
      debugPrint('[AiService] transcript tidy failed: $e');
      return null;
    }
  }

  @visibleForTesting
  VoiceTranscriptSummary? parseVoiceSummaryForTesting(String content) =>
      _parseVoiceSummary(content, Duration.zero);

  VoiceTranscriptSummary? _parseVoiceSummary(String content, Duration elapsed) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    try {
      final decoded =
          jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      final rawBullets = decoded['bullets'];
      if (rawBullets is! List) return null;

      final bullets = <VoiceTranscriptBullet>[];
      for (final entry in rawBullets) {
        if (entry is! Map) continue;
        final text = (entry['text'] as String?)?.trim();
        if (text == null || text.isEmpty) continue;
        final notes = <String>[];
        final rawNotes = entry['notes'];
        if (rawNotes is List) {
          for (final note in rawNotes) {
            final value = note?.toString().trim();
            if (value != null && value.isNotEmpty) notes.add(value);
          }
        }
        bullets.add(VoiceTranscriptBullet(text: text, notes: notes));
      }

      final context = (decoded['context'] as String?)?.trim();
      return VoiceTranscriptSummary(
        bullets: bullets,
        context: (context == null || context.isEmpty) ? null : context,
        elapsed: elapsed,
      );
    } catch (e) {
      debugPrint('[AiService] transcript tidy parse failed: $e');
      return null;
    }
  }

  /// Retries analysis with user feedback to refine the results.
  Future<AiMealCandidate> retry({
    required List<AiSuggestedItem> previousResults,
    required String feedback,
    List<File>? images,
    String? languageCode,
    AiMatchingContext? matchingContext,
  }) async {
    final previousJson = jsonEncode(
      previousResults.map((e) => e.toJson()).toList(),
    );
    final userContent = '''
Previous analysis result:
$previousJson

User correction/feedback: $feedback

Please provide an updated analysis incorporating the user's feedback. Return the corrected JSON object containing mealContext and items.''';

    final prompt = _AiPrompts.buildSystemPrompt(
      languageCode: languageCode,
      appLanguage: matchingContext?.appLanguage,
      catalogLanguage: matchingContext?.catalogLanguage,
    );

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      systemPrompt: prompt,
      images: images,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
  }

  /// Tests whether the API key is valid by sending a minimal request.
  Future<bool> testConnection() async {
    try {
      await analyzeText(
        'Test: reply with [{"name":"Test","estimatedGrams":1,"confidence":1.0}]',
      );
      return true;
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Repair
  // ---------------------------------------------------------------------------

  Future<AiMealCandidate> repairMealCaptureCandidate({
    required AiMealCandidate candidate,
    required AiValidationResult validation,
    List<File>? images,
    String? languageCode,
    AiMatchingContext? matchingContext,
    AiMealContext? mealContext,
    DepthScaleFacts? depthFacts,
  }) async {
    final userContent = '''
Previous meal capture candidate:
${jsonEncode(candidate.items.map((item) => {
              'name': item.name,
              'estimatedGrams': item.grams,
              if (item.confidence != null) 'confidence': item.confidence,
              if (item.stateHint != null) 'stateHint': item.stateHint,
            }).toList())}

Deterministic validation feedback:
${validation.toRepairFeedback()}

Repair the candidate. When database candidates are listed, pick the EXACT name from the list. Adjust grams to fit the meal context anchor.''';

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      images: images,
      systemPrompt: _AiPrompts.buildRepairPrompt(
        languageCode: languageCode,
        appLanguage: matchingContext?.appLanguage,
        catalogLanguage: matchingContext?.catalogLanguage,
        mealContext: mealContext,
        depthFacts: depthFacts,
      ),
      temperature: 0.1,
    );
    final repaired = await _parseItemsFromContent(raw);

    return AiMealCandidate(
      items: repaired
          .map(
            (item) => AiMealCandidateItem(
              name: item.name,
              grams: item.estimatedGrams,
              confidence: item.confidence,
              matchedBarcode: item.matchedBarcode,
            ),
          )
          .toList(growable: false),
      context: candidate.context,
    );
  }

  Future<String> _callSelectedProviderRaw({
    required String userContent,
    required String systemPrompt,
    List<File>? images,
    double temperature = 0.3,
  }) async {
    final requestId = const Uuid().v4();
    final providerEnum = await getSelectedProvider();
    final provider = providerEnum.name;
    final stopwatch = Stopwatch()..start();

    unawaited(TelemetryService.instance.trackAiMealScanRequested(
      requestId: requestId,
      provider: provider,
    ));

    try {
      String? apiKey;
      if (providerEnum != AiProvider.ollama) {
        apiKey = await getApiKey(providerEnum);
        if (providerEnum != AiProvider.custom &&
            (apiKey == null || apiKey.isEmpty)) {
          throw const AiKeyMissingException();
        }
      }
      final model = await resolveAndPersistSelectedModel(providerEnum);

      // Scaled before encoding: the raw camera file is 3–8 MB, base64 adds a
      // third on top, and the models resize to about 1024 px anyway — four
      // untouched photos meant tens of megabytes uploaded over mobile data for
      // pixels the provider throws away. The capture screen has usually
      // prepared these already, so this is a cache hit by the time it runs.
      final imageDataList = <String>[];
      if (images != null) {
        for (final img in images) {
          final prepared =
              await MealImageProcessor.instance.prepareForAnalysis(img);
          imageDataList.add(prepared.base64);
        }
      }

      final String rawResult;
      switch (providerEnum) {
        case AiProvider.openai:
          rawResult = await _callOpenAiRaw(
            apiKey!,
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
          );
          break;
        case AiProvider.ollama:
          rawResult = await _callOpenAiRaw(
            '',
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
            baseUrlOverride: 'http://localhost:11434/v1',
            provider: providerEnum,
          );
          break;
        case AiProvider.custom:
          final customUrl = await getCustomBaseUrl();
          rawResult = await _callOpenAiRaw(
            apiKey ?? '',
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
            baseUrlOverride: customUrl,
            provider: providerEnum,
          );
          break;
        case AiProvider.gemini:
          rawResult = await _callGeminiRaw(
            apiKey!,
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
          );
          break;
        case AiProvider.anthropic:
          rawResult = await _callAnthropicRaw(
            apiKey!,
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
          );
          break;
        case AiProvider.mistral:
          rawResult = await _callMistralRaw(
            apiKey!,
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
          );
          break;
        case AiProvider.xai:
          rawResult = await _callXaiRaw(
            apiKey!,
            model,
            userContent,
            imageDataList,
            systemPrompt: systemPrompt,
            temperature: temperature,
          );
          break;
      }

      stopwatch.stop();
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: TelemetryBuckets.getLatencyBucket(stopwatch.elapsed),
        success: true,
      ));

      return rawResult;
    } catch (e) {
      stopwatch.stop();
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: TelemetryBuckets.getLatencyBucket(stopwatch.elapsed),
        success: false,
        errorCode: e.runtimeType.toString(),
      ));
      rethrow;
    }
  }
}

part of '../ai_service.dart';

/// Supported AI providers for meal analysis.
enum AiProvider {
  openai,
  gemini,
  anthropic,
  mistral,
  xai,
  ollama,
  custom,
}

/// Provider registry metadata.
class AiProviderMetadata {
  final AiProvider provider;
  final String displayName;
  final String keyHint;
  final String defaultModel;
  final List<String> rankingHints;
  final List<String> emergencyFallbackModels;
  final bool supportsVision;
  final bool supportsDynamicModelLoading;

  const AiProviderMetadata({
    required this.provider,
    required this.displayName,
    required this.keyHint,
    required this.defaultModel,
    required this.rankingHints,
    required this.emergencyFallbackModels,
    required this.supportsVision,
    required this.supportsDynamicModelLoading,
  });
}

/// Model option for settings selection.
class AiModelOption {
  final String id;
  final String label;
  final bool isFallback;

  const AiModelOption({
    required this.id,
    required this.label,
    this.isFallback = false,
  });
}

/// Why a provider's live model list could not be loaded.
///
/// The settings screen turns this into one sentence so the user learns *why*
/// they are looking at a hardcoded list instead of the provider's own. A
/// silently swallowed 401 is indistinguishable from "the provider really only
/// offers these three models", which is exactly how a stale fallback list ends
/// up looking like the truth.
enum AiModelListErrorKind {
  /// No API key stored yet, so nothing could be requested.
  missingKey,

  /// The provider has no model-listing endpoint we speak (Ollama, custom).
  unsupported,

  /// The connection failed outright — offline, DNS, TLS, refused.
  network,

  /// The request ran past the configured AI timeout.
  timeout,

  /// 401/403 — key rejected, revoked, or lacking permission.
  auth,

  /// 429 — rate limited or out of quota.
  rateLimit,

  /// Any other non-200 status.
  http,

  /// 200, but the body was not the JSON shape we expect.
  response,
}

/// Why [AiService.loadModelOptions] fell back to the hardcoded list.
class AiModelListError {
  final AiModelListErrorKind kind;

  /// HTTP status for the [AiModelListErrorKind.auth],
  /// [AiModelListErrorKind.rateLimit] and [AiModelListErrorKind.http] kinds;
  /// null otherwise.
  final int? statusCode;

  /// The provider's own `error.message`, when it sent one.
  final String? providerMessage;

  const AiModelListError(
    this.kind, {
    this.statusCode,
    this.providerMessage,
  });

  /// True for the two "nothing was even attempted" kinds, which describe a
  /// normal state rather than a failure.
  bool get isBenign =>
      kind == AiModelListErrorKind.missingKey ||
      kind == AiModelListErrorKind.unsupported;

  @override
  String toString() {
    final parts = <String>[kind.name];
    if (statusCode != null) parts.add('HTTP $statusCode');
    if (providerMessage != null) parts.add(providerMessage!);
    return parts.join(': ');
  }
}

/// A model list plus the reason it may be a fallback.
///
/// [AiService.getModelOptions] drops the reason for callers that only need the
/// ids; the settings screen uses [AiService.loadModelOptions] so it can show
/// [error] to the user.
class AiModelListResult {
  final List<AiModelOption> options;

  /// True when [options] came from `emergencyFallbackModels` rather than from
  /// the provider.
  final bool isFallback;

  /// Why the live list is missing. Null on the happy path.
  final AiModelListError? error;

  const AiModelListResult({
    required this.options,
    required this.isFallback,
    this.error,
  });
}

/// A raw model-id fetch: either ids, or the reason there are none.
class AiModelIdsFetch {
  final Set<String>? ids;
  final AiModelListError? error;

  const AiModelIdsFetch.success(Set<String> this.ids) : error = null;
  const AiModelIdsFetch.failure(AiModelListError this.error) : ids = null;
}

/// A single food component suggested by the AI.
class AiSuggestedItem {
  /// Display name of the detected food component.
  String name;

  /// Estimated weight in grams.
  int estimatedGrams;

  /// Confidence score between 0.0 and 1.0.
  double confidence;

  /// Barcode of a matched product in the local database (filled after fuzzy matching).
  String? matchedBarcode;

  AiSuggestedItem({
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    this.matchedBarcode,
  });

  factory AiSuggestedItem.fromJson(Map<String, dynamic> json) {
    return AiSuggestedItem(
      name: json['name'] as String? ?? 'Unknown',
      estimatedGrams: (json['estimatedGrams'] as num?)?.toInt() ?? 100,
      confidence:
          (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimatedGrams': estimatedGrams,
        'confidence': confidence,
      };
}

/// Base exception for AI service errors.
sealed class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}

class AiKeyMissingException extends AiServiceException {
  const AiKeyMissingException()
      : super('No API key configured for the selected provider.');
}

class AiAuthException extends AiServiceException {
  const AiAuthException([
    super.message = 'Authentication failed. Please check your API key.',
  ]);
}

class AiNetworkException extends AiServiceException {
  const AiNetworkException([
    super.message = 'Network error. Please check your connection.',
  ]);
}

class AiParseException extends AiServiceException {
  const AiParseException([super.message = 'Could not parse the AI response.']);
}

class AiRateLimitException extends AiServiceException {
  const AiRateLimitException([
    super.message = 'Rate limit exceeded. Please wait a moment.',
  ]);
}

class AiUnsupportedFeatureException extends AiServiceException {
  const AiUnsupportedFeatureException(
      [super.message = 'Feature not supported.']);
}

/// One bullet of a tidied dictation transcript.
class VoiceTranscriptBullet {
  /// The food and its amount, e.g. "500 g Hähnchen".
  final String text;

  /// What the user said about *this* food and nothing else — "Trockengewicht",
  /// "in zwei Esslöffeln Olivenöl gebraten". Kept apart from [text] so a
  /// qualifier never gets mistaken for part of the food's name.
  final List<String> notes;

  const VoiceTranscriptBullet({required this.text, this.notes = const []});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (notes.isNotEmpty) 'notes': notes,
      };
}

/// A dictation transcript turned into readable bullets.
class VoiceTranscriptSummary {
  final List<VoiceTranscriptBullet> bullets;

  /// Anything the user said that belongs to the meal as a whole rather than to
  /// one food — "zum Mittagessen", "im Restaurant".
  final String? context;

  /// How long the request took, so the wait can be judged rather than guessed.
  final Duration elapsed;

  const VoiceTranscriptSummary({
    required this.bullets,
    this.context,
    this.elapsed = Duration.zero,
  });

  bool get isEmpty => bullets.isEmpty;

  /// The bullets as Markdown.
  ///
  /// Markdown rather than a flat sentence because this is what leaves the
  /// sheet: it lands in the note field, the user still sees the structure they
  /// just approved, and the analysis gets one food per line with that food's
  /// qualifiers attached to it instead of a run-on sentence it has to
  /// re-segment.
  String toMarkdown() {
    final lines = <String>[];
    for (final bullet in bullets) {
      lines.add('- ${bullet.text}');
      for (final note in bullet.notes) {
        lines.add('  - $note');
      }
    }
    if (context != null && context!.trim().isNotEmpty) {
      lines.add('');
      lines.add(context!.trim());
    }
    return lines.join('\n');
  }
}

/// Formats a provider and model id into a clean display label.
String? formatModelDisplayName(String? providerId, String? modelId) {
  if (providerId == 'appleFoundation' || modelId == 'apple-foundation-system') {
    return 'Apple Intelligence';
  }
  if (modelId != null && modelId.trim().isNotEmpty) {
    return modelId.trim();
  }
  return null;
}

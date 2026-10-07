// lib/screens/ai_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/ai_service.dart';
import '../../../services/theme_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../depth_scan/data/depth_scan_settings.dart';
import '../../../services/voice/voice_dictation_settings.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../../services/ai/local_ai_model_manager.dart';
import '../../../services/ai/apple_foundation_service.dart';

/// Settings page for configuring the AI Meal Capture feature.
///
/// Allows users to select an AI provider + model, enter their API key
/// (stored securely in native Keychain/Keystore), test the connection, and read
/// a privacy disclosure.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _customModelController = TextEditingController();
  AiProvider _selectedProvider = AiProvider.openai;
  String _selectedModel = '';
  List<AiModelOption> _modelOptions = const [];

  /// Why the picker is showing the built-in list instead of the provider's.
  /// Null while the live list loaded fine.
  AiModelListError? _modelListError;
  bool _isLoadingModels = false;
  bool _isTesting = false;
  bool _obscureKey = true;
  bool _hasKey = false;
  int _timeoutSeconds = 60;

  /// Only shown on devices that can actually measure — elsewhere the switch
  /// would advertise something the hardware cannot do.
  bool _hasLidar = false;
  bool _scaleHintEnabled = true;
  bool _depthImageEnabled = true;
  bool _voiceTidyEnabled = true;
  bool _isAppleFoundationAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiSettings));
    LocalAiModelManager.instance.addListener(_onLocalModelsChanged);
    unawaited(LocalAiModelManager.instance.initialize());
    unawaited(_checkAppleFoundationAvailability());
    _loadSettings();
    unawaited(_loadDepthSettings());
    unawaited(_loadVoiceSettings());
  }

  void _onLocalModelsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAppleFoundationAvailability() async {
    final available = await AppleFoundationService.instance.isAvailable();
    if (mounted) setState(() => _isAppleFoundationAvailable = available);
  }

  Future<void> _loadDepthSettings() async {
    final capability = await DepthScanChannel.instance.capability();
    final enabled = await DepthScanSettings.instance.isScaleHintEnabled();
    final depthImage = await DepthScanSettings.instance.isDepthImageEnabled();
    if (!mounted) return;
    setState(() {
      _hasLidar = capability.depthSupported;
      _scaleHintEnabled = enabled;
      _depthImageEnabled = depthImage;
    });
  }

  Future<void> _loadVoiceSettings() async {
    final enabled = await VoiceDictationSettings.instance.isAiTidyEnabled();
    if (!mounted) return;
    setState(() => _voiceTidyEnabled = enabled);
  }

  @override
  void dispose() {
    LocalAiModelManager.instance.removeListener(_onLocalModelsChanged);
    _keyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final provider = await AiService.instance.getSelectedProvider();
    final savedModel = await AiService.instance.getSelectedModel(provider);
    final key = await AiService.instance.getApiKey(provider);
    final customBaseUrl = await AiService.instance.getCustomBaseUrl();
    final customModel = await AiService.instance.getCustomModel();
    final timeout = await AiService.instance.getAiTimeoutSeconds();

    final isCloud = provider != AiProvider.ollama &&
        provider != AiProvider.custom &&
        provider != AiProvider.appleFoundation &&
        provider != AiProvider.localModel;
    final isOffline = provider == AiProvider.ollama ||
        provider == AiProvider.custom ||
        provider == AiProvider.appleFoundation ||
        provider == AiProvider.localModel;
    final meta = AiService.instance.getProviderMetadata(provider);
    final effectiveModel =
        savedModel.isNotEmpty ? savedModel : meta.defaultModel;

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = effectiveModel;
        _modelOptions = _buildModelOptionsWithSelection(
          meta.emergencyFallbackModels
              .map((m) => AiModelOption(id: m, label: m, isFallback: true))
              .toList(),
          effectiveModel,
          provider,
        );
        _hasKey = isOffline || (key != null && key.isNotEmpty);
        _timeoutSeconds = timeout;
        if (_hasKey &&
            provider != AiProvider.ollama &&
            provider != AiProvider.appleFoundation &&
            provider != AiProvider.localModel) {
          _keyController.text = '••••••••••••••••••••';
        } else {
          _keyController.text = '';
        }
        _baseUrlController.text = customBaseUrl ?? '';
        _customModelController.text = customModel ?? '';
        _isLoadingModels = isCloud;
      });
    }

    if (isCloud) {
      unawaited(_loadDynamicModels(provider));
    }
  }

  Future<void> _loadDynamicModels(AiProvider provider) async {
    try {
      final modelList = await AiService.instance.loadModelOptions(provider);
      final models = modelList.options;
      final selected = await AiService.instance.getSelectedModel(provider);
      final resolvedModel = _resolveModelSelection(
        selected.isNotEmpty ? selected : _selectedModel,
        models,
        provider,
      );
      if (resolvedModel != selected) {
        await AiService.instance.setSelectedModel(provider, resolvedModel);
      }
      if (mounted && _selectedProvider == provider) {
        setState(() {
          _selectedModel = resolvedModel;
          _modelOptions = _buildModelOptionsWithSelection(
            models,
            resolvedModel,
            provider,
          );
          _modelListError = modelList.error;
          _isLoadingModels = false;
        });
      }
    } catch (_) {
      if (mounted && _selectedProvider == provider) {
        setState(() => _isLoadingModels = false);
      }
    }
  }

  Future<void> _onProviderChanged(AiProvider? provider) async {
    if (provider == null) return;
    final isCloud = provider != AiProvider.ollama &&
        provider != AiProvider.custom &&
        provider != AiProvider.appleFoundation &&
        provider != AiProvider.localModel;
    final isOffline = provider == AiProvider.ollama ||
        provider == AiProvider.custom ||
        provider == AiProvider.appleFoundation ||
        provider == AiProvider.localModel;
    final meta = AiService.instance.getProviderMetadata(provider);
    final savedModel = await AiService.instance.getSelectedModel(provider);
    final effectiveModel =
        savedModel.isNotEmpty ? savedModel : meta.defaultModel;
    final key = await AiService.instance.getApiKey(provider);
    final customBaseUrl = await AiService.instance.getCustomBaseUrl();
    final customModel = await AiService.instance.getCustomModel();

    await AiService.instance.setSelectedProvider(provider);

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = effectiveModel;
        _modelOptions = _buildModelOptionsWithSelection(
          meta.emergencyFallbackModels
              .map((m) => AiModelOption(id: m, label: m, isFallback: true))
              .toList(),
          effectiveModel,
          provider,
        );
        _modelListError = null;
        _hasKey = isOffline || (key != null && key.isNotEmpty);
        _keyController.text = _hasKey &&
                provider != AiProvider.ollama &&
                provider != AiProvider.appleFoundation &&
                provider != AiProvider.localModel
            ? '••••••••••••••••••••'
            : '';
        _baseUrlController.text = customBaseUrl ?? '';
        _customModelController.text = customModel ?? '';
        _isLoadingModels = isCloud;
      });
    }

    if (isCloud) {
      unawaited(_loadDynamicModels(provider));
    }
  }

  Future<void> _onModelChanged(String? model) async {
    if (model == null || model.isEmpty) return;
    await AiService.instance.setSelectedModel(_selectedProvider, model);
    if (mounted) {
      setState(() => _selectedModel = model);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _keyController.text.trim();

    if (_selectedProvider == AiProvider.custom ||
        _selectedProvider == AiProvider.ollama) {
      final baseUrl = _baseUrlController.text.trim();
      final customModel = _customModelController.text.trim();
      await AiService.instance.setCustomBaseUrl(
        baseUrl.isNotEmpty ? baseUrl : null,
      );
      await AiService.instance.setCustomModel(
        customModel.isNotEmpty ? customModel : null,
      );
    }

    // Don't save the masked placeholder
    final isNewKey = key.isNotEmpty && !key.startsWith('••');
    if (isNewKey) {
      await AiService.instance.setApiKey(_selectedProvider, key);
    }

    await _refreshModels();
    if (mounted) {
      setState(() {
        _hasKey = isNewKey || _hasKey;
        if (_hasKey && _selectedProvider != AiProvider.ollama) {
          _keyController.text = '••••••••••••••••••••';
        }
        _obscureKey = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.aiKeySaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteApiKey() async {
    await AiService.instance.deleteApiKey(_selectedProvider);
    await _refreshModels();
    if (mounted) {
      setState(() {
        _hasKey = false;
        _keyController.clear();
      });
    }
  }

  Future<void> _refreshModels() async {
    if (!mounted) return;
    if (_selectedProvider == AiProvider.ollama ||
        _selectedProvider == AiProvider.custom) {
      final selectedModel = await AiService.instance.getSelectedModel(
        _selectedProvider,
      );
      if (!mounted) return;
      setState(() {
        _selectedModel = selectedModel;
        _modelListError = null;
      });
      return;
    }
    setState(() => _isLoadingModels = true);
    await _loadDynamicModels(_selectedProvider);
  }

  /// One sentence explaining why the picker is showing the built-in list.
  ///
  /// Without this the user sees a short, stale list and has no way to tell it
  /// apart from the provider's real catalogue — a rejected key looks exactly
  /// like "this provider only offers three models".
  String _modelListErrorMessage(AppLocalizations l10n, AiModelListError error) {
    final status = error.statusCode?.toString() ?? '-';
    final base = switch (error.kind) {
      AiModelListErrorKind.missingKey => l10n.aiModelListErrorMissingKey,
      AiModelListErrorKind.unsupported => l10n.aiModelListErrorResponse,
      AiModelListErrorKind.network => l10n.aiModelListErrorNetwork,
      AiModelListErrorKind.timeout => l10n.aiModelListErrorTimeout,
      AiModelListErrorKind.auth => l10n.aiModelListErrorAuth(status),
      AiModelListErrorKind.rateLimit => l10n.aiModelListErrorRateLimit(status),
      AiModelListErrorKind.http => l10n.aiModelListErrorHttp(status),
      AiModelListErrorKind.response => l10n.aiModelListErrorResponse,
    };
    // The provider's own wording is often the only thing that names the real
    // cause ("insufficient permissions for /v1/models"), so pass it through.
    final providerMessage = error.providerMessage?.trim();
    if (providerMessage == null || providerMessage.isEmpty) return base;
    return '$base\n$providerMessage';
  }

  Widget _buildModelListFallbackNotice(
    AppLocalizations l10n,
    ThemeData theme,
    AiModelListError error,
  ) {
    final color = error.kind == AiModelListErrorKind.missingKey
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.triangle_alert, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiModelListFallbackTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _modelListErrorMessage(l10n, error),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _isLoadingModels ? null : _refreshModels,
                    child: Text(l10n.aiModelListRetry),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveModelSelection(
    String currentSelection,
    List<AiModelOption> models,
    AiProvider provider,
  ) {
    if (models.any((m) => m.id == currentSelection)) return currentSelection;
    if (models.isNotEmpty) return models.first.id;
    return AiService.instance.getProviderMetadata(provider).defaultModel;
  }

  List<AiModelOption> _buildModelOptionsWithSelection(
    List<AiModelOption> models,
    String selectedModel,
    AiProvider provider,
  ) {
    if (models.isEmpty) {
      final defaultModel =
          AiService.instance.getProviderMetadata(provider).defaultModel;
      final effective = selectedModel.isNotEmpty ? selectedModel : defaultModel;
      return [
        AiModelOption(id: effective, label: effective, isFallback: true),
      ];
    }
    if (selectedModel.isNotEmpty && !models.any((m) => m.id == selectedModel)) {
      return [
        AiModelOption(id: selectedModel, label: selectedModel),
        ...models,
      ];
    }
    return models;
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await AiService.instance.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiTestSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _startModelDownload(LocalAiModelDefinition model) async {
    try {
      final completed =
          await LocalAiModelManager.instance.startDownload(model.id);
      if (!completed) return; // User cancelled download
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} erfolgreich heruntergeladen!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteModel(LocalAiModelDefinition model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modell löschen?'),
        content: Text(
          'Möchtest du "${model.name}" wirklich löschen? Dadurch werden ${model.formattedSize} Speicher auf deinem Gerät freigegeben.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await LocalAiModelManager.instance.deleteModel(model.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} gelöscht.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final aiEnabled = themeService.isAiEnabled;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiSettingsTitle),
      body: ListView(
        key: const PageStorageKey<String>('ai_settings_list'),
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppInfoRow(
            title: l10n.aiSettingsInstructionTitle,
            subtitle: l10n.aiSettingsInstructionBody,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          AppLinkRow(
            title: l10n.aiSettingsSetupGuideTitle,
            subtitle: l10n.aiSettingsSetupGuideBody,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () => launchUrl(
              Uri.parse('https://ai.google.dev/gemini-api/docs/api-key'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

          AppSectionHeader(title: l10n.aiSettingsTitle),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlatformAdaptiveSwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          DesignConstants.createAiGradientShader(bounds),
                      child: const Icon(LucideIcons.sparkles),
                    ),
                    title: Text(
                      l10n.aiEnableTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.aiEnableSubtitle),
                    value: aiEnabled,
                    onChanged: (value) => themeService.setAiEnabled(value),
                  ),
                  if (aiEnabled && _hasLidar) ...[
                    const SizedBox(height: 12),
                    PlatformAdaptiveSwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(LucideIcons.ruler),
                      title: Text(
                        l10n.aiLidarScaleTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.aiLidarScaleSubtitle),
                      value: _scaleHintEnabled,
                      onChanged: (value) async {
                        await DepthScanSettings.instance
                            .setScaleHintEnabled(value);
                        if (!mounted) return;
                        setState(() => _scaleHintEnabled = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    PlatformAdaptiveSwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(LucideIcons.layers),
                      title: Text(
                        l10n.aiDepthImageTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.aiDepthImageSubtitle),
                      value: _depthImageEnabled,
                      onChanged: (value) async {
                        await DepthScanSettings.instance
                            .setDepthImageEnabled(value);
                        if (!mounted) return;
                        setState(() => _depthImageEnabled = value);
                      },
                    ),
                  ],
                  if (aiEnabled) ...[
                    const SizedBox(height: 12),
                    PlatformAdaptiveSwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(LucideIcons.mic),
                      title: Text(
                        l10n.aiVoiceTidyTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.aiVoiceTidySubtitle),
                      value: _voiceTidyEnabled,
                      onChanged: (value) async {
                        await VoiceDictationSettings.instance
                            .setAiTidyEnabled(value);
                        if (!mounted) return;
                        setState(() => _voiceTidyEnabled = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    PlatformAdaptiveDropdownFormField<AiProvider>(
                      key: ValueKey(
                          'ai_provider_dropdown_${_selectedProvider.name}'),
                      value: _selectedProvider,
                      initialValue: _selectedProvider,
                      decoration: InputDecoration(
                        labelText: l10n.aiProviderLabel,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: AiService.instance
                          .getSupportedProviders()
                          .map(
                            (providerMeta) => DropdownMenuItem(
                              value: providerMeta.provider,
                              child: Text(providerMeta.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: _onProviderChanged,
                    ),
                    const SizedBox(height: 10),
                    if (_selectedProvider != AiProvider.ollama &&
                        _selectedProvider != AiProvider.custom &&
                        _selectedProvider != AiProvider.appleFoundation &&
                        _selectedProvider != AiProvider.localModel) ...[
                      Skeletonizer(
                        enabled: _isLoadingModels,
                        child: PlatformAdaptiveDropdownFormField<String>(
                          key: ValueKey('ai_model_dropdown_$_selectedProvider'),
                          initialValue:
                              _selectedModel.isNotEmpty ? _selectedModel : null,
                          decoration: InputDecoration(
                            labelText: l10n.aiModelLabel,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _modelOptions
                              .map(
                                (model) => DropdownMenuItem(
                                  value: model.id,
                                  child: Text(model.label),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoadingModels ? null : _onModelChanged,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_isLoadingModels && _modelListError != null)
                        _buildModelListFallbackNotice(
                          l10n,
                          theme,
                          _modelListError!,
                        ),
                    ],
                    if (_selectedProvider == AiProvider.appleFoundation) ...[
                      SummaryCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.sparkles,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Apple Intelligence (On-Device)',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            _isAppleFoundationAvailable
                                                ? LucideIcons.circle_check
                                                : LucideIcons.circle_alert,
                                            size: 14,
                                            color: _isAppleFoundationAvailable
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isAppleFoundationAvailable
                                                ? 'Aktiv & Bereit auf diesem Gerät'
                                                : 'In den iOS-Einstellungen aktivieren',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _isAppleFoundationAvailable
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Verwendet das native Apple Foundation Model direkt über die Apple Neural Engine des iPhone 16 Pro.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '0 MB Download',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '100% Offline',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Volle Privatsphäre',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_selectedProvider == AiProvider.localModel) ...[
                      SummaryCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.cpu,
                                    color: theme.colorScheme.secondary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lokale Hugging Face Modelle',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder<int>(
                                        future: LocalAiModelManager.instance
                                            .getTotalLocalStorageBytes(),
                                        builder: (context, snapshot) {
                                          final bytes = snapshot.data ?? 0;
                                          final mb = bytes / (1024 * 1024);
                                          final formatted = mb > 1024
                                              ? '${(mb / 1024).toStringAsFixed(1)} GB'
                                              : '${mb.toStringAsFixed(0)} MB';
                                          return Text(
                                            'Belegter Modellspeicher: $formatted',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Lade kuratierte Open-Source Vision-Modelle direkt von Hugging Face herunter, um Mahlzeiten komplett offline auszuführen.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...LocalAiModelManager.availableModels.map((model) {
                        final isSelected = LocalAiModelManager
                                .instance.selectedModelId ==
                            model.id;
                        final isDownloaded = LocalAiModelManager.instance
                            .isDownloaded(model.id);
                        final downloadState = LocalAiModelManager.instance
                            .getDownloadState(model.id);
                        final isDownloading = downloadState != null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCardContainer(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            model.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: model.isRecommended
                                                  ? theme.colorScheme.primary
                                                      .withValues(alpha: 0.15)
                                                  : theme.colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              model.tag,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: model.isRecommended
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      model.formattedSize,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  model.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (isDownloading) ...[
                                  LinearProgressIndicator(
                                    value: downloadState.progress > 0
                                        ? downloadState.progress
                                        : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${(downloadState.progress * 100).toStringAsFixed(0)}% (${(downloadState.receivedBytes / (1024 * 1024)).toStringAsFixed(0)} MB / ${(downloadState.totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB)',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      TextButton(
                                        onPressed: () => LocalAiModelManager
                                            .instance
                                            .cancelDownload(model.id),
                                        child: const Text('Abbrechen',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (isDownloaded) ...[
                                        const Row(
                                          children: [
                                            Icon(LucideIcons.circle_check,
                                                size: 16, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'Heruntergeladen',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            if (!isSelected)
                                              AppButton.secondary(
                                                onPressed: () async {
                                                  await LocalAiModelManager
                                                      .instance
                                                      .selectModel(model.id);
                                                  await AiService.instance
                                                      .setSelectedModel(
                                                          AiProvider.localModel,
                                                          model.id);
                                                  setState(() =>
                                                      _selectedModel =
                                                          model.id);
                                                },
                                                label: 'Aktivieren',
                                                tooltip:
                                                    'Als aktives Modell wählen',
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(LucideIcons.check,
                                                        size: 14,
                                                        color: theme
                                                            .colorScheme
                                                            .primary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Aktiv',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                  LucideIcons.trash,
                                                  size: 18,
                                                  color: Colors.red),
                                              tooltip: 'Modell löschen',
                                              onPressed: () =>
                                                  _confirmDeleteModel(model),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const Spacer(),
                                        AppButton.secondary(
                                          onPressed: () =>
                                              _startModelDownload(model),
                                          label: 'Herunterladen',
                                          tooltip:
                                              'Modell von Hugging Face herunterladen',
                                          icon: LucideIcons.download,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    if (_selectedProvider == AiProvider.ollama) ...[
                      TextField(
                        controller: _customModelController,
                        decoration: InputDecoration(
                          labelText: l10n.settingsLocalModelName,
                          hintText: 'llama3',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_selectedProvider == AiProvider.custom) ...[
                      TextField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText: l10n.settingsCustomBaseUrl,
                          hintText: 'http://localhost:8080/v1',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customModelController,
                        decoration: InputDecoration(
                          labelText: l10n.settingsCustomModelName,
                          hintText: 'custom-model',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Request Timeout Slider
                    if (_selectedProvider != AiProvider.appleFoundation &&
                        _selectedProvider != AiProvider.localModel) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.settingsRequestTimeout,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.settingsSeconds(_timeoutSeconds),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Slider(
                            value: _timeoutSeconds.toDouble(),
                            min: 10,
                            max: 300,
                            divisions: 29, // 10s steps: (300-10)/10 = 29
                            label: l10n.settingsSeconds(_timeoutSeconds),
                            activeColor: theme.colorScheme.primary,
                            onChanged: (value) async {
                              final seconds = value.round();
                              setState(() => _timeoutSeconds = seconds);
                              await AiService.instance.setAiTimeoutSeconds(
                                seconds,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_selectedProvider != AiProvider.ollama &&
                        _selectedProvider != AiProvider.appleFoundation &&
                        _selectedProvider != AiProvider.localModel) ...[
                      TextField(
                        controller: _keyController,
                        obscureText: _obscureKey,
                        onTap: () {
                          if (_keyController.text.startsWith('••')) {
                            _keyController.clear();
                            setState(() => _obscureKey = false);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: l10n.aiApiKeyLabel,
                          hintText: AiService.instance
                              .getProviderMetadata(_selectedProvider)
                              .keyHint,
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.passwordLabel,
                                icon: Icon(
                                  _obscureKey
                                      ? LucideIcons.eye_off
                                      : LucideIcons.eye,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscureKey = !_obscureKey,
                                  );
                                },
                              ),
                              if (_hasKey)
                                IconButton(
                                  tooltip: l10n.delete,
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    color: Colors.red,
                                  ),
                                  onPressed: _deleteApiKey,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        if (_selectedProvider != AiProvider.appleFoundation &&
                            _selectedProvider != AiProvider.localModel) ...[
                          Expanded(
                            child: AppButton.primary(
                              onPressed: _saveApiKey,
                              label: _selectedProvider == AiProvider.ollama
                                  ? 'Save Settings'
                                  : l10n.aiSaveKey,
                              tooltip: _selectedProvider == AiProvider.ollama
                                  ? 'Save Settings'
                                  : l10n.aiSaveKey,
                              icon: LucideIcons.save,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: AppButton.secondary(
                            isLoading: _isTesting,
                            onPressed: ((_hasKey ||
                                        _selectedProvider ==
                                            AiProvider.ollama ||
                                        _selectedProvider ==
                                            AiProvider.appleFoundation ||
                                        (_selectedProvider ==
                                                AiProvider.localModel &&
                                            LocalAiModelManager.instance
                                                .isDownloaded(
                                                    LocalAiModelManager
                                                        .instance
                                                        .selectedModelId))) &&
                                    !_isTesting)
                                ? _testConnection
                                : null,
                            label: l10n.aiTestConnection,
                            tooltip: l10n.aiTestConnection,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: DesignConstants.spacingL),

          // --- Photo Storage & Retention (Screen E2) ---
          AppSectionHeader(title: l10n.mealPhotoStorageSection),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mealPhotoRetentionTitle,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mealPhotoRetentionBody,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: 180,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      for (final days in [30, 90, 180, 365])
                        DropdownMenuItem(
                          value: days,
                          child: Text(days == 180
                              ? '${l10n.mealPhotoRetentionDays(days)} '
                                  '${l10n.mealPhotoRetentionDefaultSuffix}'
                              : l10n.mealPhotoRetentionDays(days)),
                        ),
                      DropdownMenuItem(
                        value: -1,
                        child: Text(l10n.mealPhotoRetentionUnlimited),
                      ),
                    ],
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.mealPhotoRetentionSaved)),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AppButton.secondary(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.mealPhotoDeleteAllTitle),
                          content: Text(l10n.mealPhotoDeleteAllBody),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(l10n.cancel)),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l10n.mealPhotoDeleted)),
                                );
                              },
                              child: Text(l10n.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    label: l10n.mealPhotoDeleteAll,
                    tooltip: l10n.mealPhotoDeleteAll,
                    icon: LucideIcons.trash,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: DesignConstants.spacingL),

          // --- Speech Recognition (Screen E3) ---
          AppSectionHeader(title: l10n.speechSectionTitle),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF34C759),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.speechOnDeviceActive,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.speechOnDeviceBody,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: DesignConstants.spacingXL),

          // --- Privacy Disclosure ---
          AppInfoRow(
            title: l10n.aiPrivacySection,
            subtitle: l10n.aiPrivacyDisclosure,
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ),
          ),
          const BottomContentSpacer(),
        ],
      ),
    );
  }
}

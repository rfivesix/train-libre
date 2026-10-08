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
import '../../../widgets/common/bottom_content_spacer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../depth_scan/data/depth_scan_settings.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
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
  int _retentionDays = 180;

  /// Only shown on devices that can actually measure — elsewhere the switch
  /// would advertise something the hardware cannot do.
  bool _hasLidar = false;
  bool _scaleHintEnabled = true;
  bool _depthImageEnabled = true;
  bool _isAppleFoundationAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiSettings));
    unawaited(_checkAppleFoundationAvailability());
    _loadSettings();
    unawaited(_loadDepthSettings());
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

  @override
  void dispose() {
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
        provider != AiProvider.appleFoundation;
    final isOffline = provider == AiProvider.ollama ||
        provider == AiProvider.custom ||
        provider == AiProvider.appleFoundation;
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
            provider != AiProvider.appleFoundation) {
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
        provider != AiProvider.appleFoundation;
    final isOffline = provider == AiProvider.ollama ||
        provider == AiProvider.custom ||
        provider == AiProvider.appleFoundation;
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
                provider != AiProvider.appleFoundation
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
          ),
          AppLinkRow(
            title: l10n.aiSettingsSetupGuideTitle,
            subtitle: l10n.aiSettingsSetupGuideBody,
            onTap: () => launchUrl(
              Uri.parse('https://ai.google.dev/gemini-api/docs/api-key'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

          AppSectionHeader(title: l10n.aiStatusAndFeaturesSectionTitle),
          AppSettingsRow.switchTile(
            title: l10n.aiEnableTitle,
            subtitle: l10n.aiEnableSubtitle,
            leading: const Icon(LucideIcons.sparkles),
            value: aiEnabled,
            onChanged: (value) => themeService.setAiEnabled(value),
          ),
          if (aiEnabled && _hasLidar) ...[
            const Divider(height: 1),
            AppSettingsRow.switchTile(
              title: l10n.aiLidarScaleTitle,
              subtitle: l10n.aiLidarScaleSubtitle,
              leading: const Icon(LucideIcons.ruler),
              value: _scaleHintEnabled,
              onChanged: (value) async {
                await DepthScanSettings.instance.setScaleHintEnabled(value);
                if (!mounted) return;
                setState(() => _scaleHintEnabled = value);
              },
            ),
            const Divider(height: 1),
            AppSettingsRow.switchTile(
              title: l10n.aiDepthImageTitle,
              subtitle: l10n.aiDepthImageSubtitle,
              leading: const Icon(LucideIcons.layers),
              value: _depthImageEnabled,
              onChanged: (value) async {
                await DepthScanSettings.instance.setDepthImageEnabled(value);
                if (!mounted) return;
                setState(() => _depthImageEnabled = value);
              },
            ),
          ],

          if (aiEnabled) ...[
            const SizedBox(height: DesignConstants.spacingL),
            AppSectionHeader(title: l10n.aiProviderSectionTitle),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlatformAdaptivePopupMenu<AiProvider>(
                  selectedValue: _selectedProvider,
                  onSelected: (val) {
                    _onProviderChanged(val);
                  },
                  items: AiService.instance
                      .getSupportedProviders()
                      .map(
                        (providerMeta) => PlatformAdaptivePopupMenuItem(
                          value: providerMeta.provider,
                          label: providerMeta.displayName,
                        ),
                      )
                      .toList(),
                  icon: AppSettingsRow.navigation(
                    title: l10n.aiProviderLabel,
                    subtitle: AiService.instance
                        .getProviderMetadata(_selectedProvider)
                        .displayName,
                  ),
                ),
                if (_selectedProvider == AiProvider.appleFoundation) ...[
                  const Divider(height: 1),
                  AppInfoRow(
                    leading: Icon(
                      _isAppleFoundationAvailable
                          ? LucideIcons.shield_check
                          : LucideIcons.circle_alert,
                      color: _isAppleFoundationAvailable
                          ? const Color(0xFF34C759)
                          : Colors.orange,
                    ),
                    title: _isAppleFoundationAvailable
                        ? 'Funktioniert 100% offline auf dem Gerät'
                        : 'In den iOS-Einstellungen aktivieren',
                    subtitle: _isAppleFoundationAvailable
                        ? 'Keine Datenübertragung, keine API-Kosten.'
                        : null,
                  ),
                ],
                if (_selectedProvider != AiProvider.ollama &&
                    _selectedProvider != AiProvider.custom &&
                    _selectedProvider != AiProvider.appleFoundation) ...[
                  const Divider(height: 1),
                  Skeletonizer(
                    enabled: _isLoadingModels,
                    child: PlatformAdaptivePopupMenu<String>(
                      selectedValue:
                          _selectedModel.isNotEmpty ? _selectedModel : null,
                      onSelected: (val) {
                        if (!_isLoadingModels) _onModelChanged(val);
                      },
                      items: _modelOptions
                          .map(
                            (model) => PlatformAdaptivePopupMenuItem(
                              value: model.id,
                              label: model.label,
                            ),
                          )
                          .toList(),
                      icon: AppSettingsRow.navigation(
                        title: l10n.aiModelLabel,
                        subtitle: _modelOptions
                                .cast<AiModelOption?>()
                                .firstWhere(
                                  (m) => m?.id == _selectedModel,
                                  orElse: () => null,
                                )
                                ?.label ??
                            (_selectedModel.isNotEmpty ? _selectedModel : '–'),
                      ),
                    ),
                  ),
                  if (!_isLoadingModels && _modelListError != null) ...[
                    const SizedBox(height: 8),
                    _buildModelListFallbackNotice(
                      l10n,
                      theme,
                      _modelListError!,
                    ),
                  ],
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
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
                      if (_selectedProvider != AiProvider.ollama &&
                          _selectedProvider != AiProvider.appleFoundation) ...[
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
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          if (_selectedProvider !=
                              AiProvider.appleFoundation) ...[
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
                                              AiProvider.appleFoundation) &&
                                      !_isTesting)
                                  ? _testConnection
                                  : null,
                              label: l10n.aiTestConnection,
                              tooltip: l10n.aiTestConnection,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedProvider != AiProvider.appleFoundation) ...[
                        const SizedBox(height: 8),
                        Theme(
                          data: theme.copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding:
                                const EdgeInsets.only(top: 8, bottom: 4),
                            title: Text(
                              l10n.aiAdvancedOptionsTitle,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.settingsRequestTimeout,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          l10n.settingsSeconds(_timeoutSeconds),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
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
                                    divisions: 29,
                                    label:
                                        l10n.settingsSeconds(_timeoutSeconds),
                                    activeColor: theme.colorScheme.primary,
                                    onChanged: (value) async {
                                      final seconds = value.round();
                                      setState(() => _timeoutSeconds = seconds);
                                      await AiService.instance
                                          .setAiTimeoutSeconds(seconds);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: DesignConstants.spacingL),

          // --- Photo Storage & Retention ---
          AppSectionHeader(title: l10n.mealPhotoStorageSection),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlatformAdaptivePopupMenu<int>(
                selectedValue: _retentionDays,
                onSelected: (val) {
                  setState(() => _retentionDays = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.mealPhotoRetentionSaved)),
                  );
                },
                items: [
                  for (final days in [30, 90, 180, 365])
                    PlatformAdaptivePopupMenuItem(
                      value: days,
                      label: days == 180
                          ? '${l10n.mealPhotoRetentionDays(days)} ${l10n.mealPhotoRetentionDefaultSuffix}'
                          : l10n.mealPhotoRetentionDays(days),
                    ),
                  PlatformAdaptivePopupMenuItem(
                    value: -1,
                    label: l10n.mealPhotoRetentionUnlimited,
                  ),
                ],
                icon: AppSettingsRow.navigation(
                  title: l10n.mealPhotoRetentionTitle,
                  subtitle: _retentionDays == -1
                      ? l10n.mealPhotoRetentionUnlimited
                      : (_retentionDays == 180
                          ? '${l10n.mealPhotoRetentionDays(_retentionDays)} ${l10n.mealPhotoRetentionDefaultSuffix}'
                          : l10n.mealPhotoRetentionDays(_retentionDays)),
                ),
              ),
              const Divider(height: 1),
              AppSettingsRow(
                title: l10n.mealPhotoDeleteAll,
                subtitle: l10n.mealPhotoRetentionBody,
                leading: const Icon(LucideIcons.trash),
                isDestructive: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.mealPhotoDeleteAllTitle),
                      content: Text(l10n.mealPhotoDeleteAllBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.mealPhotoDeleted)),
                            );
                          },
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: DesignConstants.spacingXL),

          // --- Privacy Disclosure ---
          AppInfoRow(
            title: l10n.aiPrivacySection,
            subtitle: l10n.aiPrivacyDisclosure,
          ),
          const BottomContentSpacer(),
        ],
      ),
    );
  }
}

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
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../depth_scan/data/depth_scan_settings.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../diary/presentation/meal_analysis_screen.dart';

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
  bool _isLoading = true;
  bool _isLoadingModels = false;
  bool _isTesting = false;
  bool _obscureKey = true;
  bool _hasKey = false;
  int _timeoutSeconds = 60;

  /// Only shown on devices that can actually measure — elsewhere the switch
  /// would advertise something the hardware cannot do.
  bool _hasLidar = false;
  bool _scaleHintEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiSettings));
    _loadSettings();
    unawaited(_loadDepthSettings());
  }

  Future<void> _loadDepthSettings() async {
    final capability = await DepthScanChannel.instance.capability();
    final enabled = await DepthScanSettings.instance.isScaleHintEnabled();
    if (!mounted) return;
    setState(() {
      _hasLidar = capability.depthSupported;
      _scaleHintEnabled = enabled;
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
    final model = await AiService.instance.resolveAndPersistSelectedModel(
      provider,
    );
    final key = await AiService.instance.getApiKey(provider);
    final models = await AiService.instance.getModelOptions(provider);
    final resolvedModel = _resolveModelSelection(model, models, provider);
    final customBaseUrl = await AiService.instance.getCustomBaseUrl();
    final customModel = await AiService.instance.getCustomModel();
    final timeout = await AiService.instance.getAiTimeoutSeconds();

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = resolvedModel;
        _modelOptions = _buildModelOptionsWithSelection(
          models,
          resolvedModel,
          provider,
        );
        _hasKey = key != null && key.isNotEmpty;
        _timeoutSeconds = timeout;
        if (_hasKey) {
          // Show masked placeholder — never display the real key
          _keyController.text = '••••••••••••••••••••';
        }
        _baseUrlController.text = customBaseUrl ?? '';
        _customModelController.text = customModel ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _onProviderChanged(AiProvider? provider) async {
    if (provider == null) return;
    setState(() => _isLoading = true);
    await AiService.instance.setSelectedProvider(provider);
    final selectedModel =
        await AiService.instance.resolveAndPersistSelectedModel(provider);
    final models = await AiService.instance.getModelOptions(provider);
    final resolvedModel = _resolveModelSelection(
      selectedModel,
      models,
      provider,
    );
    await AiService.instance.setSelectedModel(provider, resolvedModel);
    final key = await AiService.instance.getApiKey(provider);
    final customBaseUrl = await AiService.instance.getCustomBaseUrl();
    final customModel = await AiService.instance.getCustomModel();

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = resolvedModel;
        _modelOptions = _buildModelOptionsWithSelection(
          models,
          resolvedModel,
          provider,
        );
        _hasKey = key != null && key.isNotEmpty;
        _keyController.text = _hasKey ? '••••••••••••••••••••' : '';
        _baseUrlController.text = customBaseUrl ?? '';
        _customModelController.text = customModel ?? '';
        _isLoading = false;
      });
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
      });
      return;
    }
    setState(() => _isLoadingModels = true);
    final models = await AiService.instance.getModelOptions(_selectedProvider);
    final selectedModel = await AiService.instance
        .resolveAndPersistSelectedModel(_selectedProvider);
    final resolvedModel = _resolveModelSelection(
      selectedModel,
      models,
      _selectedProvider,
    );
    await AiService.instance.setSelectedModel(_selectedProvider, resolvedModel);
    if (!mounted) return;
    setState(() {
      _selectedModel = resolvedModel;
      _modelOptions = _buildModelOptionsWithSelection(
        models,
        resolvedModel,
        _selectedProvider,
      );
      _isLoadingModels = false;
    });
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
      return [
        AiModelOption(id: defaultModel, label: defaultModel, isFallback: true),
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

  void _openAnimationPreview(BuildContext context) {
    final controller = MealAnalysisController();
    Timer? loopTimer;

    final phases = [
      MealAnalysisPhase.preparing,
      MealAnalysisPhase.analyzing,
      MealAnalysisPhase.matching,
    ];
    int phaseIndex = 0;

    // Slowly cycle through phases every 4.5 seconds for testing
    loopTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      phaseIndex = (phaseIndex + 1) % phases.length;
      controller.value = phases[phaseIndex];
    });

    Navigator.of(context)
        .push(
      MealAnalysisScreen.route(
        controller: controller,
        onCancel: () {
          loopTimer?.cancel();
          Navigator.of(context).pop();
        },
      ),
    )
        .then((_) {
      loopTimer?.cancel();
      controller.dispose();
    });
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
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: false, // always show content
        extendBodyBehindAppBar: true,
        child: ListView(
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
                    ],
                    if (aiEnabled) ...[
                      const SizedBox(height: 12),
                      PlatformAdaptiveDropdownFormField<AiProvider>(
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
                          _selectedProvider != AiProvider.custom) ...[
                        _isLoadingModels
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : PlatformAdaptiveDropdownFormField<String>(
                                initialValue: _selectedModel,
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
                                onChanged: _onModelChanged,
                              ),
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
                      if (_selectedProvider != AiProvider.ollama) ...[
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
                                      LucideIcons.trash_2,
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
                          Expanded(
                            child: AppButton.secondary(
                              onPressed: ((_hasKey ||
                                          _selectedProvider ==
                                              AiProvider.ollama) &&
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

            // --- Animation Testing & Preview ---
            AppSectionHeader(title: 'AI Animation Preview'),
            SummaryCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neural Liquid Orb Animation',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Öffnet den Ladebildschirm im Dauerlauf-Modus, um die visuellen Effekte und Phasen-Übergänge live zu testen.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    AppButton.secondary(
                      onPressed: () => _openAnimationPreview(context),
                      label: 'Animation im Vollbild testen',
                      tooltip: 'Animation im Vollbild testen',
                      icon: LucideIcons.play,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: DesignConstants.spacingL),

            // --- Photo Storage & Retention (Screen E2) ---
            AppSectionHeader(title: l10n.mealPhotoStorageSection),
            SummaryCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: LucideIcons.trash_2,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
    );
  }
}

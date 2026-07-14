import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:flutter_svg/flutter_svg.dart';
import '../../../../generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class WelcomeSlide extends StatefulWidget {
  final bool isRestoring;
  final VoidCallback onContinue;
  final VoidCallback onRestore;

  /// Optional callback for restoring from iCloud. When non-null and on iOS,
  /// a restore button is shown below the manual restore option.
  final VoidCallback? onRestoreICloud;

  /// Whether an iCloud backup was found and is ready to restore.
  final bool hasICloudBackup;

  const WelcomeSlide({
    super.key,
    required this.isRestoring,
    required this.onContinue,
    required this.onRestore,
    this.onRestoreICloud,
    this.hasICloudBackup = false,
  });

  @override
  State<WelcomeSlide> createState() => _WelcomeSlideState();
}

class _WelcomeSlideState extends State<WelcomeSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Trigger entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showICloudButton = (Platform.isIOS || Platform.isMacOS) && widget.onRestoreICloud != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, _visible ? 0 : 20, 0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: 35,
                      spreadRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icon/train-libre_icon_dark_green_no_bg.svg',
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              l10n.onboardingWelcomeTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildFeatureList(l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.onboardingSettingsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            // Primary CTA — continue with profile setup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('onboarding_continue_setup_button'),
                onPressed: widget.isRestoring ? null : widget.onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingL),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.onboardingContinueSetup.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            // Secondary CTA — restore from JSON backup
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.isRestoring ? null : widget.onRestore,
                icon: widget.isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.history),
                label: Text(
                  widget.isRestoring
                      ? l10n.onboardingRestoreImporting
                      : l10n.onboardingRestoreFromBackup,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            // Tertiary CTA — iCloud restore (iOS only)
            if (showICloudButton) ...[
              const SizedBox(height: DesignConstants.spacingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('onboarding_restore_icloud_button'),
                  onPressed: widget.isRestoring ? null : widget.onRestoreICloud,
                  icon: widget.isRestoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.cloud),
                            if (widget.hasICloudBackup)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  label: Text(
                    widget.hasICloudBackup
                        ? '${l10n.onboardingRestoreFromICloud} ✓'
                        : l10n.onboardingRestoreFromICloud,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(AppLocalizations l10n, ThemeData theme) {
    final items = [
      (l10n.onboardingFeatureWorkoutTitle, l10n.onboardingFeatureWorkoutBody),
      (l10n.onboardingFeatureTdeeTitle, l10n.onboardingFeatureTdeeBody),
      (
        l10n.onboardingFeatureNutritionTitle,
        l10n.onboardingFeatureNutritionBody,
      ),
      (l10n.onboardingFeaturePrivacyTitle, l10n.onboardingFeaturePrivacyBody),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.$1}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: item.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

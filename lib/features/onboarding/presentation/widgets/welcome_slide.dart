import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class WelcomeSlide extends StatefulWidget {
  final bool isRestoring;
  final VoidCallback onContinue;
  final VoidCallback onRestore;

  const WelcomeSlide({
    super.key,
    required this.isRestoring,
    required this.onContinue,
    required this.onRestore,
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
    
    return Padding(
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
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildMissionStatement(l10n, theme),
          const SizedBox(height: 48),
          // Primary CTA — continue with profile setup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('onboarding_continue_setup_button'),
              onPressed: widget.isRestoring ? null : widget.onContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          const SizedBox(height: 12),
          // Secondary CTA — restore from backup
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
        ],
      ),
    );
  }

  Widget _buildMissionStatement(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.onboardingMissionTitle.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingMissionBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// lib/features/onboarding/presentation/legal_update_consent_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../app/presentation/legal_screen.dart';

/// Re-consent screen displayed when the Privacy Policy or Terms of Service
/// have been updated to a new version (e.g. v1.6).
class LegalUpdateConsentScreen extends StatefulWidget {
  final Widget nextScreen;

  const LegalUpdateConsentScreen({super.key, required this.nextScreen});

  @override
  State<LegalUpdateConsentScreen> createState() =>
      _LegalUpdateConsentScreenState();
}

class _LegalUpdateConsentScreenState extends State<LegalUpdateConsentScreen> {
  bool _healthDataAccepted = false;
  bool _telemetryAccepted = false;
  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _legalRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _navigateToLegal;
    _legalRecognizer = TapGestureRecognizer()..onTap = _navigateToLegal;
    _loadCurrentTelemetryState();
  }

  Future<void> _loadCurrentTelemetryState() async {
    final isOptedIn = await TelemetryService.instance.isOptedIn();
    if (mounted) {
      setState(() {
        _telemetryAccepted = isOptedIn;
      });
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _legalRecognizer.dispose();
    super.dispose();
  }

  void _navigateToLegal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LegalScreen()),
    );
  }

  Future<void> _acceptAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedConsent', true);
    await prefs.setString('acceptedLegalVersion', kCurrentLegalVersion);

    if (_telemetryAccepted) {
      await TelemetryService.instance.optIn();
    } else {
      await TelemetryService.instance.optOut();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background with app icon
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Opacity(
                  opacity: 0.2,
                  child: SvgPicture.asset(
                    'assets/icon/train-libre_icon_dark_green_no_bg.svg',
                    width: 200,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          // Consent Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignConstants.spacingXL),
              child: SummaryCard(
                padding: const EdgeInsets.all(DesignConstants.spacingXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shield_alert,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    Text(
                      l10n.welcome_back_updated_legal_title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    Text(
                      l10n.legal_update_body(kCurrentLegalVersion),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    // Legal links button
                    Center(
                      child: TextButton(
                        onPressed: _navigateToLegal,
                        child: Text(
                            '${l10n.legal_notice} & ${l10n.privacy_policy}'),
                      ),
                    ),
                    const Divider(),
                    // Mandatory updated privacy policy consent tile
                    _buildConsentTile(
                      value: _healthDataAccepted,
                      onChanged: (val) =>
                          setState(() => _healthDataAccepted = val),
                      text: l10n.i_agree_to_updated_privacy_policy(
                          kCurrentLegalVersion),
                      theme: theme,
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    // Optional anonymous telemetry tile
                    _buildConsentTile(
                      value: _telemetryAccepted,
                      onChanged: (val) =>
                          setState(() => _telemetryAccepted = val),
                      text: l10n.i_agree_to_optional_telemetry,
                      theme: theme,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        onPressed:
                            _healthDataAccepted ? _acceptAndProceed : null,
                        label: l10n.accept_and_continue,
                        tooltip: l10n.accept_and_continue,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    // Clickwrap legal text
                    Text.rich(
                      TextSpan(
                        text: '${l10n.by_tapping_accept_continue} ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.terms_of_service,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _termsRecognizer,
                          ),
                          TextSpan(
                            text: ' ${l10n.and_acknowledge} ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: l10n.privacy_policy,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _legalRecognizer,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignConstants.spacingS,
          horizontal: DesignConstants.spacingXS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 2.0, right: DesignConstants.spacingM),
              child: Icon(
                value ? LucideIcons.circle_check : LucideIcons.circle,
                color: value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/initial_consent_screen.dart

import 'package:flutter/gestures.dart';
import '../../../util/design_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/legal_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';

class InitialConsentScreen extends StatefulWidget {
  final Widget nextScreen;

  const InitialConsentScreen({super.key, required this.nextScreen});

  @override
  State<InitialConsentScreen> createState() => _InitialConsentScreenState();
}

class _InitialConsentScreenState extends State<InitialConsentScreen> {
  bool _healthDataAccepted = false;
  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _legalRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _navigateToLegal;
    _legalRecognizer = TapGestureRecognizer()..onTap = _navigateToLegal;
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
                      l10n.welcome_privacy_title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    Text(
                      l10n.welcome_privacy_body,
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
                    // Single explicit health data consent checkbox
                    CheckboxListTile(
                      value: _healthDataAccepted,
                      onChanged: (val) =>
                          setState(() => _healthDataAccepted = val ?? false),
                      checkColor: theme.colorScheme.onPrimary,
                      title: Text(
                        l10n.i_agree_to_privacy_policy,
                        style: theme.textTheme.bodySmall,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        onPressed: _healthDataAccepted ? _acceptAndProceed : null,
                        label: l10n.accept_and_get_started,
                        tooltip: l10n.accept_and_get_started,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    // Clickwrap legal text matching bodySmall style of checkbox text above
                    Text.rich(
                      TextSpan(
                        text: '${l10n.by_tapping_accept} ',
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
}

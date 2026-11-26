import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';

/// Explains the effort scale without dismissing the active set editor.
Future<void> showRpeHelpSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await showGlassBottomMenu<void>(
    context: context,
    title: l10n.rpeHelpTitle,
    contentBuilder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Text(
            l10n.rpeHelpBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        _EffortGuideCard(
          value: '10',
          title: l10n.rpeMaximumEffort,
          subtitle: l10n.rpeNoReps,
          color: const Color(0xFFEF3E42),
        ),
        const SizedBox(height: 8),
        _EffortGuideCard(
          value: '8',
          title: l10n.rpeHardEffort,
          subtitle: l10n.rpeRepsLeft('2'),
          color: const Color(0xFFF59B23),
        ),
        const SizedBox(height: 8),
        _EffortGuideCard(
          value: '6',
          title: l10n.rpeModerateEffort,
          subtitle: l10n.rpeFourPlus,
          color: const Color(0xFF39C45A),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class _EffortGuideCard extends StatelessWidget {
  const _EffortGuideCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: dark ? 0.25 : 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

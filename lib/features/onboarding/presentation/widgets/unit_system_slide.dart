import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'springy_scale.dart';

class UnitSystemSlide extends StatelessWidget {
  final UnitSystem selectedSystem;
  final ValueChanged<UnitSystem> onSelectSystem;

  const UnitSystemSlide({
    super.key,
    required this.selectedSystem,
    required this.onSelectSystem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingUnitSystemTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingUnitSystemSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SpringyScale(
            isSelected: selectedSystem == UnitSystem.metric,
            onTap: () => onSelectSystem(UnitSystem.metric),
            child: _UnitSystemChoiceCard(
              title: l10n.onboardingUnitMetric,
              subtitle: l10n.onboardingUnitMetricSubtitle,
              icon: LucideIcons.ruler,
              selected: selectedSystem == UnitSystem.metric,
            ),
          ),
          const SizedBox(height: 16),
          SpringyScale(
            isSelected: selectedSystem == UnitSystem.imperial,
            onTap: () => onSelectSystem(UnitSystem.imperial),
            child: _UnitSystemChoiceCard(
              title: l10n.onboardingUnitImperial,
              subtitle: l10n.onboardingUnitImperialSubtitle,
              icon: LucideIcons.globe,
              selected: selectedSystem == UnitSystem.imperial,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSystemChoiceCard extends StatelessWidget {
  const _UnitSystemChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.surfaceContainerLow.withValues(alpha: selected ? 1.0 : 0.6),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 34,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? LucideIcons.circle_check : LucideIcons.circle,
            color: selected ? cs.primary : cs.outline,
          ),
        ],
      ),
    );
  }
}

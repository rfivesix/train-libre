import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/experience_level_service.dart';
import '../../../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'springy_scale.dart';

class ExperienceLevelSlide extends StatelessWidget {
  final ExperienceLevel selectedLevel;
  final ValueChanged<ExperienceLevel> onSelectLevel;

  const ExperienceLevelSlide({
    super.key,
    required this.selectedLevel,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_experience_level_page'),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignConstants.spacingXL),
            Text(
              l10n.onboardingExperienceLevelTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.onboardingExperienceLevelSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            SpringyScale(
              isSelected: selectedLevel == ExperienceLevel.beginner,
              onTap: () => onSelectLevel(ExperienceLevel.beginner),
              child: _ExperienceLevelChoiceCard(
                key: const Key('onboarding_experience_beginner_card'),
                title: l10n.experienceLevelBeginner,
                subtitle: l10n.experienceLevelBeginnerDescription,
                icon: LucideIcons.sprout,
                selected: selectedLevel == ExperienceLevel.beginner,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SpringyScale(
              isSelected: selectedLevel == ExperienceLevel.advanced,
              onTap: () => onSelectLevel(ExperienceLevel.advanced),
              child: _ExperienceLevelChoiceCard(
                key: const Key('onboarding_experience_advanced_card'),
                title: l10n.experienceLevelAdvanced,
                subtitle: l10n.experienceLevelAdvancedDescription,
                icon: LucideIcons.dumbbell,
                selected: selectedLevel == ExperienceLevel.advanced,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SpringyScale(
              isSelected: selectedLevel == ExperienceLevel.pro,
              onTap: () => onSelectLevel(ExperienceLevel.pro),
              child: _ExperienceLevelChoiceCard(
                key: const Key('onboarding_experience_pro_card'),
                title: l10n.experienceLevelPro,
                subtitle: l10n.experienceLevelProDescription,
                icon: LucideIcons.flame,
                selected: selectedLevel == ExperienceLevel.pro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceLevelChoiceCard extends StatelessWidget {
  const _ExperienceLevelChoiceCard({
    super.key,
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
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: DesignConstants.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXS),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Icon(
            selected ? LucideIcons.circle_dot : LucideIcons.circle,
            color: selected ? cs.primary : cs.outline,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/app_link_row.dart';

class ExerciseMappingCard extends StatelessWidget {
  const ExerciseMappingCard({super.key, required this.onMapPressed});

  final VoidCallback? onMapPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppLinkRow(
      title: l10n.mapExercisesTitle,
      subtitle: l10n.mapExercisesDescription,
      onTap: onMapPressed ?? () {},
    );
  }
}

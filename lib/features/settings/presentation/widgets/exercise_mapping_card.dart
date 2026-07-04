import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/app_link_row.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ExerciseMappingCard extends StatelessWidget {
  const ExerciseMappingCard({super.key, required this.onMapPressed});

  final VoidCallback? onMapPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppLinkRow(
      title: l10n.mapExercisesTitle,
      subtitle: l10n.mapExercisesDescription,
      onTap: onMapPressed ?? () {},
    );
  }
}

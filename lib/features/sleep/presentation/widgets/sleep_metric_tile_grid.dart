import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../data/sleep_day_repository.dart';

class SleepMetricTileGrid extends StatelessWidget {
  const SleepMetricTileGrid({super.key, required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueSummaryCard(
      label: l10n.sleepMetricInterruptionsTitle,
      value: overview.interruptionsCount == null
          ? l10n.sleepMetricUnavailable
          : '${overview.interruptionsCount}',
    );
  }
}

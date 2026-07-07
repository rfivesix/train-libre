import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';
import '../../../../widgets/common/global_app_bar.dart';
import '../../../../widgets/common/algorithm_info_sheet.dart';
import '../../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;
import '../../../statistics/domain/timeframe_block.dart';

enum SleepPeriodScope { day, week, month }

extension SleepPeriodScopeTimeframe on SleepPeriodScope {
  TimeframeBlock get block {
    switch (this) {
      case SleepPeriodScope.day:
        return TimeframeBlock.day;
      case SleepPeriodScope.week:
        return TimeframeBlock.week;
      case SleepPeriodScope.month:
        return TimeframeBlock.month;
    }
  }
}

class SleepPeriodScopeLayout extends StatelessWidget {
  const SleepPeriodScopeLayout({
    super.key,
    required this.appBarTitle,
    required this.selectedScope,
    required this.anchorDate,
    required this.onScopeChanged,
    required this.onShiftPeriod,
    required this.onAnchorChanged,
    required this.child,
  });

  final String appBarTitle;
  final SleepPeriodScope selectedScope;
  final DateTime anchorDate;
  final ValueChanged<SleepPeriodScope> onScopeChanged;
  final ValueChanged<int> onShiftPeriod;
  final ValueChanged<DateTime> onAnchorChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final localeCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: appBarTitle,
        actions: [
          AlgorithmInfoButton(
            title: l10n.infoSleepTitle,
            explanation: l10n.infoSleepExplanation,
            keyPoints: l10n.infoSleepKeyPoints.split('\n'),
            technicalTitle: l10n.infoSleepTechnicalTitle,
            technicalExplanation: l10n.infoSleepTechnicalExplanation,
            markdownAssetPath: 'documentation/features/sleep_scoring_engine.md',
            citationUrl:
                'https://rfivesix.github.io/train-libre/sleep-score/#evidence',
            iconColor: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding + 16,
          left: 0,
          right: 0,
        ),
        children: [
          TimeRangeFilter(
            ranges: [
              l10n.sleepScopeDay,
              l10n.sleepScopeWeek,
              l10n.sleepScopeMonth,
            ],
            selectedIndex: selectedScope.index,
            onSelected: (index) =>
                onScopeChanged(SleepPeriodScope.values[index]),
            onPrevious: () => onShiftPeriod(-1),
            onNext: () => onShiftPeriod(1),
            displayDate: _periodLabel(localeCode),
            onTapDateDisplay: () async {
              final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
                context: context,
                activeBlock: selectedScope.block,
                initialAnchor: anchorDate,
                earliestAvailableDay: DateTime(2020),
              );
              if (selected != null) {
                onAnchorChanged(selected);
              }
            },
            nextEnabled: selectedScope.block.getBounds(anchorDate, DateTime(2020)).end.isBefore(DateTime.now()),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          child,
        ],
      ),
    );
  }

  String _periodLabel(String localeCode) {
    final normalized = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
    );
    switch (selectedScope) {
      case SleepPeriodScope.day:
        return DateFormat.yMMMd(localeCode).format(normalized);
      case SleepPeriodScope.week:
        final start = normalized.subtract(
          Duration(days: normalized.weekday - DateTime.monday),
        );
        final end = start.add(const Duration(days: 6));
        return '${DateFormat.MMMd(localeCode).format(start)} - ${DateFormat.MMMd(localeCode).format(end)}';
      case SleepPeriodScope.month:
        return DateFormat.yMMMM(
          localeCode,
        ).format(DateTime(normalized.year, normalized.month, 1));
    }
  }
}

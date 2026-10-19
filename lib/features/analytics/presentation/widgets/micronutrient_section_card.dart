import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/timeframe_label_formatter.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/global_app_bar.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/time_range_filter.dart';
import '../../../statistics/data/bls_micronutrient_analytics_data_adapter.dart';
import '../../../statistics/domain/timeframe_block.dart';

class MicronutrientSectionCard extends StatefulWidget {
  const MicronutrientSectionCard({
    super.key,
    required this.block,
    required this.anchor,
    required this.isRolling,
    this.adapter = const BlsMicronutrientAnalyticsDataAdapter(),
  });

  final TimeframeBlock block;
  final DateTime anchor;
  final bool isRolling;
  final BlsMicronutrientAnalyticsDataAdapter adapter;

  @override
  State<MicronutrientSectionCard> createState() =>
      _MicronutrientSectionCardState();
}

class _MicronutrientSectionCardState extends State<MicronutrientSectionCard> {
  late Future<MicronutrientPeriodSummary> _summary;
  String _languageCode = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      _load();
    }
  }

  @override
  void didUpdateWidget(MicronutrientSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block ||
        oldWidget.anchor != widget.anchor ||
        oldWidget.isRolling != widget.isRolling) {
      _load();
    }
  }

  void _load() {
    _summary = widget.adapter.fetchSummary(
      range: BlsMicronutrientAnalyticsDataAdapter.rangeFor(
        block: widget.block,
        anchor: widget.anchor,
        isRolling: widget.isRolling,
      ),
      languageCode: _languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return FutureBuilder<MicronutrientPeriodSummary>(
      future: _summary,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        Widget buildCard({VoidCallback? onTap}) => SummaryCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.statisticsMicronutrientsTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingXS),
                    Text(
                      l10n.statisticsMicronutrientsPreviewSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            );

        return MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (cardContext) => buildCard(
              onTap: () => Navigator.of(context).push(
                CardMorphRoute<void>(
                  sourceContext: cardContext,
                  sourceBuilder: (_) => buildCard(),
                  onSourceVisibilityChanged: setHidden,
                  builder: (_) => MicronutrientStatisticsScreen(
                    summary: summary,
                    initialBlock: widget.block,
                    initialAnchorDate: widget.anchor,
                    initialIsRolling: widget.isRolling,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NutrientValueRow extends StatelessWidget {
  const _NutrientValueRow({
    required this.nutrient,
    required this.localeName,
  });

  final MicronutrientAverage nutrient;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final number =
        NumberFormat('0.##', localeName).format(nutrient.averagePerLoggedDay);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            nutrient.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingM),
        Text('$number ${nutrient.unit}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end),
      ],
    );
  }
}

class MicronutrientStatisticsScreen extends StatefulWidget {
  const MicronutrientStatisticsScreen({
    super.key,
    this.summary,
    this.initialBlock = TimeframeBlock.month,
    this.initialAnchorDate,
    this.initialIsRolling = true,
    this.initialDay,
  });

  final MicronutrientPeriodSummary? summary;
  final TimeframeBlock initialBlock;
  final DateTime? initialAnchorDate;
  final bool initialIsRolling;
  final DateTime? initialDay;

  @override
  State<MicronutrientStatisticsScreen> createState() =>
      _MicronutrientStatisticsScreenState();
}

class _MicronutrientStatisticsScreenState
    extends State<MicronutrientStatisticsScreen> {
  final ScrollController _scrollController = ScrollController();
  static const _blocks = [
    TimeframeBlock.day,
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.year,
    TimeframeBlock.maxBlock,
  ];
  late TimeframeBlock _block;
  late DateTime _anchor;
  late bool _rolling;
  late Future<MicronutrientPeriodSummary> _future;
  String _languageCode = '';

  @override
  void initState() {
    super.initState();
    _block =
        widget.initialDay != null ? TimeframeBlock.day : widget.initialBlock;
    _anchor = widget.initialDay ?? widget.initialAnchorDate ?? DateTime.now();
    _rolling = widget.initialDay == null && widget.initialIsRolling;
    _load(initialSummary: widget.summary);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      _load();
    }
  }

  void _load({MicronutrientPeriodSummary? initialSummary}) {
    if (initialSummary != null &&
        widget.initialDay == null &&
        _block == widget.initialBlock) {
      _future = Future.value(initialSummary);
      return;
    }
    final bounds = _rolling
        ? _block.getRollingBounds()
        : _block.getBounds(_anchor, DateTime(2020));
    _future = const BlsMicronutrientAnalyticsDataAdapter().fetchSummary(
      range: bounds,
      languageCode: _languageCode,
    );
  }

  void _setBlock(int index) {
    setState(() {
      _block = _blocks[index];
      _anchor = DateTime.now();
      _rolling = _block != TimeframeBlock.day;
      _load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _anchor,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (picked == null || !mounted) return;
    setState(() {
      _block = TimeframeBlock.day;
      _anchor = picked;
      _rolling = false;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
          title: l10n.statisticsMicronutrientsTitle,
          actions: [
            IconButton(
              tooltip: l10n.shareAsText,
              onPressed: _share,
              icon: Icon(DesignConstants.adaptiveShareIcon),
            ),
          ],
          bottom: TimeRangeFilter(
            ranges: [
              l10n.filter1DayShort,
              l10n.filter7DaysShort,
              l10n.filter1MonthShort,
              l10n.filter3MonthsShort,
              l10n.filter6MonthsShort,
              l10n.filter1YearShort,
              l10n.filterMax
            ],
            selectedIndex: _blocks.indexOf(_block),
            onSelected: _setBlock,
            displayDate: _block == TimeframeBlock.day
                ? dateFormat.format(_anchor)
                : (_rolling
                    ? TimeframeLabelFormatter.formatRolling(_block, l10n)
                    : TimeframeLabelFormatter.format(_block, _anchor, l10n)),
            onPrevious: _block == TimeframeBlock.maxBlock
                ? null
                : () => setState(() {
                      _rolling = false;
                      _anchor = _block.shift(_anchor, -1);
                      _load();
                    }),
            onNext: _block == TimeframeBlock.maxBlock ||
                    _anchor.isAfter(
                        DateTime.now().subtract(const Duration(days: 1)))
                ? null
                : () => setState(() {
                      _anchor = _block.shift(_anchor, 1);
                      _load();
                    }),
            onTapDateDisplay: _pickDate,
            showDateNavigation: _block != TimeframeBlock.maxBlock,
          )),
      body: FutureBuilder<MicronutrientPeriodSummary>(
        future: _future,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          if (summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final grouped = <String, List<MicronutrientAverage>>{};
          for (final nutrient in summary.nutrients) {
            grouped.putIfAbsent(nutrient.group, () => []).add(nutrient);
          }
          final isDay = _block == TimeframeBlock.day;
          return CupertinoScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 4,
            thicknessWhileDragging: 8,
            mainAxisMargin: 0,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                  DesignConstants.cardPaddingInternal,
                  MediaQuery.paddingOf(context).top +
                      DesignConstants.cardPadding.top,
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.cardPadding.bottom),
              children: [
                Text(
                    isDay
                        ? dateFormat.format(_anchor)
                        : '${l10n.statisticsAveragePerLoggedDay} · ${summary.blsLoggedDays} ${l10n.statisticsMicronutrientsLoggedDays}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: DesignConstants.spacingXS),
                Text(l10n.statisticsMicronutrientsCoverage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: DesignConstants.spacingS),
                if (summary.nutrients.isEmpty)
                  Text(summary.catalogAvailable
                      ? l10n.statisticsMicronutrientsNoData
                      : l10n.blsNutrientsUnavailable),
                for (final entry in grouped.entries) ...[
                  AppSectionHeader(
                    title: entry.key,
                    padding: const EdgeInsets.only(
                      top: DesignConstants.spacingM,
                      bottom: DesignConstants.spacingS,
                    ),
                  ),
                  for (final nutrient in entry.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignConstants.spacingS,
                      ),
                      child: _NutrientValueRow(
                        nutrient: nutrient,
                        localeName: l10n.localeName,
                      ),
                    ),
                  const SizedBox(height: DesignConstants.spacingM),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _share() async {
    final summary = await _future;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final rangeLabel = _block == TimeframeBlock.day
        ? dateFormat.format(_anchor)
        : (_rolling
            ? TimeframeLabelFormatter.formatRolling(_block, l10n)
            : TimeframeLabelFormatter.format(_block, _anchor, l10n));
    final lines = <String>[
      l10n.statisticsMicronutrientsTitle,
      rangeLabel,
      _block == TimeframeBlock.day
          ? dateFormat.format(_anchor)
          : l10n.statisticsAveragePerLoggedDay,
      '${summary.blsLoggedDays} ${l10n.statisticsMicronutrientsLoggedDays}',
      '${l10n.statisticsMicronutrientsCoverage}: ${summary.blsFoodEntries}',
      '',
    ];
    var previousGroup = '';
    for (final nutrient in summary.nutrients) {
      if (nutrient.group != previousGroup) {
        lines.add('');
        lines.add(nutrient.group);
        previousGroup = nutrient.group;
      }
      lines.add(
        '- ${nutrient.name}: ${NumberFormat('0.##', l10n.localeName).format(nutrient.averagePerLoggedDay)} ${nutrient.unit} (${nutrient.loggedDays} ${l10n.statisticsMicronutrientsLoggedDays})',
      );
    }
    await SharePlus.instance.share(
      ShareParams(
        text: lines.join('\n'),
        subject: l10n.statisticsMicronutrientsTitle,
      ),
    );
  }
}

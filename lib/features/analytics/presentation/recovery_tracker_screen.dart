import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../../../services/profile_service.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/analytics_state.dart';
import '../../statistics/domain/recovery_domain_service.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_section_header.dart';
import 'widgets/analytics_chart_defaults.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';
import '../../../widgets/common/dual_body_highlighter.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _muscleKeys = {};

  bool _isRecoveringExpanded = false;
  bool _isReadyExpanded = false;
  bool _isFreshExpanded = false;

  bool _isLoading = true;
  RecoveryAnalyticsPayload _recovery = const RecoveryAnalyticsPayload(
    hasData: false,
    overallState: '',
    totals: RecoveryTotalsPayload(
      recovering: 0,
      ready: 0,
      fresh: 0,
      tracked: 0,
    ),
    muscles: [],
  );

  @override
  void initState() {
    super.initState();
    _loadRecovery();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecovery() async {
    setState(() => _isLoading = true);
    final data = await WorkoutLocalDataSource.instance.getRecoveryAnalytics();
    if (!mounted) return;
    setState(() {
      _recovery = RecoveryAnalyticsPayload.fromMap(data);
      _isLoading = false;
    });
  }

  String _overallLabel(AppLocalizations l10n, String? state) {
    return StatisticsPresentationFormatter.recoveryOverallLabel(l10n, state);
  }

  String _stateLabel(AppLocalizations l10n, String state) {
    return StatisticsPresentationFormatter.recoveryStateLabel(l10n, state);
  }

  Color _stateColor(BuildContext context, String state) {
    return StatisticsPresentationFormatter.recoveryStateColor(context, state);
  }

  String _fatigueContextLabel(AppLocalizations l10n, bool highFatigue) {
    return highFatigue
        ? l10n.recoveryFatigueContextHigh
        : l10n.recoveryFatigueContextBaseline;
  }

  String _explanationForMuscle(
    AppLocalizations l10n,
    RecoveryMusclePayload muscle,
  ) {
    final rawName = muscle.muscleGroup;
    final muscleName =
        StatisticsPresentationFormatter.muscleGroupLabel(l10n, rawName);
    final hours = muscle.hoursSinceLastSignificantLoad.round();
    final highFatigue = muscle.highSessionFatigue;

    if (highFatigue) {
      return l10n.recoveryExplanationWithHighFatigue(muscleName, hours);
    }
    return l10n.recoveryExplanationBasic(muscleName, hours);
  }

  bool _shouldHideMuscle(String name) {
    return RecoveryDomainService.shouldHideMuscle(name) ||
        StatisticsPresentationFormatter.isOtherCategoryLabel(name);
  }

  double _readinessScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.readinessScore(
      hoursSinceLastSignificantLoad: muscle.hoursSinceLastSignificantLoad,
      recoveringUpperHours: muscle.recoveringUpperHours.toDouble(),
      readyUpperHours: muscle.readyUpperHours.toDouble(),
    );
  }

  double _lastLoadPressureScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.lastLoadPressureScore(
      lastEquivalentSets: muscle.lastEquivalentSets,
      highSessionFatigue: muscle.highSessionFatigue,
    );
  }

  String _lastLoadPressureLabel(
    AppLocalizations l10n,
    RecoveryMusclePayload muscle,
  ) {
    final pressureScore = _lastLoadPressureScore(muscle);
    final level = RecoveryDomainService.pressureLevelForScore(pressureScore);
    final levelLabel =
        StatisticsPresentationFormatter.recoveryPressureLevelLabel(l10n, level);
    return l10n.recoveryLastLoadPressure(levelLabel);
  }

  String _formatEquivalentSets(BuildContext context, double value) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final format = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return format.format(value);
  }

  Color _overallStateColor(BuildContext context, String overallState) {
    switch (overallState) {
      case RecoveryDomainService.overallMostlyRecovered:
        return _stateColor(context, RecoveryDomainService.stateFresh);
      case RecoveryDomainService.overallMixedRecovery:
        return _stateColor(context, RecoveryDomainService.stateReady);
      case RecoveryDomainService.overallSeveralRecovering:
        return _stateColor(context, RecoveryDomainService.stateRecovering);
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Widget _buildReadinessPill(
    BuildContext context,
    AppLocalizations l10n, {
    required String state,
    required int count,
    required int total,
  }) {
    final color = _stateColor(context, state);
    final percent = total > 0 ? (count / total * 100).round() : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(DesignConstants.borderRadiusL);
    // Blend: card surface + color tint as a single background
    final surfaceBase = isDark
        ? DesignConstants.summaryCardDarkMode
        : theme.colorScheme.surface.withValues(alpha: 0.95);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              blurRadius: 9,
              offset: const Offset(0, 3),
              color: theme.colorScheme.shadow
                  .withValues(alpha: isDark ? 0.2 : 0.08),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: surfaceBase,
              borderRadius: radius,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: color,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXS),
                Text(
                  _stateLabel(l10n, state).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percent%',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildContextChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildScaleLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  int _computeConsistentTrackedCount({
    required int tracked,
    required int recovering,
    required int ready,
    required int fresh,
  }) {
    // Keep distribution denominators consistent even if persisted tracked total
    // is missing or temporarily lower than visible state buckets.
    final trackedFromStates = recovering + ready + fresh;
    if (tracked <= 0) {
      return trackedFromStates;
    }
    return tracked < trackedFromStates ? trackedFromStates : tracked;
  }

  void _scrollToMuscle(String muscleGroup) {
    final muscle = _recovery.muscles.firstWhere(
      (m) => m.muscleGroup == muscleGroup,
      orElse: () => _recovery.muscles.first,
    );

    setState(() {
      if (muscle.state == RecoveryDomainService.stateRecovering) {
        _isRecoveringExpanded = true;
      } else if (muscle.state == RecoveryDomainService.stateReady) {
        _isReadyExpanded = true;
      } else if (muscle.state == RecoveryDomainService.stateFresh) {
        _isFreshExpanded = true;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _muscleKeys[muscleGroup];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  Widget _buildBodyView(
    BuildContext context,
    List<RecoveryMusclePayload> muscles,
  ) {
    final List<BodyPartHighlightData> highlights = [];

    for (final muscle in muscles) {
      final slugs = BodySlugMapper.fromRawName(muscle.muscleGroup);
      final color = _stateColor(context, muscle.state);

      for (final slug in slugs) {
        highlights.add(
          BodyPartHighlightData(
            slug: slug,
            color: color,
            payload: muscle.muscleGroup,
          ),
        );
      }
    }

    return DualBodyHighlighter(
      gender: context.watch<ProfileService>().gender.toBodyGender(),
      frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
      backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
      height: 320,
      onBodyPartTap: (slug, data) {
        if (data.payload is String) {
          _scrollToMuscle(data.payload as String);
        }
      },
    );
  }

  Widget _buildMuscleCard(
    BuildContext context,
    AppLocalizations l10n,
    RecoveryMusclePayload muscle,
  ) {
    final rawName = muscle.muscleGroup;
    final muscleName =
        StatisticsPresentationFormatter.muscleGroupLabel(l10n, rawName);
    final state = muscle.state;
    final stateColor = _stateColor(context, state);
    final hours = muscle.hoursSinceLastSignificantLoad.round();
    final highFatigue = muscle.highSessionFatigue;
    final eqSets = muscle.lastEquivalentSets;
    final recoveringUpper = muscle.recoveringUpperHours;
    final readyUpper = muscle.readyUpperHours;
    final readinessScore = _readinessScore(muscle);
    final readinessColor = stateColor;

    final key = _muscleKeys.putIfAbsent(rawName, () => GlobalKey());

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscleName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: DesignConstants.spacingXS),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _stateLabel(l10n, state),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildContextChip(
              context,
              l10n.recoveryRecentLoad(_formatEquivalentSets(context, eqSets)),
            ),
            _buildContextChip(
              context,
              l10n.recoveryLastLoadedHours(hours),
            ),
            _buildContextChip(
              context,
              _fatigueContextLabel(l10n, highFatigue),
            ),
            _buildContextChip(
              context,
              _lastLoadPressureLabel(l10n, muscle),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Row(
          children: [
            Text(
              l10n.recoveryReadinessLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Text(
              readinessScore.toStringAsFixed(0),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: readinessColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: readinessScore / 100,
            minHeight: 8,
            color: readinessColor,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: DesignConstants.spacingXS),
          child: Row(
            children: [
              _buildScaleLabel(context, '0'),
              const Spacer(),
              _buildScaleLabel(context, '50'),
              const Spacer(),
              _buildScaleLabel(context, '100'),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.recoveryCurrentWindow(recoveringUpper, readyUpper),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _explanationForMuscle(l10n, muscle),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Widget _buildZoneCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required List<RecoveryMusclePayload> muscles,
    required Color color,
    required bool isExpanded,
    required ValueChanged<bool> onToggle,
  }) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
      child: SummaryCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onToggle(!isExpanded),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingL,
                    vertical: DesignConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        Expanded(
                          child: Text(
                            '$title (${muscles.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            LucideIcons.chevron_down,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: DesignConstants.spacingS,
                          left: DesignConstants.spacingXL),
                      child: Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: muscles.map((m) {
                          final label =
                              StatisticsPresentationFormatter.muscleGroupLabel(
                                  l10n, m.muscleGroup);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const SizedBox(height: DesignConstants.spacingS),
                    ...muscles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final muscle = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index > 0)
                            Divider(
                              height: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.08),
                            ),
                          _buildMuscleCard(context, l10n, muscle),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final recovering = _recovery.totals.recovering;
    final ready = _recovery.totals.ready;
    final fresh = _recovery.totals.fresh;
    final tracked = _computeConsistentTrackedCount(
      tracked: _recovery.totals.tracked,
      recovering: recovering,
      ready: ready,
      fresh: fresh,
    );
    final hasData = _recovery.hasData;

    final muscles = _recovery.muscles;
    final visibleMuscles = muscles
        .where((m) => !_shouldHideMuscle(m.muscleGroup))
        .toList(growable: false);

    final recoveringMuscles = visibleMuscles
        .where((m) => m.state == RecoveryDomainService.stateRecovering)
        .toList();
    final readyMuscles = visibleMuscles
        .where((m) => m.state == RecoveryDomainService.stateReady)
        .toList();
    final freshMuscles = visibleMuscles
        .where((m) => m.state == RecoveryDomainService.stateFresh)
        .toList();

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.recoveryTrackerTitle,
        actions: [
          AlgorithmInfoButton(
            title: l10n.infoRecoveryTitle,
            explanation: l10n.infoRecoveryExplanation,
            keyPoints: l10n.infoRecoveryKeyPoints.split('\n'),
            technicalTitle: l10n.infoRecoveryTechnicalTitle,
            technicalExplanation: l10n.infoRecoveryTechnicalExplanation,
            markdownAssetPath:
                'documentation/features/muscle_recovery_model.md',
            citationUrl:
                'https://rfivesix.github.io/train-libre/recovery/#evidence',
            iconColor: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: !_recovery.hasData,
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
              controller: _scrollController,
              padding: DesignConstants.screenPadding.copyWith(
                top: DesignConstants.screenPadding.top + topPadding,
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: l10n.metricsMuscleReadiness,
                    padding: const EdgeInsets.only(
                        left: DesignConstants.spacingXS, bottom: 6),
                  ),
                  Text(
                    _overallLabel(l10n, _recovery.overallState),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _overallStateColor(
                            context,
                            _recovery.overallState,
                          ),
                        ),
                  ),
                  if (hasData && tracked > 0) ...[
                    const SizedBox(height: DesignConstants.spacingL),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            if (recovering > 0)
                              Expanded(
                                flex: recovering,
                                child: ColoredBox(
                                  color: _stateColor(
                                    context,
                                    RecoveryDomainService
                                        .stateRecovering,
                                  ),
                                ),
                              ),
                            if (ready > 0)
                              Expanded(
                                flex: ready,
                                child: ColoredBox(
                                  color: _stateColor(
                                    context,
                                    RecoveryDomainService.stateReady,
                                  ),
                                ),
                              ),
                            if (fresh > 0)
                              Expanded(
                                flex: fresh,
                                child: ColoredBox(
                                  color: _stateColor(
                                    context,
                                    RecoveryDomainService.stateFresh,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildReadinessPill(
                          context,
                          l10n,
                          state: RecoveryDomainService.stateRecovering,
                          count: recovering,
                          total: tracked,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        _buildReadinessPill(
                          context,
                          l10n,
                          state: RecoveryDomainService.stateReady,
                          count: ready,
                          total: tracked,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        _buildReadinessPill(
                          context,
                          l10n,
                          state: RecoveryDomainService.stateFresh,
                          count: fresh,
                          total: tracked,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    l10n.recoveryHeuristicDisclaimer,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  AppSectionHeader(
                    title: l10n.analyticsRecentDistributionHeatmap,
                    padding: const EdgeInsets.only(
                        left: DesignConstants.spacingXS, bottom: 6),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          if (!hasData)
                            AnalyticsChartDefaults.stateView(
                              context: context,
                              l10n: l10n,
                              status: AnalyticsStatus.empty,
                              emptyLabel: l10n.recoveryNoDataBody,
                            )
                          else
                            RepaintBoundary(
                              child: _buildBodyView(
                                context,
                                visibleMuscles,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  AppSectionHeader(
                    title: l10n.recoveryByMuscleTitle,
                    padding: const EdgeInsets.only(
                        left: DesignConstants.spacingXS, bottom: 6),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  if (!hasData)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: DesignConstants.spacingS),
                      child: Text(l10n.recoveryNoDataBody),
                    )
                  else ...[
                    _buildZoneCard(
                      context,
                      l10n,
                      title: l10n.recoveryStateRecovering,
                      muscles: recoveringMuscles,
                      color: _stateColor(
                          context, RecoveryDomainService.stateRecovering),
                      isExpanded: _isRecoveringExpanded,
                      onToggle: (val) =>
                          setState(() => _isRecoveringExpanded = val),
                    ),
                    _buildZoneCard(
                      context,
                      l10n,
                      title: l10n.localeName.startsWith('de')
                          ? 'Gemischt / Bereit'
                          : 'Mixed / Ready',
                      muscles: readyMuscles,
                      color: _stateColor(
                          context, RecoveryDomainService.stateReady),
                      isExpanded: _isReadyExpanded,
                      onToggle: (val) => setState(() => _isReadyExpanded = val),
                    ),
                    _buildZoneCard(
                      context,
                      l10n,
                      title: l10n.recoveryStateFresh,
                      muscles: freshMuscles,
                      color: _stateColor(
                          context, RecoveryDomainService.stateFresh),
                      isExpanded: _isFreshExpanded,
                      onToggle: (val) => setState(() => _isFreshExpanded = val),
                    ),
                  ]
                ],
              ),
            ),
      ),
    );
  }
}

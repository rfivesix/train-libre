import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  static const Duration _expandDuration = Duration(milliseconds: 280);

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _muscleKeys = {};
  final Set<String> _expandedMuscles = <String>{};

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
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.recoveryTracker));
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

  bool _shouldHideMuscle(String name) {
    return RecoveryDomainService.shouldHideMuscle(name) ||
        StatisticsPresentationFormatter.isOtherCategoryLabel(name);
  }

  double _readinessScore(RecoveryMusclePayload muscle) {
    final v2Score = muscle.readinessScore;
    if (v2Score != null && v2Score.isFinite) {
      return v2Score.clamp(0.0, 100.0).toDouble();
    }
    return RecoveryDomainService.readinessScore(
      hoursSinceLastSignificantLoad: muscle.hoursSinceLastSignificantLoad,
      recoveringUpperHours: muscle.recoveringUpperHours.toDouble(),
      readyUpperHours: muscle.readyUpperHours.toDouble(),
    );
  }

  String _formatEquivalentSets(BuildContext context, double value) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final format = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return format.format(value);
  }

  int _hoursUntil(RecoveryMusclePayload muscle, int targetHour) {
    final remaining = targetHour - muscle.hoursSinceLastSignificantLoad;
    return remaining <= 0 ? 0 : remaining.ceil();
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
        ? DesignConstants.summaryCardSecondaryDarkMode
        : DesignConstants.summaryCardSecondaryLightMode;

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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count',
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _stateLabel(l10n, state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percent%',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Future<void> _scrollToMuscle(String muscleGroup) async {
    final index =
        _recovery.muscles.indexWhere((m) => m.muscleGroup == muscleGroup);
    if (index < 0) return;
    final muscle = _recovery.muscles[index];

    var didExpand = false;
    setState(() {
      if (muscle.state == RecoveryDomainService.stateRecovering &&
          !_isRecoveringExpanded) {
        _isRecoveringExpanded = true;
        didExpand = true;
      } else if (muscle.state == RecoveryDomainService.stateReady &&
          !_isReadyExpanded) {
        _isReadyExpanded = true;
        didExpand = true;
      } else if (muscle.state == RecoveryDomainService.stateFresh &&
          !_isFreshExpanded) {
        _isFreshExpanded = true;
        didExpand = true;
      }
    });

    // Wait until the expand animation settled, otherwise the target position is
    // measured against a layout that is still growing.
    if (didExpand) {
      await Future<void>.delayed(
          _expandDuration + const Duration(milliseconds: 32));
    } else {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || !_scrollController.hasClients) return;

    final renderObject =
        _muscleKeys[muscleGroup]?.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    // The body extends behind the app bar, so the first visually usable pixel
    // sits below status bar + toolbar.
    final topInset = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        DesignConstants.spacingM;

    final viewport = RenderAbstractViewport.of(renderObject);
    final revealOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;

    final position = _scrollController.position;
    final target = (revealOffset - topInset)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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
          unawaited(_scrollToMuscle(data.payload as String));
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
    final readinessScore = _readinessScore(muscle);
    final key = _muscleKeys.putIfAbsent(rawName, () => GlobalKey());
    final isExpanded = _expandedMuscles.contains(rawName);
    final hasDetails = muscle.lastSignificantLoadAt != null;
    final lastSessionLoad = muscle.lastSessionLoad ?? muscle.lastEquivalentSets;
    final lastSessionHours = muscle.hoursSinceLastSignificantLoad.round();
    final remainingHours = switch (state) {
      RecoveryDomainService.stateRecovering =>
        _hoursUntil(muscle, muscle.recoveringUpperHours),
      RecoveryDomainService.stateReady =>
        _hoursUntil(muscle, muscle.readyUpperHours),
      _ => null,
    };

    return InkWell(
      key: key,
      onTap: hasDetails
          ? () => setState(() {
                if (isExpanded) {
                  _expandedMuscles.remove(rawName);
                } else {
                  _expandedMuscles.add(rawName);
                }
              })
          : null,
      borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingS),
        child: Column(
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
                Text(
                  readinessScore.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: stateColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (hasDetails) ...[
                  const SizedBox(width: DesignConstants.spacingS),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      LucideIcons.chevron_down,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildReadinessScale(
                    context,
                    readinessScore: readinessScore,
                    markerColor: stateColor,
                  ),
                ),
                if (remainingHours != null) ...[
                  const SizedBox(width: DesignConstants.spacingM),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.recoveryCompactHours(remainingHours),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ],
            ),
            AnimatedSize(
              duration: _expandDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: DesignConstants.spacingM,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(DesignConstants.spacingM),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusM,
                          ),
                          border: Border.all(
                            color: stateColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildRecoveryDetailRow(
                              context,
                              title: l10n.recoveryDetailLastSession,
                              value: l10n.recoverySessionLoadAndAge(
                                _formatEquivalentSets(context, lastSessionLoad),
                                lastSessionHours,
                              ),
                            ),
                            if (state != RecoveryDomainService.stateFresh) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: DesignConstants.spacingS,
                                ),
                                child: Divider(height: 1),
                              ),
                              _buildRecoveryDetailRow(
                                context,
                                title: l10n.recoveryDetailForecast,
                                value: state ==
                                        RecoveryDomainService.stateRecovering
                                    ? '${l10n.recoveryReadyInHours(_hoursUntil(muscle, muscle.recoveringUpperHours))}\n${l10n.recoveryFreshInHours(_hoursUntil(muscle, muscle.readyUpperHours))}'
                                    : l10n.recoveryFreshInHours(
                                        _hoursUntil(
                                          muscle,
                                          muscle.readyUpperHours,
                                        ),
                                      ),
                              ),
                            ],
                            if (muscle.eligibleSetCount > 0) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: DesignConstants.spacingS,
                                ),
                                child: Divider(height: 1),
                              ),
                              _buildRecoveryDetailRow(
                                context,
                                title: l10n.recoveryDetailRirData,
                                value: l10n.recoveryRirCoverage(
                                  muscle.setsWithRir,
                                  muscle.eligibleSetCount,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessScale(
    BuildContext context, {
    required double readinessScore,
    required Color markerColor,
  }) {
    final theme = Theme.of(context);
    final markerPosition = readinessScore.clamp(0.0, 100.0) / 100;

    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerLeft = (constraints.maxWidth * markerPosition - 7)
              .clamp(0.0, constraints.maxWidth - 14)
              .toDouble();
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 3,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.38),
                        Colors.orange.withValues(alpha: 0.38),
                        Colors.blue.withValues(alpha: 0.34),
                        Colors.blue.withValues(alpha: 0.34),
                        Colors.green.withValues(alpha: 0.36),
                        Colors.green.withValues(alpha: 0.36),
                      ],
                      stops: const [0, 0.6, 0.6, 0.85, 0.85, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                top: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withValues(alpha: 0.35),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecoveryDetailRow(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.spacingS,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${muscles.length}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
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
                      ),
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
            _ExpandReveal(
              isExpanded: isExpanded,
              duration: _expandDuration,
              child: Padding(
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
                'https://trainlibre.com/docs/features/muscle-recovery-model/#evidence',
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                                RecoveryDomainService.stateRecovering,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  padding: const EdgeInsets.only(top: DesignConstants.spacingS),
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
                  color: _stateColor(context, RecoveryDomainService.stateReady),
                  isExpanded: _isReadyExpanded,
                  onToggle: (val) => setState(() => _isReadyExpanded = val),
                ),
                _buildZoneCard(
                  context,
                  l10n,
                  title: l10n.recoveryStateFresh,
                  muscles: freshMuscles,
                  color: _stateColor(context, RecoveryDomainService.stateFresh),
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

/// Expand/collapse reveal that clips its child instead of resizing it.
///
/// The child keeps its natural layout for the whole animation, so text never
/// reflows or collapses onto itself while the section closes.
class _ExpandReveal extends StatefulWidget {
  const _ExpandReveal({
    required this.isExpanded,
    required this.duration,
    required this.child,
  });

  final bool isExpanded;
  final Duration duration;
  final Widget child;

  @override
  State<_ExpandReveal> createState() => _ExpandRevealState();
}

class _ExpandRevealState extends State<_ExpandReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.isExpanded ? 1.0 : 0.0,
  );

  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  // Fades in only after the section already opened a bit, and fades out during
  // the first part of the collapse so the content is gone before it is clipped.
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    reverseCurve: const Interval(0.55, 1.0, curve: Curves.easeIn),
  );

  @override
  void didUpdateWidget(covariant _ExpandReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final heightFactor = _reveal.value.clamp(0.0, 1.0);
        if (heightFactor == 0.0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: heightFactor,
            child: Opacity(
              opacity: _fade.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

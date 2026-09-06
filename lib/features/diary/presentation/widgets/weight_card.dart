import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../data/drift_database.dart' as db;
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_card_container.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/glass_actionable_card.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../profile/data/sources/profile_local_data_source.dart';
import '../../../profile/presentation/measurements_screen.dart';
import 'weight_ruler.dart';

class WeightCard extends StatefulWidget {
  final DateTime date;
  final ProfileLocalDataSource? dataSource;

  const WeightCard({super.key, required this.date, this.dataSource});

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final CurvedAnimation _phase = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeOutCubic,
  );
  late Stream<db.Measurement?> _weight;
  double? _draftKg;
  bool _editing = false;
  bool _saving = false;
  bool _saveFailed = false;

  /// Days without a weigh-in after which the card nudges again. Kept well
  /// below the recommendation engine's `sparse_weight_logs` threshold (fewer
  /// than 3 entries in 21 days), so following the nudge keeps the estimate out
  /// of the sparse bucket with room to spare.
  static const int _staleNudgeAfterDays = 5;

  ProfileLocalDataSource get _source =>
      widget.dataSource ?? ProfileLocalDataSource.instance;

  DateTime get _day => DateUtils.dateOnly(widget.date);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _weight = _source.watchLatestWeightBefore(
      DateTime(_day.year, _day.month, _day.day + 1),
    );
  }

  @override
  void didUpdateWidget(covariant WeightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.date, widget.date) ||
        oldWidget.dataSource != widget.dataSource) {
      _controller.value = 0;
      _editing = false;
      _draftKg = null;
      _saveFailed = false;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _open(db.Measurement? latest, UnitService units) {
    // A draft is rounded in the visible unit before confirmation, so exactly
    // the displayed number is saved. Unit changes keep the physical weight.
    final display = units.convertDisplayValue(
      latest?.value ?? 75,
      UnitDimension.weight,
    );
    setState(() {
      _draftKg = units.convertToMetric(
        (display * 10).round() / 10,
        UnitDimension.weight,
      );
      _editing = true;
      _saveFailed = false;
    });
    _controller.forward();
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _saveFailed = false;
    });
    _controller.reverse();
  }

  Future<void> _save(UnitService units) async {
    if (_saving) return;
    final day = _day;
    final display = units.convertDisplayValue(_draftKg!, UnitDimension.weight);
    final kg = units.convertToMetric(
      (display * 10).round() / 10,
      UnitDimension.weight,
    );
    final now = DateTime.now();
    final date = DateUtils.isSameDay(day, now)
        ? now
        : DateTime(
            day.year, day.month, day.day, now.hour, now.minute, now.second);
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await _source.saveWeightKg(kg, date: date);
      if (!mounted) return;
      if (day == _day) {
        setState(() => _editing = false);
        _controller.reverse();
      }
    } catch (_) {
      if (mounted && day == _day) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitService>();
    final l10n = AppLocalizations.of(context)!;
    if (_day.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<db.Measurement?>(
      stream: _weight,
      builder: (context, snapshot) {
        final isSkeleton = Skeletonizer.maybeOf(context)?.enabled ?? false;
        if (snapshot.hasError && !isSkeleton) {
          return AppCardContainer(
            padding: const EdgeInsets.all(DesignConstants.spacingM),
            child: Column(children: [
              Text(l10n.diaryWeightLoadError),
              TextButton(
                onPressed: () => setState(_subscribe),
                child: Text(l10n.diaryWeightRetry),
              ),
            ]),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !isSkeleton) {
          return const AppCardContainer(
            padding: EdgeInsets.all(DesignConstants.spacingM),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final latest = snapshot.data ??
            (isSkeleton
                ? db.Measurement(
                    localId: -1,
                    id: 'mock-skeleton',
                    createdAt: _day,
                    updatedAt: _day,
                    type: 'weight',
                    value: 75.0,
                    date: _day,
                    unit: 'kg',
                  )
                : null);
        final logged = latest != null && DateUtils.isSameDay(latest.date, _day);
        // The card's own margin sits outside the morph scope so the measured
        // source rect is the visible card, not the card plus its gap.
        return Padding(
          padding:
              const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
          child: MorphSourceScope(
            builder: (context, setHidden) => Builder(
              builder: (cardCtx) => AnimatedBuilder(
                animation: _phase,
                builder: (context, _) {
                  final open = _phase.value > 0 || _editing;
                  return _buildCard(
                    units,
                    l10n,
                    latest,
                    logged,
                    // Only the collapsed, already-logged card navigates; while
                    // the ruler is open the card belongs to the inline editor.
                    onTap: logged && !open && !isSkeleton
                        ? () => Navigator.of(context).push(
                              CardMorphRoute<void>(
                                sourceContext: cardCtx,
                                // The flying copy is the same presentation
                                // call, not a fresh WeightCard: that one would
                                // resubscribe and take off as a spinner.
                                sourceBuilder: (_) => _buildCard(
                                    units, l10n, latest, logged,
                                    onTap: null),
                                onSourceVisibilityChanged: setHidden,
                                builder: (_) => const MeasurementsScreen(
                                  initialMeasurementType: 'weight',
                                ),
                              ),
                            )
                        : null,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(UnitService units, AppLocalizations l10n,
      db.Measurement? latest, bool logged,
      {required VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = _phase.value;
    final open = p > 0 || _editing;
    final rulerP = ((p - .18) / .82).clamp(0.0, 1.0);
    final actionP = ((p - .5) / .5).clamp(0.0, 1.0);
    final triggerP = (1 - p / .4).clamp(0.0, 1.0);
    final locale = Localizations.localeOf(context).toString();
    final value = units.convertDisplayValue(
      open ? (_draftKg ?? latest?.value ?? 75) : (latest?.value ?? 75),
      UnitDimension.weight,
    );
    final rounded = (value * 10).round() / 10;
    final valid = units.isImperial
        ? rounded >= 77 && rounded <= 550
        : rounded >= 35 && rounded <= 250;
    final number = NumberFormat('0.0', locale).format(rounded);
    final unit = units.suffixFor(UnitDimension.weight);
    final daysSinceLatest = latest == null
        ? null
        : DateTime.utc(_day.year, _day.month, _day.day)
            .difference(DateTime.utc(
                latest.date.year, latest.date.month, latest.date.day))
            .inDays;
    final age = latest == null
        ? ''
        : logged
            ? (DateUtils.isSameDay(_day, DateTime.now())
                ? l10n.diaryWeightToday
                : DateFormat.MMMd(locale).format(_day))
            : l10n.diaryWeightDaysAgo(daysSinceLatest!);
    // The onboarding weigh-in alone would silence the pitch forever, so keep
    // nudging once the trend data goes stale.
    final isStale = !open &&
        daysSinceLatest != null &&
        daysSinceLatest >= _staleNudgeAfterDays;
    final secondaryTextColor = cs.onSurface.withValues(alpha: .64);
    final titleColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final label = Text(
      l10n.diaryWeightLabel,
      style: theme.textTheme.titleMedium?.copyWith(
        color: titleColor,
        fontWeight: FontWeight.bold,
      ),
    );
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: cs.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget valueColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: DesignConstants.spacingXS),
        Wrap(
          spacing: DesignConstants.spacingXS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(number,
                key: const ValueKey('weight-value'), style: valueStyle),
            Text(unit, style: valueStyle),
            if (!open)
              Text(age,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: secondaryTextColor)),
          ],
        ),
      ],
    );
    final actionStyle = theme.textTheme.labelLarge!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: .1,
    );
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingM),
      textStyle: actionStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
      ),
    );
    Widget trigger(bool wide) => IgnorePointer(
          ignoring: open || _saving,
          child: Opacity(
            opacity: triggerP,
            child: Transform.scale(
              scale: .94 + .06 * triggerP,
              child: FilledButton(
                style: buttonStyle,
                onPressed: () => _open(latest, units),
                child:
                    Text(wide ? l10n.diaryWeightLogLong : l10n.diaryWeightLog),
              ),
            ),
          ),
        );
    final actions = IgnorePointer(
      ignoring: !_editing || actionP < .5 || _saving,
      child: Opacity(
        opacity: actionP,
        child: Transform.translate(
          offset: Offset(0, DesignConstants.spacingS * (1 - actionP)),
          child: Wrap(
            spacing: DesignConstants.spacingS,
            runSpacing: DesignConstants.spacingXS,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                style: buttonStyle.copyWith(
                  foregroundColor: WidgetStatePropertyAll(secondaryTextColor),
                ),
                onPressed: _saving ? null : _cancel,
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: buttonStyle,
                onPressed: valid && !_saving ? () => _save(units) : null,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
    return GlassActionableCard(
      enableSwipe: false,
      enableContextMenu: false,
      onTap: onTap,
      child: AppCardContainer(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        margin: EdgeInsets.zero,
        child: LayoutBuilder(builder: (context, constraints) {
          // Keep full German labels and three-digit pounds at narrow widths
          // and large text sizes. Only the action row moves below the value.
          final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
          final actionText = TextPainter(
            text: TextSpan(
              text: '${l10n.cancel}${l10n.save}',
              style: actionStyle,
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final actionTextWidth = actionText.width;
          actionText.dispose();
          final stackActions = constraints.maxWidth <
              actionTextWidth + 56 + 120 * textScale + DesignConstants.spacingM;
          final header = latest == null && !open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    const SizedBox(height: DesignConstants.spacingXS),
                    Text(l10n.diaryWeightPitch,
                        style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35, color: secondaryTextColor)),
                    const SizedBox(height: DesignConstants.spacingM),
                    trigger(true),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: valueColumn),
                      const SizedBox(width: DesignConstants.spacingM),
                      if (!open && logged)
                        Icon(LucideIcons.chevron_right, color: cs.onSurface)
                      else if (!open)
                        trigger(false)
                      else if (!stackActions)
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [actions, if (triggerP > 0) trigger(false)],
                        )
                      else if (triggerP > 0)
                        trigger(false),
                    ]),
                    if (isStale) ...[
                      const SizedBox(height: DesignConstants.spacingS),
                      Text(
                        l10n.diaryWeightStaleNudge,
                        key: const ValueKey('weight-stale-nudge'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(height: 1.35, color: secondaryTextColor),
                      ),
                    ],
                    if (open && stackActions) ...[
                      const SizedBox(height: DesignConstants.spacingS),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  ],
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: header,
              ),
              if (open)
                ClipRect(
                  child: Align(
                    heightFactor: rulerP,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: rulerP,
                      child: IgnorePointer(
                        ignoring: !_editing || _saving,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: DesignConstants.spacingM),
                            WeightRuler(
                              key: const ValueKey('weight-ruler'),
                              value: value,
                              imperial: units.isImperial,
                              enabled: !_saving,
                              label: l10n.diaryWeightLabel,
                              unit: unit,
                              onChanged: (display) => setState(() {
                                _draftKg = units.convertToMetric(
                                    display, UnitDimension.weight);
                              }),
                            ),
                            if (!valid)
                              Text(l10n.diaryWeightRange,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: secondaryTextColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_saveFailed)
                Text(l10n.diaryWeightSaveError,
                    style: theme.textTheme.bodySmall,
                    semanticsLabel: l10n.diaryWeightSaveError),
            ],
          );
        }),
      ),
    );
  }
}

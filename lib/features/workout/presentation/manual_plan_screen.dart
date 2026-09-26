import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/drift_database.dart' as db;
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/morph_source.dart';
import '../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/empty_states/cold_start_empty_state.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../data/manual_training_plan_repository.dart';
import '../domain/models/manual_training_plan.dart';
import '../domain/models/workout_log.dart';
import '../domain/services/workout_plan_notification_orchestrator.dart';
import 'live_workout_screen.dart';
import 'live_workout_view_model.dart';
import 'manual_plan_editor_screen.dart';
import 'manual_plan_text.dart';
import 'workout_log_detail_screen.dart';
import 'widgets/manual_plan_ui.dart';

Future<void> startManualPlanDay(
  BuildContext context,
  ManualTrainingPlan plan,
  PlannedCalendarDay day, {
  Rect? sourceRect,
  WidgetBuilder? sourceBuilder,
  MorphSourceVisibilityCallback? onSourceVisibilityChanged,
}) async {
  final repository = ManualTrainingPlanRepository();
  final live = context.read<LiveWorkoutViewModel>();
  if (live.isActive) {
    final existing = live.workoutLog;
    if (existing != null && context.mounted) {
      await Navigator.of(context).push(
        CardMorphRoute(
          sourceRect: sourceRect,
          sourceBuilder: sourceBuilder,
          onSourceVisibilityChanged: onSourceVisibilityChanged,
          builder: (_) => LiveWorkoutScreen(workoutLog: existing),
        ),
      );
      if (existing.id != null) await repository.reconcileWorkout(existing.id!);
    }
    await WorkoutPlanNotificationOrchestrator().synchronize();
    return;
  }
  final started = await repository.start(plan, day);
  final log = WorkoutLog(
    id: started.log.localId,
    routineName: started.routine.name,
    routineId: started.log.routineId,
    startTime: started.log.startTime,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    CardMorphRoute(
      sourceRect: sourceRect,
      sourceBuilder: sourceBuilder,
      onSourceVisibilityChanged: onSourceVisibilityChanged,
      builder: (_) =>
          LiveWorkoutScreen(workoutLog: log, routine: started.routine),
    ),
  );
  await repository.reconcileWorkout(started.log.localId);
  await WorkoutPlanNotificationOrchestrator().synchronize();
}

class ManualPlanScreen extends StatefulWidget {
  final ManualTrainingPlanRepository? repository;
  const ManualPlanScreen({super.key, this.repository});

  @override
  State<ManualPlanScreen> createState() => _ManualPlanScreenState();
}

class _ManualPlanScreenState extends State<ManualPlanScreen> {
  late final ManualTrainingPlanRepository _repository;
  String? _selectedId;
  DateTime? _weekAnchor;
  DateTime? _selectedDate;
  int _weekDirection = 0;
  int _refresh = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ManualTrainingPlanRepository();
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
  DateTime _startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday + 1);
  void _reload() => setState(() => _refresh++);

  Future<void> _syncReminders() =>
      WorkoutPlanNotificationOrchestrator().synchronize();

  Future<void> _createOrEdit(ManualTrainingPlan? plan) async {
    final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ManualPlanEditorScreen(plan: plan)));
    if (saved == true) {
      await _syncReminders();
      _selectedId = null;
      _weekAnchor = null;
      _selectedDate = null;
      _weekDirection = 0;
      _reload();
    }
  }

  Future<void> _editPlanFromCard(
      ManualTrainingPlan plan, BuildContext sourceContext) async {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final saved = await Navigator.of(context).push<bool>(
      reduceMotion
          ? MaterialPageRoute(
              builder: (_) => ManualPlanEditorScreen(plan: plan),
            )
          : CardMorphRoute<bool>(
              sourceRect: CardMorphRoute.measureRect(sourceContext),
              builder: (_) => ManualPlanEditorScreen(plan: plan),
            ),
    );
    if (saved == true) {
      await _syncReminders();
      _selectedId = null;
      _weekAnchor = null;
      _selectedDate = null;
      _weekDirection = 0;
      _reload();
    }
  }

  Future<void> _activate(ManualTrainingPlan plan) async {
    final text = ManualPlanText(context);
    final resume = await showGlassBottomMenu<bool>(
      context: context,
      title: text.get('activatePlanTitle'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text.get('activatePlanBody')),
          const SizedBox(height: DesignConstants.spacingM),
          AppLinkRow(
              title: text.get('resume'),
              subtitle: text.get('resumeDescription'),
              onTap: () {
                close();
                Navigator.pop(context, true);
              }),
          AppLinkRow(
              title: text.get('restart'),
              subtitle: text.get('restartDescription'),
              onTap: () {
                close();
                Navigator.pop(context, false);
              }),
        ]),
      ),
    );
    if (resume == null) return;
    await _repository.activate(plan.id, resume: resume);
    await _syncReminders();
    _weekAnchor = null;
    _selectedDate = null;
    _reload();
  }

  Future<void> _deactivate(ManualTrainingPlan plan) async {
    final text = ManualPlanText(context);
    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: text.get('deactivatePlanTitle'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text.get('deactivatePlanBody')),
          const SizedBox(height: DesignConstants.spacingM),
          AppButton.danger(
              label: text.get('deactivate'),
              onPressed: () {
                close();
                Navigator.pop(context, true);
              }),
          const SizedBox(height: DesignConstants.spacingS),
          AppButton.secondary(
              label: text.get('cancel'),
              onPressed: () {
                close();
                Navigator.pop(context, false);
              }),
        ]),
      ),
    );
    if (confirmed != true) return;
    await _repository.deactivate(plan.id);
    await _syncReminders();
    _reload();
  }

  Future<void> _handleManageAction(
      ManualTrainingPlan plan, String action) async {
    switch (action) {
      case 'edit':
        await _createOrEdit(plan);
      case 'history':
        await _versions(plan);
      case 'deactivate':
        await _deactivate(plan);
    }
  }

  Future<void> _viewWorkout(int workoutLogId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutLogDetailScreen(logId: workoutLogId),
      ),
    );
  }

  Future<void> _skip(ManualTrainingPlan plan, PlannedCalendarDay day) async {
    final text = ManualPlanText(context);
    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: text.get('confirmSkip'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text.get('skipExplanation')),
          const SizedBox(height: DesignConstants.spacingM),
          AppButton.danger(
              label: text.get('skip'),
              onPressed: () {
                close();
                Navigator.pop(context, true);
              }),
          const SizedBox(height: DesignConstants.spacingS),
          AppButton.secondary(
              label: text.get('cancel'),
              onPressed: () {
                close();
                Navigator.pop(context, false);
              }),
        ]),
      ),
    );
    if (confirmed != true) return;
    await _repository.skip(plan, day);
    await _syncReminders();
    _reload();
  }

  Future<void> _start(
    ManualTrainingPlan plan,
    PlannedCalendarDay day, {
    Rect? sourceRect,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    final text = ManualPlanText(context);
    if (day.date.isBefore(_day(DateTime.now()))) {
      final confirmed = await showGlassBottomMenu<bool>(
        context: context,
        title: text.get('startPastConfirm'),
        contentBuilder: (context, close) => Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text.get('startPastBody')),
            const SizedBox(height: DesignConstants.spacingM),
            AppButton.primary(
                label: text.get('start'),
                onPressed: () {
                  close();
                  Navigator.pop(context, true);
                }),
            const SizedBox(height: DesignConstants.spacingS),
            AppButton.secondary(
                label: text.get('cancel'),
                onPressed: () {
                  close();
                  Navigator.pop(context, false);
                }),
          ]),
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (!mounted) return;
    await startManualPlanDay(
      context,
      plan,
      day,
      sourceRect: sourceRect,
      sourceBuilder: sourceBuilder,
      onSourceVisibilityChanged: onSourceVisibilityChanged,
    );
    _reload();
  }

  Future<void> _versions(ManualTrainingPlan plan) async {
    final versions = await _repository.revisions(plan.id);
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    final text = ManualPlanText(context);
    await showGlassBottomMenu<void>(
      context: context,
      title: text.get('history'),
      expandToFullHeight: versions.length > 4,
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
            ),
            child: Text(
              text.get('historyExplanation'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          for (final revision in versions)
            _PlanRevisionTile(
              revision: revision,
              locale: locale,
              text: text,
            ),
        ]),
      ),
    );
  }

  Future<void> _pickWeek(ManualTrainingPlan plan, DateTime anchor) async {
    final today = _day(DateTime.now());
    final earliest = _day(plan.startedOn ?? today);
    final selected = await showAdaptiveTimeframePicker(
      context: context,
      activeBlock: TimeframeBlock.week,
      initialAnchor: anchor,
      earliestAvailableDay: earliest,
      latestAvailableDay: DateTime(today.year + 1, today.month, today.day),
      supportRolling: false,
    );
    if (selected == null) return;
    final nextAnchor = _startOfWeek(selected.anchorDate);
    final currentAnchor = _weekAnchor ?? _startOfWeek(today);
    setState(() {
      _weekDirection = nextAnchor.compareTo(currentAnchor);
      _weekAnchor = nextAnchor;
      _selectedDate = null;
    });
  }

  Future<void> _selectPlan(
      List<db.TrainingPlan> plans, String selectedId) async {
    final text = ManualPlanText(context);
    final selected = await showGlassBottomMenu<String>(
      context: context,
      title: text.get('savedPlans'),
      expandToFullHeight: plans.length > 7,
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final plan in plans)
              AppLinkRow(
                title: plan.name,
                subtitle:
                    plan.isActive ? text.get('active') : text.get('inactive'),
                trailingIcon: plan.id == selectedId
                    ? LucideIcons.check
                    : LucideIcons.chevron_right,
                onTap: () {
                  close();
                  Navigator.pop(context, plan.id);
                },
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == selectedId || !mounted) return;
    setState(() {
      _selectedId = selected;
      _weekAnchor = null;
      _selectedDate = null;
      _weekDirection = 0;
    });
  }

  Future<({List<PlannedCalendarDay> visible, PlannedCalendarDay? next})>
      _calendarData(
          ManualTrainingPlan plan, DateTime start, DateTime end) async {
    final visible = await _repository.calendar(plan.id, start, end);
    if (!plan.active) return (visible: visible, next: null);
    final today = _day(DateTime.now());
    final upcoming = await _repository.calendar(
        plan.id, today, DateTime(today.year, today.month, today.day + 28));
    return (
      visible: visible,
      next: upcoming
          .where((day) =>
              !day.day.isRest && day.status == PlannedDayStatus.planned)
          .firstOrNull,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return FutureBuilder<List<db.TrainingPlan>>(
      key: ValueKey(_refresh),
      future: _repository.allPlans(),
      builder: (context, snapshot) {
        final rows = snapshot.data;
        final hasPlans = rows != null && rows.isNotEmpty;
        final isEmpty = rows != null && rows.isEmpty;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlobalAppBar(
            title: text.get('plan'),
            actions: hasPlans
                ? [
                    IconButton(
                      tooltip: text.get('create'),
                      onPressed: () => _createOrEdit(null),
                      icon: const Icon(LucideIcons.plus),
                    ),
                  ]
                : null,
          ),
          body: !snapshot.hasData
              ? Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : isEmpty
                  ? _buildEmptyState(context, text, topPadding)
                  : _buildPlanContent(context, rows!, text, topPadding),
          floatingActionButton: isEmpty
              ? GlassFab(
                  label: text.get('create'),
                  icon: LucideIcons.plus,
                  onPressed: () => _createOrEdit(null),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ManualPlanText text,
    double topPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: ColdStartEmptyState(
        icon: LucideIcons.calendar_plus,
        title: text.get('noPlan'),
        subtitle: text.get('noPlanDescription'),
        callToAction: text.get('create'),
        showArrow: true,
        customEndXOffset: 110.0,
        customTargetYOffset: 100.0 + MediaQuery.paddingOf(context).bottom,
      ),
    );
  }

  Widget _buildPlanContent(
    BuildContext context,
    List<db.TrainingPlan> rows,
    ManualPlanText text,
    double topPadding,
  ) {
    final selectedId = _selectedId ??
        rows.where((row) => row.isActive).firstOrNull?.id ??
        rows.first.id;
    return FutureBuilder<ManualTrainingPlan?>(
      future: _repository.loadPlan(selectedId),
      builder: (context, planSnapshot) {
        final plan = planSnapshot.data;
        if (plan == null) {
          return Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final today = _day(DateTime.now());
        var start = _weekAnchor ?? _startOfWeek(today);
        final earliestWeek = _startOfWeek(plan.startedOn ?? today);
        if (start.isBefore(earliestWeek)) start = earliestWeek;
        final end = DateTime(start.year, start.month, start.day + 6);
        final overviewActiveSlot = !plan.active
            ? null
            : plan.kind == TrainingPlanKind.week
                ? today.weekday - 1
                : null;
        return ListView(
          padding: EdgeInsets.only(
            top: topPadding + DesignConstants.screenPaddingVertical,
            bottom: 36,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.screenPaddingHorizontal,
              ),
              child: _buildPlanHeader(
                context,
                plan,
                canSwitch: rows.length > 1,
                onSwitch: () => _selectPlan(rows, selectedId),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.screenPaddingHorizontal,
              ),
              child: FutureBuilder<
                  ({
                    List<PlannedCalendarDay> visible,
                    PlannedCalendarDay? next
                  })>(
                future: _calendarData(plan, start, end),
                builder: (context, daySnapshot) {
                  if (!daySnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(DesignConstants.spacingXL),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final next = daySnapshot.data!.next;
                  return Column(
                    children: [
                      PlanOverviewCard(
                        plan: plan,
                        activeSlotIndex:
                            overviewActiveSlot ?? next?.slotIndex,
                        onEdit: (sourceContext) =>
                            _editPlanFromCard(plan, sourceContext),
                      ),
                      const SizedBox(height: DesignConstants.spacingL),
                      _buildWeek(context, plan, start,
                          daySnapshot.data!.visible, next),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanHeader(
    BuildContext context,
    ManualTrainingPlan plan, {
    required bool canSwitch,
    required VoidCallback onSwitch,
  }) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: canSwitch ? onSwitch : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                            ),
                          ),
                        ),
                        if (canSwitch) ...[
                          const SizedBox(width: 7),
                          Icon(
                            LucideIcons.chevron_down,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              PlatformAdaptivePopupMenu<String>(
                icon: Icon(
                  LucideIcons.ellipsis,
                  size: 21,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (action) => _handleManageAction(plan, action),
                items: [
                  PlatformAdaptivePopupMenuItem(
                    value: 'edit',
                    label: text.get('edit'),
                    icon: LucideIcons.pencil,
                  ),
                  PlatformAdaptivePopupMenuItem(
                    value: 'history',
                    label: text.get('history'),
                    icon: LucideIcons.rotate_ccw_clock,
                  ),
                  if (plan.active)
                    PlatformAdaptivePopupMenuItem(
                      value: 'deactivate',
                      label: text.get('deactivate'),
                      icon: LucideIcons.pause,
                    ),
                ],
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                if (!plan.active)
                  TextSpan(
                    text: '${text.get('inactive')}'
                        '${DesignConstants.metadataSeparator}',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                TextSpan(
                  text:
                      '${text.get(plan.kind == TrainingPlanKind.week ? 'week' : 'sequence')}'
                      '${DesignConstants.metadataSeparator}'
                      '${plan.days.length} ${text.get('days')}',
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
          if (!plan.active) ...[
            const SizedBox(height: DesignConstants.spacingM),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: text.get('activate'),
                icon: LucideIcons.play,
                onPressed: () => _activate(plan),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeek(BuildContext context, ManualTrainingPlan plan,
      DateTime start, List<PlannedCalendarDay> days, PlannedCalendarDay? next) {
    final byDate = {for (final day in days) _day(day.date): day};
    final dates = List.generate(
        7, (index) => DateTime(start.year, start.month, start.day + index));
    final selectable = dates.where((date) => byDate[date] != null).toList();
    var selected = _selectedDate;
    if (selected == null ||
        !dates.any((date) => DateUtils.isSameDay(date, selected))) {
      final today = _day(DateTime.now());
      selected = selectable
              .where((date) => DateUtils.isSameDay(date, today))
              .firstOrNull ??
          selectable
              .where((date) =>
                  next != null && DateUtils.isSameDay(date, next.date))
              .firstOrNull ??
          selectable.firstOrNull;
    }
    final selectedDay = selected == null ? null : byDate[_day(selected)];
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final canStart = plan.active &&
        selectedDay != null &&
        !selectedDay.day.isRest &&
        selectedDay.status == PlannedDayStatus.planned &&
        !selectedDay.date.isAfter(_day(DateTime.now()));
    final workoutLogId = selectedDay?.workoutLogId;
    final canViewWorkout = workoutLogId != null &&
        (selectedDay?.status == PlannedDayStatus.completed ||
            selectedDay?.status == PlannedDayStatus.partial);

    Widget buildDetailCard({VoidCallback? onStart, VoidCallback? onSkip}) =>
        PlanDayDetailCard(
          plan: plan,
          day: selectedDay!,
          onStart: onStart,
          onSkip: onSkip,
          onViewWorkout:
              canViewWorkout ? () => _viewWorkout(workoutLogId) : null,
        );

    return Column(children: [
      AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          if (reduceMotion || _weekDirection == 0) {
            return FadeTransition(opacity: animation, child: child);
          }
          final offset = _weekDirection > 0 ? 0.045 : -0.045;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(offset, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Row(
          key: ValueKey(start),
          children: [
            PlanCalendarPickerButton(
              onPressed: () => _pickWeek(plan, start),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PlanWeekStrip(
                dates: dates,
                days: byDate,
                selectedDate: selected,
                nextDate: next?.date,
                onSelected: (date) => setState(() => _selectedDate = date),
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        child: selectedDay == null
            ? const SizedBox.shrink()
            : MorphSourceScope(
                key: ValueKey('${selectedDay.date}_${selectedDay.status}'),
                builder: (context, setHidden) => Builder(
                  builder: (cardContext) => buildDetailCard(
                    onStart: canStart
                        ? () => _start(
                              plan,
                              selectedDay,
                              sourceRect:
                                  CardMorphRoute.measureRect(cardContext),
                              sourceBuilder: (_) => buildDetailCard(
                                onStart: () {},
                                onSkip: () {},
                              ),
                              onSourceVisibilityChanged: setHidden,
                            )
                        : null,
                    onSkip: canStart ? () => _skip(plan, selectedDay) : null,
                  ),
                ),
              ),
      ),
    ]);
  }
}

class _PlanRevisionTile extends StatelessWidget {
  const _PlanRevisionTile({
    required this.revision,
    required this.locale,
    required this.text,
  });

  final db.TrainingPlanRevision revision;
  final String locale;
  final ManualPlanText text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = TrainingPlanDay.decodeDays(revision.daysJson);
    final visibleDays = days.take(7).toList();
    return SummaryCard(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingS),
      useSecondarySurface: true,
      disableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${text.get('version')} ${revision.number}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat.yMMMd(locale).format(revision.effectiveOn),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in visibleDays)
                _RevisionDayChip(
                  label: day.routineName ?? text.get('rest'),
                  rest: day.isRest,
                ),
              if (days.length > visibleDays.length)
                _RevisionDayChip(
                  label: '+${days.length - visibleDays.length}',
                  rest: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevisionDayChip extends StatelessWidget {
  const _RevisionDayChip({required this.label, required this.rest});

  final String label;
  final bool rest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (rest ? theme.colorScheme.onSurface : theme.colorScheme.primary)
            .withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: rest
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

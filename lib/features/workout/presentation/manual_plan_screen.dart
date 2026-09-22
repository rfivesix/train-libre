import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/time_range_filter.dart';
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

Future<void> startManualPlanDay(BuildContext context, ManualTrainingPlan plan,
    PlannedCalendarDay day) async {
  final repository = ManualTrainingPlanRepository();
  final live = context.read<LiveWorkoutViewModel>();
  if (live.isActive) {
    final existing = live.workoutLog;
    if (existing != null && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LiveWorkoutScreen(workoutLog: existing)));
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
  await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          LiveWorkoutScreen(workoutLog: log, routine: started.routine)));
  await repository.reconcileWorkout(started.log.localId);
  await WorkoutPlanNotificationOrchestrator().synchronize();
}

class ManualPlanScreen extends StatefulWidget {
  const ManualPlanScreen({super.key});

  @override
  State<ManualPlanScreen> createState() => _ManualPlanScreenState();
}

class _ManualPlanScreenState extends State<ManualPlanScreen> {
  final _repository = ManualTrainingPlanRepository();
  String? _selectedId;
  DateTime? _weekAnchor;
  DateTime? _selectedDate;
  int _refresh = 0;

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

  Future<void> _manage(ManualTrainingPlan plan) async {
    final text = ManualPlanText(context);
    final action = await showGlassBottomMenu<String>(
      context: context,
      title: text.get('managePlan'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppLinkRow(
              title: text.get('edit'),
              trailingIcon: LucideIcons.pencil,
              onTap: () {
                close();
                Navigator.pop(context, 'edit');
              }),
          AppLinkRow(
              title: text.get('history'),
              trailingIcon: LucideIcons.rotate_ccw_clock,
              onTap: () {
                close();
                Navigator.pop(context, 'history');
              }),
          if (plan.active)
            AppLinkRow(
                title: text.get('deactivate'),
                trailingIcon: LucideIcons.pause,
                onTap: () {
                  close();
                  Navigator.pop(context, 'deactivate');
                }),
        ]),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _createOrEdit(plan);
      case 'history':
        await _versions(plan);
      case 'deactivate':
        await _deactivate(plan);
    }
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

  Future<void> _start(ManualTrainingPlan plan, PlannedCalendarDay day) async {
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
    await startManualPlanDay(context, plan, day);
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
          Text(text.get('historyExplanation')),
          const SizedBox(height: DesignConstants.spacingM),
          for (var index = 0; index < versions.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingM,
                  vertical: DesignConstants.spacingM),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(LucideIcons.rotate_ccw_clock,
                    size: 19, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${text.get('version')} ${versions[index].number}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormat.yMMMd(locale).format(versions[index].effectiveOn)} · ${TrainingPlanDay.decodeDays(versions[index].daysJson).map((day) => day.routineName ?? text.get('rest')).join(' · ')}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.68),
                            ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            if (index != versions.length - 1) const Divider(height: 1),
          ],
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
    setState(() {
      _weekAnchor = _startOfWeek(selected.anchorDate);
      _selectedDate = null;
    });
  }

  void _shiftWeek(ManualTrainingPlan plan, int direction) {
    final today = _day(DateTime.now());
    final earliest = _startOfWeek(plan.startedOn ?? today);
    final latest =
        _startOfWeek(DateTime(today.year + 1, today.month, today.day));
    final current = _weekAnchor ?? _startOfWeek(today);
    var next =
        DateTime(current.year, current.month, current.day + 7 * direction);
    if (next.isBefore(earliest)) next = earliest;
    if (next.isAfter(latest)) next = latest;
    setState(() {
      _weekAnchor = next;
      _selectedDate = null;
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
    return Scaffold(
      appBar: GlobalAppBar(title: text.get('plans'), actions: [
        IconButton(
            tooltip: text.get('create'),
            onPressed: () => _createOrEdit(null),
            icon: const Icon(LucideIcons.plus)),
      ]),
      body: FutureBuilder(
        key: ValueKey(_refresh),
        future: _repository.allPlans(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) return _buildEmptyState(context);
          final selectedId = _selectedId ??
              rows.where((row) => row.isActive).firstOrNull?.id ??
              rows.first.id;
          return FutureBuilder<ManualTrainingPlan?>(
            future: _repository.loadPlan(selectedId),
            builder: (context, planSnapshot) {
              final plan = planSnapshot.data;
              if (plan == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final today = _day(DateTime.now());
              final earliestWeek = _startOfWeek(plan.startedOn ?? today);
              final latestWeek = _startOfWeek(
                  DateTime(today.year + 1, today.month, today.day));
              var start = _weekAnchor ?? _startOfWeek(today);
              if (start.isBefore(earliestWeek)) start = earliestWeek;
              final end = DateTime(start.year, start.month, start.day + 6);
              return ListView(
                padding: DesignConstants.screenPadding,
                children: [
                  if (rows.length > 1) ...[
                    AppSectionHeader(
                        title: text.get('savedPlans'), isFirst: true),
                    SummaryCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        for (var index = 0; index < rows.length; index++) ...[
                          AppLinkRow(
                            title: rows[index].name,
                            subtitle: rows[index].isActive
                                ? text.get('active')
                                : text.get('inactive'),
                            trailingIcon: rows[index].id == selectedId
                                ? LucideIcons.check
                                : LucideIcons.chevron_right,
                            onTap: () => setState(() {
                              _selectedId = rows[index].id;
                              _weekAnchor = null;
                              _selectedDate = null;
                            }),
                          ),
                          if (index != rows.length - 1)
                            const Divider(height: 1),
                        ],
                      ]),
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                  ],
                  _buildPlanHeader(context, plan),
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(title: text.get('schedule')),
                  TimeRangeFilter(
                    ranges: [text.get('weekView')],
                    selectedIndex: 0,
                    onSelected: (_) {},
                    onPrevious: start.isAfter(earliestWeek)
                        ? () => _shiftWeek(plan, -1)
                        : null,
                    onNext: start.isBefore(latestWeek)
                        ? () => _shiftWeek(plan, 1)
                        : null,
                    nextEnabled: start.isBefore(latestWeek),
                    displayDate: _formatWeek(context, start, end),
                    onTapDateDisplay: () => _pickWeek(plan, start),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  FutureBuilder<
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
                      return _buildWeek(context, plan, start,
                          daySnapshot.data!.visible, daySnapshot.data!.next);
                    },
                  ),
                  const SizedBox(height: 36),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final text = ManualPlanText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.calendar_plus,
              size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: DesignConstants.spacingM),
          Text(text.get('noPlan'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DesignConstants.spacingS),
          Text(text.get('noPlanDescription'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: DesignConstants.spacingL),
          AppButton.primary(
              label: text.get('create'),
              icon: LucideIcons.plus,
              onPressed: () => _createOrEdit(null)),
        ]),
      ),
    );
  }

  Widget _buildPlanHeader(BuildContext context, ManualTrainingPlan plan) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    return SummaryCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${text.get(plan.kind == TrainingPlanKind.week ? 'week' : 'sequence')} · ${plan.days.length} ${text.get('days')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (plan.active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              text.get(plan.active ? 'active' : 'inactive'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: plan.active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          text.get(plan.kind == TrainingPlanKind.week
              ? 'weekPlanExplanation'
              : 'sequencePlanExplanation'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.35,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        const Divider(height: 1),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _manage(plan),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Icon(LucideIcons.settings_2,
                  size: 19, color: theme.colorScheme.primary),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: Text(text.get('managePlan'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Icon(LucideIcons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ]),
          ),
        ),
        if (!plan.active) ...[
          const SizedBox(height: DesignConstants.spacingS),
          AppButton.primary(
            label: text.get('activate'),
            icon: LucideIcons.play,
            onPressed: () => _activate(plan),
          ),
        ],
      ]),
    );
  }

  String _formatWeek(BuildContext context, DateTime start, DateTime end) {
    final locale = Localizations.localeOf(context).toString();
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat.MMMd(locale).format(start)}–${DateFormat.d(locale).format(end)}';
    }
    return '${DateFormat.MMMd(locale).format(start)}–${DateFormat.MMMd(locale).format(end)}';
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
    final theme = Theme.of(context);
    return Column(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.025, 0), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: SummaryCard(
          key: ValueKey(start),
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var index = 0; index < dates.length; index++) ...[
              _PlanAgendaRow(
                date: dates[index],
                day: byDate[dates[index]],
                selected: selected != null &&
                    DateUtils.isSameDay(dates[index], selected),
                next: next != null &&
                    DateUtils.isSameDay(dates[index], next.date),
                onTap: byDate[dates[index]] == null
                    ? null
                    : () => setState(() => _selectedDate = dates[index]),
              ),
              if (index != dates.length - 1)
                Divider(
                  height: 1,
                  indent: 72,
                  color: theme.dividerColor.withValues(alpha: 0.45),
                ),
            ],
          ]),
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        child: selectedDay == null
            ? const SizedBox.shrink()
            : _buildDayDetail(context, plan, selectedDay,
                key: ValueKey('${selectedDay.date}_${selectedDay.status}')),
      ),
    ]);
  }

  Widget _buildDayDetail(
      BuildContext context, ManualTrainingPlan plan, PlannedCalendarDay day,
      {required Key key}) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = _day(DateTime.now());
    final canResolve = plan.active &&
        !day.day.isRest &&
        day.status == PlannedDayStatus.planned &&
        !day.date.isAfter(today);
    final helper = day.day.isRest
        ? text.get('restDescription')
        : day.status == PlannedDayStatus.completed
            ? text.get('completedDescription')
            : day.status == PlannedDayStatus.partial
                ? text.get('partialDescription')
                : day.status == PlannedDayStatus.skipped
                    ? text.get('skippedDescription')
                    : day.date.isAfter(today)
                        ? text.get('futureDescription')
                        : DateUtils.isSameDay(day.date, today)
                            ? text.get('todayDescription')
                            : text.get('pastOpenDescription');
    return SummaryCard(
      key: key,
      useSecondarySurface: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat.yMMMMEEEEd(locale).format(day.date),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            )),
        const SizedBox(height: 4),
        Text(day.day.routineName ?? text.get('rest'),
            style: theme.textTheme.titleLarge),
        const SizedBox(height: DesignConstants.spacingS),
        Text(helper,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            )),
        if (canResolve) ...[
          const SizedBox(height: DesignConstants.spacingM),
          Row(children: [
            Expanded(
              child: AppButton.secondary(
                label: text.get('skip'),
                icon: LucideIcons.skip_forward,
                onPressed: () => _skip(plan, day),
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: AppButton.primary(
                label: text.get('startShort'),
                icon: LucideIcons.play,
                onPressed: () => _start(plan, day),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _PlanAgendaRow extends StatelessWidget {
  const _PlanAgendaRow({
    required this.date,
    required this.day,
    required this.selected,
    required this.next,
    required this.onTap,
  });

  final DateTime date;
  final PlannedCalendarDay? day;
  final bool selected;
  final bool next;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
    final today = DateUtils.isSameDay(date, DateTime.now());
    final status = day?.status;
    final (icon, color) = switch (status) {
      PlannedDayStatus.completed => (
          LucideIcons.circle_check,
          theme.colorScheme.primary
        ),
      PlannedDayStatus.partial => (LucideIcons.circle_dot, Colors.orange),
      PlannedDayStatus.skipped => (
          LucideIcons.skip_forward,
          theme.colorScheme.onSurfaceVariant
        ),
      PlannedDayStatus.rest => (
          LucideIcons.moon,
          theme.colorScheme.onSurfaceVariant
        ),
      PlannedDayStatus.ongoing => (
          LucideIcons.timer,
          theme.colorScheme.primary
        ),
      PlannedDayStatus.planned => (
          LucideIcons.circle,
          theme.colorScheme.onSurfaceVariant
        ),
      null => (LucideIcons.minus, theme.disabledColor),
    };
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM, vertical: 11),
          child: Row(children: [
            SizedBox(
              width: 48,
              child: Column(children: [
                Text(DateFormat.E(locale).format(date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    )),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        today ? theme.colorScheme.primary : Colors.transparent,
                  ),
                  child: Text(DateFormat.d(locale).format(date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: today ? theme.colorScheme.onPrimary : null,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ]),
            ),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        day?.day.routineName ??
                            (day == null
                                ? text.get('notStarted')
                                : text.get('rest')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: day == null ? theme.disabledColor : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (next) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(text.get('nextUp'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    day == null
                        ? text.get('beforePlanStart')
                        : text.get(status!.name),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: day == null
                          ? theme.disabledColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 19, color: color),
          ]),
        ),
      ),
    );
  }
}

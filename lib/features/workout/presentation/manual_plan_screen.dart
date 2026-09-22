import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../data/manual_training_plan_repository.dart';
import '../domain/models/manual_training_plan.dart';
import '../domain/models/workout_log.dart';
import 'live_workout_screen.dart';
import 'live_workout_view_model.dart';
import 'manual_plan_editor_screen.dart';
import 'manual_plan_text.dart';

/// Opens a planned session with its frozen routine snapshot. The log/occurrence
/// are inserted together, and resolution is retried after navigation.
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
}

class ManualPlanScreen extends StatefulWidget {
  const ManualPlanScreen({super.key});

  @override
  State<ManualPlanScreen> createState() => _ManualPlanScreenState();
}

class _ManualPlanScreenState extends State<ManualPlanScreen> {
  final _repository = ManualTrainingPlanRepository();
  String? _selectedId;
  int _weekOffset = 0;
  int _refresh = 0;

  void _reload() => setState(() => _refresh++);

  DateTime _startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - date.weekday + 1);

  Future<void> _createOrEdit(ManualTrainingPlan? plan) async {
    final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ManualPlanEditorScreen(plan: plan)));
    if (saved == true) {
      _selectedId = null;
      _reload();
    }
  }

  Future<void> _activate(ManualTrainingPlan plan) async {
    final text = ManualPlanText(context);
    final resume = await showGlassBottomMenu<bool>(
      context: context,
      title: plan.name,
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppLinkRow(
              title: text.get('resume'),
              onTap: () {
                close();
                Navigator.pop(context, true);
              }),
          AppLinkRow(
              title: text.get('restart'),
              onTap: () {
                close();
                Navigator.pop(context, false);
              }),
        ]),
      ),
    );
    if (resume == null) return;
    await _repository.activate(plan.id, resume: resume);
    _reload();
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
          AppButton.danger(
              label: text.get('skip'),
              onPressed: () {
                close();
                Navigator.pop(context, true);
              }),
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
    _reload();
  }

  Future<void> _versions(ManualTrainingPlan plan) async {
    final versions = await _repository.revisions(plan.id);
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    await showGlassBottomMenu<void>(
      context: context,
      title: ManualPlanText(context).get('history'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final version in versions)
            SummaryCard(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${ManualPlanText(context).get('version')} ${version.number}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(DateFormat.yMMMd(locale).format(version.effectiveOn)),
                const SizedBox(height: 4),
                Text(
                    TrainingPlanDay.decodeDays(version.daysJson)
                        .map((day) => day.routineName ?? '–')
                        .join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
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
          if (rows.isEmpty) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(text.get('noPlan'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: DesignConstants.spacingL),
                AppButton.primary(
                    label: text.get('create'),
                    onPressed: () => _createOrEdit(null)),
              ]),
            ));
          }
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
              final today = DateTime.now();
              final start = _startOfWeek(DateTime(
                  today.year, today.month, today.day + _weekOffset * 7));
              final end = DateTime(start.year, start.month, start.day + 6);
              return ListView(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                children: [
                  if (rows.length > 1)
                    SummaryCard(
                        child: Column(children: [
                      for (final row in rows)
                        AppLinkRow(
                          title: row.name,
                          subtitle: row.isActive ? text.get('active') : null,
                          onTap: () => setState(() {
                            _selectedId = row.id;
                            _weekOffset = 0;
                          }),
                        ),
                    ])),
                  SummaryCard(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                          '${text.get(plan.kind == TrainingPlanKind.week ? 'week' : 'sequence')} · ${plan.days.length} ${text.get('days')}'
                          '${plan.active ? ' · ${text.get('active')}' : ''}'),
                      const SizedBox(height: DesignConstants.spacingM),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        AppButton.secondary(
                            label: text.get('edit'),
                            size: AppButtonSize.small,
                            onPressed: () => _createOrEdit(plan)),
                        AppButton.secondary(
                            label: text.get('history'),
                            size: AppButtonSize.small,
                            onPressed: () => _versions(plan)),
                        if (!plan.active)
                          AppButton.primary(
                              label: text.get('activate'),
                              size: AppButtonSize.small,
                              onPressed: () => _activate(plan))
                        else
                          AppButton.secondary(
                              label: text.get('deactivate'),
                              size: AppButtonSize.small,
                              onPressed: () async {
                                await _repository.deactivate(plan.id);
                                _reload();
                              }),
                      ]),
                    ],
                  )),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(children: [
                    IconButton(
                        tooltip: text.get('previous'),
                        onPressed: () => setState(() => _weekOffset--),
                        icon: const Icon(LucideIcons.chevron_left)),
                    Expanded(
                        child: Text(
                      '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                    IconButton(
                        tooltip: text.get('next'),
                        onPressed: () => setState(() => _weekOffset++),
                        icon: const Icon(LucideIcons.chevron_right)),
                  ]),
                  FutureBuilder<List<PlannedCalendarDay>>(
                    future: _repository.calendar(plan.id, start, end),
                    builder: (context, daySnapshot) {
                      if (!daySnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final dates = {
                        for (final day in daySnapshot.data!)
                          DateUtils.dateOnly(day.date): day
                      };
                      PlannedCalendarDay? nextDay;
                      for (final candidate in daySnapshot.data!) {
                        if (!candidate.date
                                .isBefore(DateUtils.dateOnly(DateTime.now())) &&
                            candidate.status == PlannedDayStatus.planned) {
                          nextDay = candidate;
                          break;
                        }
                      }
                      return Column(children: [
                        for (var i = 0; i < 7; i++)
                          _buildDay(
                              context,
                              plan,
                              DateTime(start.year, start.month, start.day + i),
                              dates[DateTime(
                                  start.year, start.month, start.day + i)],
                              nextDay?.date),
                      ]);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDay(BuildContext context, ManualTrainingPlan plan, DateTime date,
      PlannedCalendarDay? day, DateTime? nextDate) {
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isPast = date.isBefore(DateUtils.dateOnly(DateTime.now()));
    final isNext = nextDate != null && DateUtils.isSameDay(date, nextDate);
    return SummaryCard(
      useSecondarySurface: isToday || isNext,
      child: Row(children: [
        SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.E(locale).format(date)),
                Text(DateFormat.d(locale).format(date),
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            )),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day?.day.routineName ?? (day == null ? '–' : text.get('rest')),
                style: Theme.of(context).textTheme.titleMedium),
            if (day != null && !day.day.isRest)
              Text(
                  isNext
                      ? text.get('nextUp')
                      : isPast && day.status == PlannedDayStatus.planned
                          ? text.get('open')
                          : text.get(day.status.name),
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        )),
        if (day != null &&
            !date.isAfter(DateUtils.dateOnly(DateTime.now())) &&
            plan.active &&
            day.status == PlannedDayStatus.planned) ...[
          IconButton(
              tooltip: text.get('skip'),
              onPressed: () => _skip(plan, day),
              icon: const Icon(LucideIcons.skip_forward, size: 18)),
          IconButton(
              tooltip: text.get('start'),
              onPressed: () async {
                if (isPast) {
                  final confirmed = await showGlassBottomMenu<bool>(
                    context: context,
                    title: text.get('startPastConfirm'),
                    contentBuilder: (context, close) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.spacingS),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AppButton.primary(
                            label: text.get('start'),
                            onPressed: () {
                              close();
                              Navigator.pop(context, true);
                            }),
                        AppButton.secondary(
                            label: text.get('cancel'),
                            onPressed: () {
                              close();
                              Navigator.pop(context, false);
                            }),
                      ]),
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                }
                await startManualPlanDay(context, plan, day);
                _reload();
              },
              icon: const Icon(LucideIcons.play, size: 22)),
        ],
      ]),
    );
  }
}

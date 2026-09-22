import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/app_segmented_control.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../data/manual_training_plan_repository.dart';
import '../data/sources/workout_local_data_source.dart';
import '../domain/models/manual_training_plan.dart';
import '../domain/models/routine.dart';
import '../domain/services/workout_plan_notification_orchestrator.dart';
import 'edit_routine_screen.dart';
import 'manual_plan_text.dart';

class ManualPlanEditorScreen extends StatefulWidget {
  const ManualPlanEditorScreen({super.key, this.plan});
  final ManualTrainingPlan? plan;

  @override
  State<ManualPlanEditorScreen> createState() => _ManualPlanEditorScreenState();
}

class _ManualPlanEditorScreenState extends State<ManualPlanEditorScreen> {
  final _repository = ManualTrainingPlanRepository();
  final _name = TextEditingController();
  TrainingPlanKind _kind = TrainingPlanKind.week;
  List<TrainingPlanDay> _days = List.filled(7, const TrainingPlanDay());
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    if (plan != null) {
      _name.text = plan.name;
      _kind = plan.kind;
      _days = List.of(plan.days);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _setLength(int length) {
    if (length < 1 || length > 14) return;
    setState(() {
      if (length > _days.length) {
        _days = [
          ..._days,
          ...List.filled(length - _days.length, const TrainingPlanDay())
        ];
      } else {
        _days = _days.take(length).toList();
      }
    });
  }

  Future<void> _chooseRoutine(int index) async {
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    if (!mounted) return;
    final chosen = await showGlassBottomMenu<Object>(
      context: context,
      title: ManualPlanText(context).get('chooseRoutine'),
      expandToFullHeight: routines.length > 7,
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView(
                shrinkWrap: true,
                children: [
                  AppLinkRow(
                    title: ManualPlanText(context).get('rest'),
                    subtitle:
                        ManualPlanText(context).get('restPickerDescription'),
                    trailingIcon: LucideIcons.moon,
                    onTap: () {
                      close();
                      Navigator.pop(context, 'rest');
                    },
                  ),
                  for (final routine in routines)
                    AppLinkRow(
                      title: routine.name,
                      subtitle:
                          '${routine.exercises.length} ${ManualPlanText(context).get('exercises')}',
                      trailingIcon: LucideIcons.dumbbell,
                      onTap: () {
                        close();
                        Navigator.pop(context, routine);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (chosen == null) return;
    try {
      final day = chosen == 'rest'
          ? const TrainingPlanDay()
          : await _repository.dayFromRoutine(chosen as Routine);
      setState(() => _days[index] = day);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _editRoutine(int index) async {
    final id = (_days[index].routineSnapshot?['id'] as num?)?.toInt();
    if (id == null) return;
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    final matches = routines.where((routine) => routine.id == id);
    if (matches.isEmpty || !mounted) return;
    final before = jsonEncode(_days[index].routineSnapshot);
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditRoutineScreen(
            routine: matches.first, offerPlanUpdateOnSave: false)));
    if (!mounted) return;
    final updated = await _repository.dayFromRoutine(matches.first);
    if (!mounted) return;
    if (jsonEncode(updated.routineSnapshot) == before) return;
    final include = await showGlassBottomMenu<bool>(
      context: context,
      title: ManualPlanText(context).get('routineChanged'),
      contentBuilder: (context, close) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppLinkRow(
              title: ManualPlanText(context).get('routineOnly'),
              onTap: () {
                close();
                Navigator.pop(context, false);
              }),
          AppLinkRow(
              title: ManualPlanText(context).get('updatePlan'),
              onTap: () {
                close();
                Navigator.pop(context, true);
              }),
        ]),
      ),
    );
    if (include != true || !mounted) return;
    setState(() => _days[index] = updated);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = ManualPlanText(context).get('missingName'));
      return;
    }
    if (!_days.any((day) => !day.isRest)) {
      setState(() => _error = ManualPlanText(context).get('needsWorkout'));
      return;
    }
    bool nextCycle = false;
    if (widget.plan != null) {
      final choice = await showGlassBottomMenu<bool>(
        context: context,
        title: ManualPlanText(context).get('applyWhen'),
        contentBuilder: (context, close) => Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppLinkRow(
                title: ManualPlanText(context).get('fromToday'),
                onTap: () {
                  close();
                  Navigator.pop(context, false);
                }),
            AppLinkRow(
                title: ManualPlanText(context).get('nextCycle'),
                onTap: () {
                  close();
                  Navigator.pop(context, true);
                }),
          ]),
        ),
      );
      if (choice == null) return;
      nextCycle = choice;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.plan == null) {
        await _repository.createPlan(
            name: _name.text, kind: _kind, days: _days);
      } else {
        await _repository.revisePlan(
            planId: widget.plan!.id,
            name: _name.text,
            kind: _kind,
            days: _days,
            nextCycle: nextCycle);
      }
      await WorkoutPlanNotificationOrchestrator().synchronize();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
    final weekdayNames = List.generate(
        7,
        (index) =>
            DateFormat.EEEE(locale).format(DateTime(2026, 9, 21 + index)));
    return Scaffold(
      appBar: GlobalAppBar(
          title: text.get(widget.plan == null ? 'create' : 'edit')),
      body: ListView(
        padding: DesignConstants.screenPadding,
        children: [
          AppSectionHeader(title: text.get('basics'), isFirst: true),
          SummaryCard(
              child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: text.get('name'),
              border: InputBorder.none,
            ),
          )),
          if (widget.plan == null) ...[
            const SizedBox(height: DesignConstants.spacingM),
            AppSegmentedControl<TrainingPlanKind>(
              children: {
                TrainingPlanKind.week: text.get('week'),
                TrainingPlanKind.sequence: text.get('sequence')
              },
              groupValue: _kind,
              onValueChanged: (kind) => setState(() {
                _kind = kind;
                _days = List.filled(kind == TrainingPlanKind.week ? 7 : 3,
                    const TrainingPlanDay());
              }),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  text.get(_kind == TrainingPlanKind.week
                      ? 'weekEditorExplanation'
                      : 'sequenceEditorExplanation'),
                  key: ValueKey(_kind),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.68),
                        height: 1.35,
                      ),
                ),
              ),
            ),
          ],
          if (_kind == TrainingPlanKind.sequence) ...[
            const SizedBox(height: DesignConstants.spacingM),
            SummaryCard(
                child: Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.get('length'),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${_days.length} ${text.get('days')}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              IconButton(
                  tooltip: text.get('shorter'),
                  onPressed: _days.length > 1
                      ? () => _setLength(_days.length - 1)
                      : null,
                  icon: const Icon(LucideIcons.minus)),
              IconButton(
                  tooltip: text.get('longer'),
                  onPressed: _days.length < 14
                      ? () => _setLength(_days.length + 1)
                      : null,
                  icon: const Icon(LucideIcons.plus)),
            ])),
          ],
          const SizedBox(height: DesignConstants.spacingL),
          AppSectionHeader(title: text.get('schedule')),
          Text(
            text.get('editorScheduleHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: SummaryCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var index = 0; index < _days.length; index++) ...[
                  _PlanEditorDayRow(
                    label: _kind == TrainingPlanKind.week
                        ? weekdayNames[index]
                        : '${text.get('day')} ${index + 1}',
                    day: _days[index],
                    onChoose: () => _chooseRoutine(index),
                    onEdit:
                        _days[index].isRest ? null : () => _editRoutine(index),
                  ),
                  if (index != _days.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ]),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: DesignConstants.spacingL),
          AppButton.primary(
            label: text.get(widget.plan == null ? 'saveActivate' : 'save'),
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _PlanEditorDayRow extends StatelessWidget {
  const _PlanEditorDayRow({
    required this.label,
    required this.day,
    required this.onChoose,
    this.onEdit,
  });

  final String label;
  final TrainingPlanDay day;
  final VoidCallback onChoose;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onChoose,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 8, 11),
        child: Row(children: [
          SizedBox(
            width: 34,
            child: Icon(
              day.isRest ? LucideIcons.moon : LucideIcons.dumbbell,
              size: 19,
              color: day.isRest
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
                const SizedBox(height: 2),
                Text(day.routineName ?? text.get('rest'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: text.get('editRoutine'),
              onPressed: onEdit,
              icon: const Icon(LucideIcons.pencil, size: 18),
            ),
          const Icon(LucideIcons.chevron_right, size: 18),
        ]),
      ),
    );
  }
}

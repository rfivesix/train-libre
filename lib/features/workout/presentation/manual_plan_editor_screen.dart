import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
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
import 'widgets/manual_plan_ui.dart';

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
  List<Key> _dayKeys = List.generate(7, (_) => UniqueKey());
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
      _dayKeys = List.generate(_days.length, (_) => UniqueKey());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addSequenceDay() {
    if (_kind != TrainingPlanKind.sequence || _days.length >= 14) return;
    setState(() {
      _days = [..._days, const TrainingPlanDay()];
      _dayKeys = [..._dayKeys, UniqueKey()];
    });
  }

  void _removeSequenceDay(int index) {
    if (_kind != TrainingPlanKind.sequence || _days.length <= 1) return;
    setState(() {
      _days = List.of(_days)..removeAt(index);
      _dayKeys = List.of(_dayKeys)..removeAt(index);
    });
  }

  void _reorderSequenceDay(int oldIndex, int newIndex) {
    if (_kind != TrainingPlanKind.sequence) return;
    setState(() {
      final reordered = List<TrainingPlanDay>.of(_days);
      final day = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, day);
      _days = reordered;
      final reorderedKeys = List<Key>.of(_dayKeys);
      final key = reorderedKeys.removeAt(oldIndex);
      reorderedKeys.insert(newIndex, key);
      _dayKeys = reorderedKeys;
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
                  if (!_days[index].isRest)
                    AppLinkRow(
                      title: _days[index].routineName ??
                          ManualPlanText(context).get('editRoutine'),
                      subtitle: ManualPlanText(context).get('editRoutine'),
                      trailingIcon: LucideIcons.pencil,
                      onTap: () {
                        close();
                        Navigator.pop(context, 'edit');
                      },
                    ),
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
    if (chosen == 'edit') {
      await _editRoutine(index);
      return;
    }
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
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final weekdayNames = List.generate(
        7,
        (index) =>
            DateFormat.EEEE(locale).format(DateTime(2026, 9, 21 + index)));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
          title: text.get(widget.plan == null ? 'create' : 'edit')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.screenPaddingHorizontal,
          topPadding + DesignConstants.screenPaddingVertical,
          DesignConstants.screenPaddingHorizontal,
          104,
        ),
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
            _PlanKindSelector(
              value: _kind,
              onChanged: (kind) => setState(() {
                _kind = kind;
                _days = List.filled(kind == TrainingPlanKind.week ? 7 : 3,
                    const TrainingPlanDay());
                _dayKeys = List.generate(_days.length, (_) => UniqueKey());
              }),
            ),
          ],
          const SizedBox(height: DesignConstants.spacingL),
          AppSectionHeader(
            title: text.get('schedule'),
            action: _kind == TrainingPlanKind.sequence
                ? Text(
                    '${_days.length}/14 ${text.get('days')}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              text.get('editorScheduleHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
                  ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          _buildSchedule(context, weekdayNames),
          if (_kind == TrainingPlanKind.sequence && _days.length < 14) ...[
            const SizedBox(height: DesignConstants.spacingS),
            SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                label: text.get('addDay'),
                icon: LucideIcons.plus,
                onPressed: _addSequenceDay,
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AppButton.primary(
          label: text.get(widget.plan == null ? 'saveActivate' : 'save'),
          onPressed: _saving ? null : _save,
          isLoading: _saving,
        ),
      ),
    );
  }

  Widget _buildSchedule(BuildContext context, List<String> weekdayNames) {
    final text = ManualPlanText(context);
    final Widget content;
    if (_kind == TrainingPlanKind.sequence) {
      content = ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _days.length,
        onReorderItem: _reorderSequenceDay,
        itemBuilder: (context, index) => _PlanEditorDayRow(
          key: _dayKeys[index],
          label: '${text.get('day')} ${index + 1}',
          day: _days[index],
          onChoose: () => _chooseRoutine(index),
          onRemove: _days.length > 1 ? () => _removeSequenceDay(index) : null,
          dragHandle: ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(LucideIcons.grip_vertical, size: 19),
            ),
          ),
        ),
      );
    } else {
      content = Column(
        children: [
          for (var index = 0; index < _days.length; index++) ...[
            _PlanEditorDayRow(
              key: ValueKey('week-day-$index'),
              label: weekdayNames[index],
              day: _days[index],
              onChoose: () => _chooseRoutine(index),
            ),
            if (index != _days.length - 1) const Divider(height: 1, indent: 68),
          ],
        ],
      );
    }
    return AnimatedSize(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SummaryCard(padding: EdgeInsets.zero, child: content),
    );
  }
}

class _PlanEditorDayRow extends StatelessWidget {
  const _PlanEditorDayRow({
    required this.label,
    required this.day,
    required this.onChoose,
    this.onRemove,
    this.dragHandle,
    super.key,
  });

  final String label;
  final TrainingPlanDay day;
  final VoidCallback onChoose;
  final VoidCallback? onRemove;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    final routineLabel = day.routineName ?? text.get('rest');
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '$label, $routineLabel',
            excludeSemantics: true,
            child: InkWell(
              onTap: onChoose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 8, 11),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day.isRest
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.06)
                            : theme.colorScheme.primary.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        day.isRest ? LucideIcons.minus : LucideIcons.dumbbell,
                        size: 18,
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
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            routineLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!day.isRest) ...[
                            const SizedBox(height: 2),
                            Text(
                              plannedDayMetadata(context, day),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (dragHandle == null)
                      Icon(
                        LucideIcons.chevron_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: text.get('removeDay'),
            onPressed: onRemove,
            icon: const Icon(LucideIcons.circle_minus, size: 18),
          ),
        if (dragHandle != null) dragHandle!,
        const SizedBox(width: 4),
      ],
    );
  }
}

class _PlanKindSelector extends StatelessWidget {
  const _PlanKindSelector({required this.value, required this.onChanged});

  final TrainingPlanKind value;
  final ValueChanged<TrainingPlanKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PlanKindOption(
              icon: LucideIcons.calendar_days,
              title: text.get('week'),
              description: text.get('weekEditorShort'),
              selected: value == TrainingPlanKind.week,
              onTap: () {
                if (value != TrainingPlanKind.week) {
                  onChanged(TrainingPlanKind.week);
                }
              },
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Expanded(
            child: _PlanKindOption(
              icon: LucideIcons.repeat_2,
              title: text.get('sequence'),
              description: text.get('sequenceEditorShort'),
              selected: value == TrainingPlanKind.sequence,
              onTap: () {
                if (value != TrainingPlanKind.sequence) {
                  onChanged(TrainingPlanKind.sequence);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanKindOption extends StatelessWidget {
  const _PlanKindOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(DesignConstants.spacingM),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.11)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        width: selected ? 5 : 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

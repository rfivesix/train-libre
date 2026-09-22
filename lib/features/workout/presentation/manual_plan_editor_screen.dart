import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_link_row.dart';
import '../../../widgets/common/app_segmented_control.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../data/manual_training_plan_repository.dart';
import '../data/sources/workout_local_data_source.dart';
import '../domain/models/manual_training_plan.dart';
import '../domain/models/routine.dart';
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
                    onTap: () {
                      close();
                      Navigator.pop(context, 'rest');
                    },
                  ),
                  for (final routine in routines)
                    AppLinkRow(
                      title: routine.name,
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
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        children: [
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
            const SizedBox(height: DesignConstants.spacingL),
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
          ],
          if (_kind == TrainingPlanKind.sequence) ...[
            const SizedBox(height: DesignConstants.spacingL),
            SummaryCard(
                child: Row(children: [
              Expanded(
                  child: Text(
                      '${text.get('length')}: ${_days.length} ${text.get('days')}')),
              IconButton(
                  onPressed: () => _setLength(_days.length - 1),
                  icon: const Icon(LucideIcons.minus)),
              IconButton(
                  onPressed: () => _setLength(_days.length + 1),
                  icon: const Icon(LucideIcons.plus)),
            ])),
          ],
          const SizedBox(height: DesignConstants.spacingM),
          for (var index = 0; index < _days.length; index++)
            SummaryCard(
                child: Row(children: [
              SizedBox(
                  width: 92,
                  child: Text(_kind == TrainingPlanKind.week
                      ? weekdayNames[index]
                      : '${index + 1}. ${text.get('days')}')),
              Expanded(
                  child: InkWell(
                onTap: () => _chooseRoutine(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(_days[index].routineName ?? text.get('rest'),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              )),
              if (!_days[index].isRest)
                IconButton(
                  tooltip: text.get('edit'),
                  onPressed: () => _editRoutine(index),
                  icon: const Icon(LucideIcons.pencil, size: 18),
                ),
              const Icon(LucideIcons.chevron_right, size: 18),
            ])),
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

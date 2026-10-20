import "package:provider/provider.dart";
import "../../services/unit_service.dart";

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../workout/data/sources/workout_local_data_source.dart';
import '../../generated/app_localizations.dart';
import '../exercise_catalog/domain/models/exercise.dart';
import '../workout/domain/models/routine.dart';
import '../workout/domain/models/workout_log.dart';
import '../workout/domain/models/manual_training_plan.dart';
import '../app/presentation/widgets/glass_bottom_menu.dart';
import 'share_card_renderer.dart';
import 'share_labels.dart';
import 'workout_share_formatter.dart';
import 'share_link_codec.dart';
import 'share_link_repository.dart';
import 'share_export_formatter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:async';
import '../../services/telemetry/telemetry_service.dart';

class ShareService {
  const ShareService({ShareCardRenderer renderer = const ShareCardRenderer()})
      : _renderer = renderer;

  final ShareCardRenderer _renderer;

  Future<void> showWorkoutShareSheet({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareWorkout,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.image,
          label: l10n.shareAsImage,
          onTap: () => _showWorkoutImageLayoutSheet(
            context: context,
            workout: workout,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.text_initial,
          label: l10n.shareFormattedText,
          onTap: () => shareWorkoutAsText(context: context, workout: workout),
        ),
        GlassMenuAction(
          icon: LucideIcons.file_text,
          label: l10n.sharePortableJson,
          onTap: () => _showJsonActions(
            context,
            ShareLinkCodec.forWorkout(workout),
          ),
        ),
      ],
    );
  }

  static bool _canShareAsLink(ShareLinkPayload payload) {
    try {
      ShareLinkPayload.fromJson(payload.toJson());
      return ShareLinkCodec.link(payload).length <=
          ShareLinkCodec.maxLinkLength;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sharePayload(
    BuildContext context,
    ShareLinkPayload payload,
  ) async {
    try {
      if (!_canShareAsLink(payload)) return;
      await _shareText(ShareLinkCodec.link(payload), subject: payload.name);
    } catch (_) {
      if (context.mounted) _showLinkError(context);
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.shareFailed)),
    );
  }

  Future<void> showRoutineShareSheet({
    required BuildContext context,
    required Routine routine,
  }) async {
    unawaited(TelemetryService.instance
        .trackFeatureUsed(featureKey: FeatureKey.routineShared));
    final l10n = AppLocalizations.of(context)!;
    final payload = ShareLinkCodec.forRoutine(routine);
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareRoutine,
      actions: [
        if (_canShareAsLink(payload))
          GlassMenuAction(
            icon: LucideIcons.link,
            label: l10n.shareWebLink,
            onTap: () => _sharePayload(context, payload),
          ),
        GlassMenuAction(
          icon: LucideIcons.image,
          label: l10n.shareAsImage,
          onTap: () => _showRoutineImageLayoutSheet(
            context: context,
            routine: routine,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.text_initial,
          label: l10n.shareFormattedText,
          onTap: () => shareRoutineAsText(context: context, routine: routine),
        ),
        GlassMenuAction(
          icon: LucideIcons.file_text,
          label: l10n.sharePortableJson,
          onTap: () => _showJsonActions(context, payload),
        ),
      ],
    );
  }

  Future<void> showPlanShareSheet({
    required BuildContext context,
    required ManualTrainingPlan plan,
  }) async {
    final payload = ShareLinkCodec.forPlan(plan);
    await _showPortableShareSheet(context, payload);
  }

  Future<void> showRecipeShareSheet({
    required BuildContext context,
    required Map<String, dynamic> meal,
  }) async {
    try {
      final payload = await const ShareLinkRepository().forRecipe(meal);
      if (context.mounted) await _showPortableShareSheet(context, payload);
    } catch (_) {
      if (context.mounted) _showLinkError(context);
    }
  }

  Future<void> _showPortableShareSheet(
    BuildContext context,
    ShareLinkPayload payload,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.share,
      actions: [
        if (_canShareAsLink(payload))
          GlassMenuAction(
            icon: LucideIcons.link,
            label: l10n.shareWebLink,
            onTap: () => _sharePayload(context, payload),
          ),
        GlassMenuAction(
          icon: LucideIcons.text_initial,
          label: l10n.shareFormattedText,
          onTap: () => _sharePortableText(context, payload),
        ),
        GlassMenuAction(
          icon: LucideIcons.file_text,
          label: l10n.sharePortableJson,
          onTap: () => _showJsonActions(context, payload),
        ),
      ],
    );
  }

  Future<void> _sharePortableText(
      BuildContext context, ShareLinkPayload payload) async {
    final text = ShareExportFormatter.format(
      payload,
      AppLocalizations.of(context)!,
      context.read<UnitService>(),
      Localizations.localeOf(context).toString(),
    );
    await _shareText(text, subject: payload.name);
  }

  Future<void> _showJsonActions(
      BuildContext context, ShareLinkPayload payload) async {
    final l10n = AppLocalizations.of(context)!;
    late final String content;
    try {
      content = SharePortableCodec.encode(payload);
    } catch (_) {
      if (context.mounted) _showLinkError(context);
      return;
    }
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.sharePortableJson,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.copy,
          label: l10n.shareCopyJson,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: content));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.shareJsonCopied)),
              );
            }
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.file_up,
          label: l10n.shareJsonFile,
          onTap: () => _shareJsonFile(context, payload, content),
        ),
      ],
    );
  }

  Future<void> _shareJsonFile(
      BuildContext context, ShareLinkPayload payload, String content) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/train-libre-${payload.type}-${DateTime.now().microsecondsSinceEpoch}.json');
      await file.writeAsString(content);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: payload.name,
        sharePositionOrigin: _sharePositionOrigin(),
      ));
    } catch (_) {
      if (context.mounted) _showLinkError(context);
    }
  }

  Future<void> _showWorkoutImageLayoutSheet({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareAsImage,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.layout_dashboard,
          label: l10n.shareImageSummary,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.summary,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.list,
          label: l10n.shareImageExercises,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.exercises,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.chart_pie,
          label: l10n.shareImageMuscleFocus,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.muscleFocus,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.square,
          label: l10n.shareImageMinimal,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.minimal,
          ),
        ),
      ],
    );
  }

  Future<void> _showRoutineImageLayoutSheet({
    required BuildContext context,
    required Routine routine,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareAsImage,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.layout_dashboard,
          label: l10n.shareImageSummary,
          onTap: () => shareRoutineAsImage(
            context: context,
            routine: routine,
            layout: RoutineShareCardLayout.summary,
          ),
        ),
        GlassMenuAction(
          icon: LucideIcons.list,
          label: l10n.shareImageExercises,
          onTap: () => shareRoutineAsImage(
            context: context,
            routine: routine,
            layout: RoutineShareCardLayout.exercises,
          ),
        ),
      ],
    );
  }

  Future<void> shareWorkoutAsText({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final unitService = context.read<UnitService>();
    final labels =
        ShareLabels.fromL10n(AppLocalizations.of(context)!, unitService);
    final locale = Localizations.localeOf(context).toString();
    final details = await _loadExerciseDetails(workout);
    final text = WorkoutShareFormatter(
      labels,
      locale: locale,
      exerciseDetails: details,
      unitService: unitService,
    ).format(workout);
    await _shareText(text, subject: workout.routineName ?? labels.appName);
  }

  Future<void> shareRoutineAsText({
    required BuildContext context,
    required Routine routine,
  }) async {
    await _sharePortableText(context, ShareLinkCodec.forRoutine(routine));
  }

  Future<void> shareWorkoutAsImage({
    required BuildContext context,
    required WorkoutLog workout,
    WorkoutShareCardLayout layout = WorkoutShareCardLayout.summary,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    final labels = ShareLabels.fromL10n(l10n, unitService);
    final locale = Localizations.localeOf(context).toString();
    try {
      final details = await _loadExerciseDetails(workout);
      final muscleSummaries = layout == WorkoutShareCardLayout.muscleFocus
          ? await _loadMuscleSummaries(
              workout: workout,
              labels: labels,
              locale: locale,
              exerciseDetails: details,
              unitService: unitService,
            )
          : const <MuscleVolumeSummary>[];
      if (!context.mounted) return;
      final file = await _renderer.renderWorkoutCard(
        context: context,
        workout: workout,
        labels: labels,
        locale: locale,
        layout: layout,
        muscleSummaries: muscleSummaries,
        exerciseDetails: details,
      );
      final formattedText = WorkoutShareFormatter(
        labels,
        locale: locale,
        exerciseDetails: details,
        unitService: unitService,
      ).format(workout);
      await _shareImage(
        file,
        subject: workout.routineName ?? labels.appName,
        text: formattedText,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
      }
      if (context.mounted) {
        await shareWorkoutAsText(context: context, workout: workout);
      }
    }
  }

  Future<void> shareRoutineAsImage({
    required BuildContext context,
    required Routine routine,
    RoutineShareCardLayout layout = RoutineShareCardLayout.summary,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    final labels = ShareLabels.fromL10n(l10n, unitService);
    final locale = Localizations.localeOf(context).toString();
    try {
      final file = await _renderer.renderRoutineCard(
        context: context,
        routine: routine,
        labels: labels,
        locale: locale,
        layout: layout,
      );
      final formattedText = ShareExportFormatter.format(
        ShareLinkCodec.forRoutine(routine),
        l10n,
        unitService,
        locale,
      );
      await _shareImage(
        file,
        subject: routine.name,
        text: formattedText,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
      }
      if (context.mounted) {
        await shareRoutineAsText(context: context, routine: routine);
      }
    }
  }

  Future<void> _shareText(String text, {String? subject}) {
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  Future<void> _shareImage(File file, {String? subject, String? text}) {
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  Future<Map<String, Exercise>> _loadExerciseDetails(WorkoutLog workout) async {
    final details = <String, Exercise>{};
    for (final set in workout.sets) {
      if (details.containsKey(set.exerciseName)) continue;
      final exercise =
          await WorkoutLocalDataSource.instance.resolveExerciseForSetLog(set);
      if (exercise != null) {
        details[set.exerciseName] = exercise;
      }
    }
    return details;
  }

  Future<List<MuscleVolumeSummary>> _loadMuscleSummaries({
    required WorkoutLog workout,
    required ShareLabels labels,
    required String locale,
    required Map<String, Exercise> exerciseDetails,
    required UnitService unitService,
  }) async {
    return WorkoutShareFormatter(
      labels,
      locale: locale,
      exerciseDetails: exerciseDetails,
      unitService: unitService,
    ).muscleVolumeSummaries(workout, exerciseDetails);
  }

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}

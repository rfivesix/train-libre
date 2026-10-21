import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../data/database_helper.dart';
import '../../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../../../diary/presentation/meal_screen.dart';
import '../../../../workout/data/sources/workout_local_data_source.dart';
import '../../../../workout/presentation/routines_screen.dart';
import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_change_proposal.dart';
import 'ai_chat_turn.dart';
import 'cloud_overlay_markdown.dart';

/// Formats generation duration into localized seconds.
String formatGenerationDuration(Duration duration) {
  final seconds = duration.inMilliseconds / 1000.0;
  if (seconds < 10) {
    return '${seconds.toStringAsFixed(1).replaceAll('.', ',')} s';
  } else {
    return '${seconds.toStringAsFixed(0)} s';
  }
}

/// Renders a single conversation turn in the AI overlay.
class CloudChatTurnView extends StatelessWidget {
  const CloudChatTurnView({
    super.key,
    required this.turn,
    required this.contrastColor,
    required this.softColor,
    required this.isStreaming,
    required this.showLoadingCloud,
    required this.loadingCloudAnimation,
    required this.isCopied,
    required this.isGenerating,
    required this.useLiveAi,
    required this.onCopyResponse,
    required this.onCopyFullChat,
    required this.onRetryPrompt,
    required this.onShowAccessAudit,
    required this.onResolveProposal,
    required this.onNavigate,
  });

  final AiChatTurn turn;
  final Color contrastColor;
  final Color softColor;
  final bool isStreaming;
  final bool showLoadingCloud;
  final Animation<double> loadingCloudAnimation;
  final bool isCopied;
  final bool isGenerating;
  final bool useLiveAi;
  final VoidCallback onCopyResponse;
  final VoidCallback onCopyFullChat;
  final VoidCallback onRetryPrompt;
  final ValueChanged<AssistantAccessRecord> onShowAccessAudit;
  final ValueChanged<bool> onResolveProposal;
  final Future<void> Function(WidgetBuilder builder) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompactPrompt = turn.prompt.trim().runes.length <= 2;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final userBubbleColor =
        isDark ? Color.lerp(Colors.black, primary, 0.42)! : primary;
    final userBubbleTextColor =
        isDark ? Colors.white : theme.colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                minWidth: isCompactPrompt ? 56 : 0,
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: userBubbleColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isCompactPrompt
                  ? Center(
                      widthFactor: 1,
                      child: Text(
                        turn.prompt,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: userBubbleTextColor,
                        ),
                      ),
                    )
                  : Text(
                      turn.prompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: userBubbleTextColor,
                      ),
                    ),
            ),
          ),
          if (showLoadingCloud)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: AnimatedBuilder(
                animation: loadingCloudAnimation,
                builder: (context, _) {
                  // 0.0 -> 0.44: nichts -> Kreis (sizeFactor 0 -> 1, morph 0)
                  // 0.44 -> 1.0: Kreis -> Wolke (sizeFactor 1, morph 0 -> 1)
                  // Reverse runs Wolke -> Kreis -> nichts.
                  const split = 0.44;
                  final progress = loadingCloudAnimation.value.clamp(0.0, 1.0);
                  final circleScale = progress <= split
                      ? Curves.easeInOutCubic.transform(
                          (progress / split).clamp(0.0, 1.0),
                        )
                      : 1.0;
                  final cloudMorph = progress <= split
                      ? 0.0
                      : Curves.easeInOutCubic.transform(
                          ((progress - split) / (1.0 - split)).clamp(0.0, 1.0),
                        );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AiNeuralCloudOrbWidget(
                      size: 68,
                      canvasSize: const Size(42, 42),
                      cloudCenter: const Offset(21, 21),
                      sizeFactor: circleScale,
                      morph: 0,
                      instantaneousMorph: cloudMorph,
                      baseColor: contrastColor,
                      showAmbientGlow: false,
                      enableInteraction: false,
                    ),
                  );
                },
              ),
            )
          else if (turn.response.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12),
              child: CloudOverlayMarkdown(
                rawResponse: turn.response,
                contrastColor: contrastColor,
                softColor: softColor,
                isStreaming: isStreaming,
              ),
            ),
            if (turn.changeProposal != null) _buildProposalCard(context, theme),
            if (!isStreaming) _buildActionBar(theme, context),
          ],
        ],
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, ThemeData theme) {
    final proposal = turn.changeProposal!;
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final pending = turn.proposalStatus == 'proposal_pending';
    final title = switch (proposal.payload.type) {
      'routine' => isDe ? 'Routine-Entwurf' : 'Routine draft',
      'plan' => isDe ? 'Trainingsplan-Entwurf' : 'Training plan draft',
      'recipe' => isDe ? 'Rezept-Entwurf' : 'Recipe draft',
      _ => isDe ? 'Entwurf' : 'Draft',
    };
    final action = proposal.operation.name == 'create'
        ? (isDe ? 'Neu erstellen' : 'Create new')
        : (isDe ? 'Ändern' : 'Update');
    final data = proposal.payload.data;
    final rows = switch (proposal.payload.type) {
      'routine' => data['exercises'],
      'plan' => data['days'],
      'recipe' => data['items'],
      _ => null,
    };
    final detail = switch (proposal.payload.type) {
      'routine' when rows is List =>
        '${rows.length} ${isDe ? 'Übungen' : 'exercises'}',
      'plan' when rows is List =>
        '${rows.where((row) => row != null).length} ${isDe ? 'Trainingstage' : 'training days'}',
      'recipe' when rows is List =>
        '${rows.length} ${isDe ? 'Zutaten' : 'ingredients'}',
      _ => '',
    };
    final color = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '$action · $title: ${proposal.payload.name}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(proposal.summary, style: theme.textTheme.bodyMedium),
            if (_proposalMetadata(proposal.payload.type, data, isDe)
                .isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _proposalMetadata(proposal.payload.type, data, isDe),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              textColor: theme.colorScheme.onSurface,
              collapsedTextColor: theme.colorScheme.onSurface,
              iconColor: theme.colorScheme.onSurfaceVariant,
              collapsedIconColor: theme.colorScheme.onSurfaceVariant,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                isDe ? 'Entwurf prüfen' : 'Review draft',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isDe
                    ? 'Details vor dem Speichern ansehen'
                    : 'Inspect details before saving',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children:
                  _proposalDetails(context, proposal.payload.type, data, theme),
            ),
            const SizedBox(height: 12),
            if (pending)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: turn.isApplyingProposal
                        ? null
                        : () => onResolveProposal(true),
                    icon: turn.isApplyingProposal
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.check, size: 16),
                    label: Text(isDe ? 'Übernehmen' : 'Apply'),
                  ),
                  OutlinedButton(
                    onPressed: turn.isApplyingProposal
                        ? null
                        : () => onResolveProposal(false),
                    child: Text(isDe ? 'Verwerfen' : 'Discard'),
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    turn.proposalStatus == 'proposal_applied'
                        ? (isDe ? 'Gespeichert' : 'Saved')
                        : (isDe ? 'Verworfen' : 'Discarded'),
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                  if (turn.proposalStatus == 'proposal_applied' &&
                      const {'routine', 'recipe'}
                          .contains(proposal.payload.type)) ...[
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => _openSavedItem(proposal),
                      icon: Icon(LucideIcons.external_link, size: 16),
                      label: Text(isDe ? 'Öffnen' : 'Open'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSavedItem(
    AssistantChangeProposal proposal,
  ) async {
    final expectedName = proposal.payload.name.trim().toLowerCase();
    switch (proposal.payload.type) {
      case 'routine':
        final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
        int? matchingRoutineId;
        for (final routine in routines) {
          if (routine.name.trim().toLowerCase() == expectedName) {
            matchingRoutineId = routine.id;
            break;
          }
        }
        await onNavigate(
          (_) => RoutinesScreen(initialRoutineId: matchingRoutineId),
        );
      case 'recipe':
        final meals = await DatabaseHelper.instance.getMeals();
        Map<String, dynamic>? matchingMeal;
        for (final meal in meals) {
          if ((meal['name'] as String? ?? '').trim().toLowerCase() ==
              expectedName) {
            matchingMeal = meal;
            break;
          }
        }
        if (matchingMeal != null) {
          await onNavigate((_) => MealScreen(meal: matchingMeal!));
        }
      default:
        return;
    }
  }

  String _proposalMetadata(String type, Map<String, dynamic> data, bool isDe) {
    final values = <String>[];
    if (type == 'recipe') {
      if (data['portions'] != null) {
        values.add('${isDe ? 'Portionen' : 'Servings'}: ${data['portions']}');
      }
      if (data['cookedWeightInGrams'] != null) {
        values.add(
            '${isDe ? 'Fertiggewicht' : 'Cooked weight'}: ${data['cookedWeightInGrams']} g');
      }
    }
    if (type == 'plan') {
      if (data['kind'] is String) {
        values.add('${isDe ? 'Planart' : 'Plan type'}: ${data['kind']}');
      }
      if (data['lengthDays'] != null) {
        values.add('${isDe ? 'Tage' : 'Days'}: ${data['lengthDays']}');
      }
    }
    if (data['notes'] is String && (data['notes'] as String).isNotEmpty) {
      values.add('${isDe ? 'Notiz' : 'Notes'}: ${data['notes']}');
    }
    return values.join(' · ');
  }

  List<Widget> _proposalDetails(
    BuildContext context,
    String type,
    Map<String, dynamic> data,
    ThemeData theme,
  ) {
    final rows = switch (type) {
      'routine' => data['exercises'],
      'plan' => data['days'],
      'recipe' => data['items'],
      _ => null,
    };
    if (rows is! List || rows.isEmpty) {
      return [
        Text(Localizations.localeOf(context).languageCode == 'de'
            ? 'Keine Details verfügbar.'
            : 'No details available.')
      ];
    }
    return [
      for (var index = 0; index < rows.length; index++)
        if (rows[index] case final Map row?)
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _proposalRowTitle(context, type, row, index),
                    textAlign: TextAlign.start,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _proposalRowSubtitle(context, type, row),
                    textAlign: TextAlign.start,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  String _proposalRowTitle(
      BuildContext context, String type, Map row, int index) {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final localizedName = row['displayName'] is String &&
            (row['displayName'] as String).trim().isNotEmpty
        ? row['displayName'] as String
        : row['name'] ?? (isDe ? 'Übung' : 'Exercise');
    return switch (type) {
      'routine' => '${index + 1}. $localizedName',
      'plan' =>
        '${index + 1}. ${row['n'] ?? (isDe ? 'Trainingstag' : 'Training day')}',
      'recipe' =>
        '${row['name'] ?? (isDe ? 'Zutat' : 'Ingredient')} · ${row['grams'] ?? '?'} ${row['unit'] ?? 'g'}',
      _ => '${index + 1}',
    };
  }

  String _proposalRowSubtitle(BuildContext context, String type, Map row) {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    if (type == 'routine') {
      final sets = row['sets'];
      if (sets is! List || sets.isEmpty) {
        return isDe ? 'Keine Sätze' : 'No sets';
      }
      final prescription = sets
          .map((raw) {
            if (raw is! Map) return '';
            final reps = raw['reps'] ??
                (raw['repMin'] != null
                    ? '${raw['repMin']}-${raw['repMax']}'
                    : null);
            final weight = raw['weight'];
            return [
              reps?.toString(),
              if (weight != null) '$weight kg',
              if (raw['rir'] != null) 'RIR ${raw['rir']}',
            ].whereType<String>().join(' · ');
          })
          .where((value) => value.isNotEmpty)
          .join(' / ');
      final extras = [
        if (row['pause'] is num)
          '${row['pause']} ${isDe ? 'Sek. Pause' : 'sec rest'}',
        if (row['notes'] is String && (row['notes'] as String).isNotEmpty)
          '${isDe ? 'Notiz' : 'Note'}: ${row['notes']}',
      ];
      return [prescription, ...extras]
          .where((item) => item.isNotEmpty)
          .join('\n');
    }
    if (type == 'plan') {
      final day = row['d'];
      if (day is Map) {
        final exercises = day['exercises'];
        if (exercises is List) {
          return exercises
              .whereType<Map>()
              .map((exercise) {
                final name = exercise['name']?.toString() ?? '';
                final sets = exercise['sets'];
                final prescription = sets is List
                    ? sets
                        .whereType<Map>()
                        .map((set) {
                          final reps = set['reps'] ??
                              (set['repMin'] != null
                                  ? '${set['repMin']}-${set['repMax']}'
                                  : null);
                          return [
                            reps?.toString(),
                            if (set['weight'] != null) '${set['weight']} kg',
                            if (set['rir'] != null) 'RIR ${set['rir']}',
                          ].whereType<String>().join(' · ');
                        })
                        .where((item) => item.isNotEmpty)
                        .join(' / ')
                    : '';
                return [name, prescription]
                    .where((item) => item.isNotEmpty)
                    .join(': ');
              })
              .where((name) => name.isNotEmpty)
              .join('\n');
        }
      }
      return isDe
          ? 'Ruhetag oder zugeordnete Routine'
          : 'Rest day or assigned routine';
    }
    if (type == 'recipe') {
      final values = [
        if (row['kcal'] != null) '${row['kcal']} kcal',
        if (row['protein'] != null) '${row['protein']} g protein',
        if (row['carbs'] != null) '${row['carbs']} g carbs',
        if (row['fat'] != null) '${row['fat']} g fat',
      ];
      return values.join(' · ');
    }
    return '';
  }

  Widget _buildActionBar(ThemeData theme, BuildContext context) {
    final subtleColor = contrastColor.withValues(alpha: 0.52);
    final modelLabel = turn.modelName;
    final durationLabel =
        turn.duration != null ? formatGenerationDuration(turn.duration!) : null;

    final metaText = [
      if (modelLabel != null && modelLabel.isNotEmpty) modelLabel,
      if (durationLabel != null) durationLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIconButton(
            icon: isCopied ? LucideIcons.check : LucideIcons.copy,
            tooltip: 'Antwort kopieren (Lange drücken: Gesamten Chat kopieren)',
            onTap: onCopyResponse,
            onLongPress: onCopyFullChat,
            foregroundColor: isCopied
                ? (theme.brightness == Brightness.dark
                    ? Colors.greenAccent
                    : Colors.green.shade700)
                : subtleColor,
          ),
          const SizedBox(width: 4),
          _buildActionIconButton(
            icon: LucideIcons.rotate_cw,
            tooltip: 'Erneut versuchen',
            onTap: isGenerating ? null : onRetryPrompt,
            foregroundColor: subtleColor,
          ),
          if (useLiveAi && turn.access != null) ...[
            const SizedBox(width: 4),
            PlatformAdaptivePopupMenu<String>(
              icon: Semantics(
                button: true,
                label: Localizations.localeOf(context).languageCode == 'de'
                    ? 'Weitere Optionen'
                    : 'More options',
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Icon(
                      LucideIcons.ellipsis,
                      size: 18,
                      color: subtleColor,
                    ),
                  ),
                ),
              ),
              menuWidth: 220,
              items: [
                PlatformAdaptivePopupMenuItem(
                  value: 'dataAccess',
                  label: Localizations.localeOf(context).languageCode == 'de'
                      ? 'Datenzugriff'
                      : 'Data access',
                ),
              ],
              onSelected: (_) => onShowAccessAudit(turn.access!),
            ),
          ],
          if (metaText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              metaText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: subtleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    required Color foregroundColor,
  }) {
    return Semantics(
      button: onTap != null,
      label: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

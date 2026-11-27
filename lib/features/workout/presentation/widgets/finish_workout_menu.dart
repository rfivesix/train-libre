import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';

typedef FinishWorkoutChoice = ({String title, String notes, bool discard});

Future<FinishWorkoutChoice?> showFinishWorkoutMenu(
  BuildContext context,
  String defaultTitle,
) async {
  final l10n = AppLocalizations.of(context)!;
  final titleController = TextEditingController(text: defaultTitle);
  final notesController = TextEditingController();

  final result =
      await showGlassBottomMenu<({String title, String notes, bool discard})>(
        context: context,
        title: l10n.finishWorkoutButton,
        contentBuilder: (ctx, close) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  l10n.dialogFinishWorkoutBody,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n.finishWorkoutTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n.finishWorkoutNotesLabel,
                  hintText: l10n.finishWorkoutNotesHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton.danger(
                      onPressed: () async {
                        final confirmed = await showDeleteConfirmation(
                          ctx,
                          title: l10n.discardWorkoutAction,
                          content: l10n.deleteWorkoutConfirmContent,
                          confirmLabel: l10n.discardWorkoutAction,
                        );
                        if (confirmed && ctx.mounted) {
                          Navigator.of(ctx)
                              .pop((title: '', notes: '', discard: true));
                        }
                      },
                      label: l10n.discardWorkoutAction,
                      tooltip: l10n.discardWorkoutAction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      onPressed: () {
                        Navigator.of(ctx).pop((
                          title: titleController.text.trim(),
                          notes: notesController.text.trim(),
                          discard: false,
                        ));
                      },
                      label: l10n.finishWorkoutButton,
                      tooltip: l10n.finishWorkoutButton,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

  titleController.dispose();
  notesController.dispose();

  return result;
}

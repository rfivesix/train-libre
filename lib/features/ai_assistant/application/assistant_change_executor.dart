import '../../../data/database_helper.dart';
import '../../../features/sharing/share_link_repository.dart';
import '../domain/assistant_change_proposal.dart';

/// Applies only a proposal that has already passed the in-app user review.
/// All payloads are decoded by the existing portable import codec first.
class AssistantChangeExecutor {
  const AssistantChangeExecutor(
      {ShareLinkRepository sharing = const ShareLinkRepository()})
      : _sharing = sharing;

  final ShareLinkRepository _sharing;

  Future<void> apply(AssistantChangeProposal proposal) async {
    final database = DatabaseHelper.instance.dbInstance;
    final payload = proposal.payload;
    switch (proposal.operation) {
      case AssistantChangeOperation.create:
        switch (payload.type) {
          case 'routine':
            await _sharing.importRoutine(payload);
          case 'recipe':
            await _sharing.import(payload);
          case 'plan':
            await _sharing.import(payload);
          default:
            throw const FormatException('Unsupported change proposal.');
        }
      case AssistantChangeOperation.update:
        final targetId = proposal.targetId!;
        switch (payload.type) {
          case 'routine':
            final target = await (database.select(database.routines)
                  ..where((row) => row.id.equals(targetId)))
                .getSingleOrNull();
            if (target == null) throw StateError('Routine no longer exists.');
            await _sharing.replaceRoutine(target.localId, payload);
          case 'recipe':
            final target = await (database.select(database.meals)
                  ..where((row) => row.id.equals(targetId)))
                .getSingleOrNull();
            if (target == null) throw StateError('Recipe no longer exists.');
            await _sharing.replaceRecipe(target.localId, payload);
          case 'plan':
            final target = await (database.select(database.trainingPlans)
                  ..where((row) => row.id.equals(targetId)))
                .getSingleOrNull();
            if (target == null) throw StateError('Plan no longer exists.');
            await _sharing.replacePlan(
              target.id,
              payload,
              nextCycle: proposal.nextCycle,
            );
          default:
            throw const FormatException('Unsupported change proposal.');
        }
    }
  }
}

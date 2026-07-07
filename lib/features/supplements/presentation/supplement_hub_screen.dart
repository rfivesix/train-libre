// lib/features/supplements/presentation/supplement_hub_screen.dart
import 'package:flutter/material.dart';
import '../domain/repositories/supplement_repository.dart';
import '../data/supplement_repository_impl.dart';
import '../data/sources/supplement_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/supplement.dart';
import 'create_supplement_screen.dart';
import '../../../util/design_constants.dart';
import '../../../util/supplement_l10n.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/swipe_action_background.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A screen for managing the catalog of available supplements (Supplement Hub).
class SupplementHubScreen extends StatefulWidget {
  final SupplementRepository? repository;

  const SupplementHubScreen({super.key, this.repository});

  @override
  State<SupplementHubScreen> createState() =>
      _SupplementHubScreenState();
}

class _SupplementHubScreenState extends State<SupplementHubScreen> {
  late final SupplementRepository _repository = widget.repository ??
      SupplementRepositoryImpl(
        localDataSource: SupplementLocalDataSource.instance,
      );
  bool _isLoading = true;
  List<Supplement> _supplements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _repository.getAllSupplements();
    if (!mounted) return;

    final sortedList = List<Supplement>.from(list)
      ..sort((a, b) {
        if (a.isTracked != b.isTracked) {
          return a.isTracked ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    setState(() {
      _supplements = sortedList;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEdit(Supplement s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateSupplementScreen(
            supplementToEdit: s, repository: _repository),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Supplement s) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await showGlassBottomMenu<bool>(
            context: context,
            title: l10n.deleteConfirmTitle,
            contentBuilder: (ctx, close) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
                     child: Text(
                       l10n.deleteSupplementConfirm,
                       textAlign: TextAlign.center,
                     ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop(false);
                          },
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop(true);
                          },
                          child: Text(l10n.delete),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!ok) return;

      await _repository.deleteSupplement(s.id!);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleted)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.operationNotAllowed)));
    }
  }

  Widget _tile(Supplement s, AppLocalizations l10n) {
    final isBuiltin = s.isBuiltin ||
        s.code == 'caffeine' ||
        s.name.toLowerCase() == 'caffeine';
    final title = localizeSupplementName(s, l10n);

    final content = SummaryCard(
      child: ListTile(
        leading: SizedBox(
          height: double.infinity,
          child: Icon(
            s.isTracked ? LucideIcons.circle_check : LucideIcons.circle,
            color: s.isTracked ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(title),
        subtitle: (s.dailyGoal != null || s.dailyLimit != null)
            ? Text(
                [
                  if (s.dailyGoal != null)
                    '${l10n.dailyGoalLabel}: ${s.dailyGoal} ${s.unit}',
                  if (s.dailyLimit != null)
                    '${l10n.dailyLimitLabel}: ${s.dailyLimit} ${s.unit}',
                ].join('  •  '),
              )
            : null,
        trailing: isBuiltin ? null : const Icon(LucideIcons.chevron_right),
        onTap: () => _navigateToEdit(s),
      ),
    );

    if (isBuiltin) return content;

    return Dismissible(
      key: Key('supp_${s.id}'),
      direction: DismissDirection.horizontal,
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: LucideIcons.pencil,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: LucideIcons.trash_2,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _navigateToEdit(s);
          return false;
        } else {
          _delete(s);
          return false;
        }
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.supplementTrackerTitle),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: _supplements.isEmpty,
        extendBodyBehindAppBar: true,
        child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: DesignConstants.cardPadding.copyWith(
                    top: DesignConstants.cardPadding.top + topPadding,
                  ),
                  children: [
                    if (_supplements.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          l10n.emptySupplements,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._supplements.map((s) => _tile(s, l10n)),
                  ],
                ),
              ),
      ),
      floatingActionButton: GlassFab(
        label: l10n.createSupplementTitle,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) =>
                  CreateSupplementScreen(repository: _repository),
            ),
          );
          if (created == true) _load();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

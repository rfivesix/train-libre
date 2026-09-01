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
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/glass_actionable_card.dart';
import '../../../widgets/common/morph_source.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

/// A screen for managing the catalog of available supplements (Supplement Hub).
class SupplementHubScreen extends StatefulWidget {
  final SupplementRepository? repository;

  const SupplementHubScreen({super.key, this.repository});

  @override
  State<SupplementHubScreen> createState() => _SupplementHubScreenState();
}

class _SupplementHubScreenState extends State<SupplementHubScreen> {
  late final SupplementRepository _repository = widget.repository ??
      SupplementRepositoryImpl(
        localDataSource: SupplementLocalDataSource.instance,
      );
  bool _isLoading = true;
  bool _isFabHidden = false;
  List<Supplement> _supplements = const [];

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.supplementsOverview));
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

  Future<void> _navigateToEdit(
    Supplement s, {
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      CardMorphRoute(
        sourceContext: sourceContext,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
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
                        child: AppButton.secondary(
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop(false);
                          },
                          label: l10n.cancel,
                          tooltip: l10n.cancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.primary(
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop(true);
                          },
                          label: l10n.delete,
                          tooltip: l10n.delete,
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
    final isBuiltin = s.isBuiltin || s.isCaffeine;
    final title = localizeSupplementName(s, l10n);

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) {
          // `late` because the tile's own onTap hands this widget back to the
          // morph route as the source copy to fly with.
          late final Widget content;
          content = SummaryCard(
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
              onTap: () => _navigateToEdit(
                s,
                sourceContext: cardCtx,
                sourceBuilder: (_) => content,
                onSourceVisibilityChanged: setHidden,
              ),
            ),
          );

          if (isBuiltin) return content;

          return GlassActionableCard(
            dismissibleKey: Key('supp_${s.id}'),
            onEdit: () => _navigateToEdit(
              s,
              sourceContext: cardCtx,
              sourceBuilder: (_) => content,
              onSourceVisibilityChanged: setHidden,
            ),
            onDelete: () => _delete(s),
            confirmDelete: () async => false,
            child: content,
          );
        },
      ),
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
      body: Stack(
        children: [
          SeamlessLoadingOverlay(
            isLoading: _isLoading,
            isEmpty: _supplements.isEmpty,
            extendBodyBehindAppBar: true,
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: DesignConstants.cardPadding.copyWith(
                  top: DesignConstants.cardPadding.top + topPadding,
                  bottom: DesignConstants.cardPadding.bottom + 80.0,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: DesignConstants.bottomVignetteHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: DesignConstants.bottomVignetteGradient(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Opacity(
        opacity: _isFabHidden ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: _isFabHidden,
          child: Builder(
            builder: (fabCtx) {
              Widget buildFab({VoidCallback? onPressed}) => GlassFab(
                    label: l10n.createSupplementTitle,
                    onPressed: onPressed ?? () {},
                  );

              return GlassFab(
                label: l10n.createSupplementTitle,
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    CardMorphRoute(
                      sourceContext: fabCtx,
                      sourceBorderRadius: 28.0,
                      sourceBuilder: (_) => buildFab(),
                      onSourceVisibilityChanged: (hidden) {
                        if (mounted) setState(() => _isFabHidden = hidden);
                      },
                      builder: (context) =>
                          CreateSupplementScreen(repository: _repository),
                    ),
                  );
                  if (created == true) _load();
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

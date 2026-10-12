import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'statistics_hub_preferences.dart';

class StatisticsHubEditScreen extends StatefulWidget {
  const StatisticsHubEditScreen({super.key});

  @override
  State<StatisticsHubEditScreen> createState() =>
      _StatisticsHubEditScreenState();
}

class _StatisticsHubEditScreenState extends State<StatisticsHubEditScreen> {
  late Future<List<StatisticsHubCardId>> _load;
  List<StatisticsHubCardId> _pinned = [];
  Future<void> _pendingSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _load = StatisticsHubPreferences.loadPinnedCards()
      ..then((cards) {
        if (mounted) setState(() => _pinned = List.of(cards));
      });
  }

  String _cardName(StatisticsHubCardId card, AppLocalizations l10n) {
    switch (card) {
      case StatisticsHubCardId.steps:
        return l10n.steps;
      case StatisticsHubCardId.sleep:
        return l10n.sleepHubScoreLabel;
      case StatisticsHubCardId.pulse:
        return l10n.pulseTitle;
      case StatisticsHubCardId.bodyNutrition:
        return l10n.sectionBodyNutrition;
      case StatisticsHubCardId.bodyMeasurements:
        return l10n.body_measurements;
      case StatisticsHubCardId.consistency:
        return l10n.consistencyTrackerTitle;
      case StatisticsHubCardId.performance:
        return l10n.analyticsNewBestPerformances;
      case StatisticsHubCardId.muscleGroups:
        return l10n.analyticsMuscleGroups;
      case StatisticsHubCardId.macros:
        return l10n.nutrition;
    }
  }

  String _categoryName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'activity':
        return l10n.statisticsActivityCategory;
      case 'recovery':
        return l10n.sectionRecovery;
      case 'body':
        return l10n.statisticsSectionBody;
      case 'training':
        return l10n.statisticsSectionTraining;
      default:
        return l10n.nutrition;
    }
  }

  Future<void> _save() {
    final snapshot = List<StatisticsHubCardId>.of(_pinned);
    _pendingSave = _pendingSave.then(
      (_) => StatisticsHubPreferences.savePinnedCards(snapshot),
    );
    return _pendingSave;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.statisticsEditCardsTitle,
        actions: [
          TextButton(
            onPressed: () async {
              await _pendingSave;
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.doneButtonLabel),
          ),
        ],
      ),
      body: FutureBuilder<List<StatisticsHubCardId>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final unpinned = StatisticsHubCardId.values
              .where((card) => !_pinned.contains(card))
              .toList(growable: false);
          const categories = [
            'activity',
            'recovery',
            'body',
            'training',
            'nutrition',
          ];

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.screenPaddingHorizontal,
                  MediaQuery.paddingOf(context).top +
                      kToolbarHeight -
                      DesignConstants.spacingM,
                  DesignConstants.screenPaddingHorizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _sectionHeader(
                    l10n.statisticsPinnedTitle,
                    first: true,
                  ),
                ),
              ),
              if (_pinned.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                      child: Text(
                        l10n.statisticsPinnedEmptyHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: _pinned.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final card = _pinned.removeAt(oldIndex);
                        _pinned.insert(newIndex, card);
                      });
                      _save();
                    },
                    itemBuilder: (context, index) => _buildPinnedRow(
                      context,
                      l10n,
                      _pinned[index],
                      index,
                      _pinned.length,
                    ),
                  ),
                ),
              if (unpinned.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(l10n.statisticsAddCardsTitle),
                        for (final category in categories)
                          if (unpinned
                              .any((card) => card.categoryId == category)) ...[
                            const SizedBox(
                              height: DesignConstants.spacingM,
                            ),
                            _sectionHeader(_categoryName(category, l10n)),
                            _buildAvailableList(
                              context,
                              unpinned
                                  .where((card) => card.categoryId == category)
                                  .toList(growable: false),
                              l10n,
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: DesignConstants.bottomContentSpacer),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {bool first = false}) => AppSectionHeader(
        title: title,
        isFirst: first,
      );

  Widget _buildPinnedRow(
    BuildContext context,
    AppLocalizations l10n,
    StatisticsHubCardId card,
    int index,
    int count,
  ) {
    final theme = Theme.of(context);
    final radius = DesignConstants.borderRadiusL;
    final borderRadius = BorderRadius.vertical(
      top: index == 0 ? Radius.circular(radius) : Radius.zero,
      bottom: index == count - 1 ? Radius.circular(radius) : Radius.zero,
    );
    final surface = theme.brightness == Brightness.dark
        ? DesignConstants.summaryCardDarkMode
        : Colors.white;

    return Material(
      key: ValueKey(card.storageId),
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _cardName(card, l10n),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.statisticsRemoveCard,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.circle_minus, size: 20),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    setState(() => _pinned.remove(card));
                    _save();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (index < count - 1) const Divider(height: 1, indent: 52),
        ],
      ),
    );
  }

  Widget _buildAvailableList(
    BuildContext context,
    List<StatisticsHubCardId> cards,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            InkWell(
              onTap: () {
                setState(() => _pinned.add(cards[index]));
                _save();
              },
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _cardName(cards[index], l10n),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Icon(
                        LucideIcons.circle_plus,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index < cards.length - 1) const Divider(height: 1, indent: 16),
          ],
        ],
      ),
    );
  }
}

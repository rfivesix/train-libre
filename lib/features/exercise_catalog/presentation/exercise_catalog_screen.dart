// lib/features/exercise_catalog/presentation/exercise_catalog_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'create_exercise_screen.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/morph_source.dart';
import '../../../widgets/common/glass_fab.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../domain/body_slug_mapper.dart';
import '../../../services/telemetry/telemetry_service.dart';

/// A searchable list of all available exercises in the database.
class ExerciseCatalogScreen extends StatefulWidget {
  /// Whether the screen is used to select an exercise to return to a caller.
  final bool isSelectionMode;

  /// Optional callback for handling the selection manually instead of popping.
  final void Function(Exercise)? onExerciseSelected;
  final IExerciseCatalogRepository? repository;

  const ExerciseCatalogScreen({
    super.key,
    this.isSelectionMode = false,
    this.onExerciseSelected,
    this.repository,
  });

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
  List<Exercise> _foundExercises = [];
  bool _isLoading = true;
  bool _isFabHidden = false;
  final _searchController = TextEditingController();
  List<String> _allCategories = [];
  final List<String> _selectedCategories = [];

  /// The load-bearing implement per exercise, from the catalog. Empty until a
  /// v2 catalog has been imported, which is what hides the filter entirely on
  /// an older one rather than showing an empty menu.
  List<({String id, String name})> _allEquipment = [];
  final List<String> _selectedEquipment = [];

  List<String> _allUsageTags = [];
  final List<String> _selectedUsageTags = [];

  Timer? _searchDebounce;

  bool _isWgerDbInitialized = false;

  Future<void> _checkDbStatus() async {
    final initialized =
        await BasisDataManager.instance.isExerciseCatalogInitialized();
    if (mounted) {
      setState(() {
        _isWgerDbInitialized = initialized;
      });
      if (initialized) {
        _loadCategories();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.exerciseCatalog));
    _searchController.addListener(_onSearchChanged);
    _checkDbStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BasisDataManager.instance
          .promptOffDatabaseDownloadIfFirstTime(context);
      await _checkDbStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runFilter(_searchController.text);
    });
  }

  Future<void> _loadCategories() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = await _repository.getAllCategories();
    final equipment = await _repository.getPrimaryEquipment(languageCode);
    final usageTags = await _repository.getUsageTags();
    if (!mounted) return;
    setState(() {
      _allCategories = categories;
      _allEquipment = equipment;
      _allUsageTags = usageTags;
      _isLoading = false;
    });
    _runFilter(_searchController.text);
  }

  void _runFilter(String enteredKeyword) async {
    final results = await _repository.searchExercises(
      query: enteredKeyword,
      categories: _selectedCategories,
      equipmentIds: _selectedEquipment,
      usageTags: _selectedUsageTags,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (mounted) {
      setState(() {
        _foundExercises = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_isWgerDbInitialized) {
      return Scaffold(
        appBar: GlobalAppBar(title: l10n.shareExercisesLabel),
        body: DatabasePlaceholderWidget(
          title: l10n.offDownloadTitle,
          body: l10n.wgerPlaceholderText,
          icon: LucideIcons.dumbbell,
          onDownloadPressed: () async {
            await BasisDataManager.instance
                .promptOffDatabaseDownloadIfFirstTime(context);
            await _checkDbStatus();
          },
        ),
      );
    }

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.exerciseCatalogTitle,
        actions: [
          if (widget.isSelectionMode)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.doneButtonLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignConstants.spacingL,
                  right: DesignConstants.spacingL,
                  top: DesignConstants.spacingS,
                  bottom: DesignConstants.spacingS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.searchHintText,
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: l10n.clearSearch,
                                      icon: Icon(
                                        LucideIcons.x,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        _buildFilterButton(context, l10n),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _foundExercises.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noExercisesFound,
                              style: textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            scrollCacheExtent:
                                const ScrollCacheExtent.pixels(1500.0),
                            padding: DesignConstants.cardPadding,
                            itemCount: _foundExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _foundExercises[index];
                              return MorphSourceScope(
                                builder: (context, setHidden) => Builder(
                                  builder: (cardCtx) {
                                    // Handed to the morph route as the copy that flies with
                                    // the container, so the card dissolves into the detail
                                    // screen instead of the screen simply growing.
                                    late final Widget card;
                                    card = SummaryCard(
                                      child: ListTile(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                exercise
                                                    .getLocalizedName(context),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            if (exercise.source == 'user') ...[
                                              const SizedBox(
                                                  width:
                                                      DesignConstants.spacingS),
                                              _buildSourceBadge(
                                                  context, exercise.source),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(
                                          BodySlugMapper.localize(
                                            context,
                                            exercise.categoryName,
                                          ),
                                        ),
                                        trailing: widget.isSelectionMode
                                            ? IconButton(
                                                tooltip: l10n.add_button,
                                                icon: Icon(
                                                  LucideIcons.circle_plus,
                                                  color: colorScheme.primary,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(exercise),
                                              )
                                            : const Icon(
                                                LucideIcons.chevron_right,
                                              ),
                                        onTap: () {
                                          if (widget.onExerciseSelected !=
                                              null) {
                                            widget
                                                .onExerciseSelected!(exercise);
                                          } else if (widget.isSelectionMode) {
                                            Navigator.of(context).pop(exercise);
                                          } else {
                                            Navigator.of(context)
                                                .push(
                                              CardMorphRoute(
                                                sourceContext: cardCtx,
                                                sourceBuilder: (_) => card,
                                                onSourceVisibilityChanged:
                                                    setHidden,
                                                builder: (context) =>
                                                    ExerciseDetailScreen(
                                                        exercise: exercise,
                                                        repository:
                                                            _repository),
                                              ),
                                            )
                                                .then((result) {
                                              if (result == 'deleted') {
                                                _runFilter(
                                                    _searchController.text);
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    );
                                    return card;
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
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
                    label: l10n.create_exercise_screen_title,
                    onPressed: onPressed ?? () {},
                  );

              return GlassFab(
                label: l10n.create_exercise_screen_title,
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    CardMorphRoute(
                      sourceContext: fabCtx,
                      sourceBorderRadius: 28.0,
                      sourceBuilder: (_) => buildFab(),
                      onSourceVisibilityChanged: (hidden) {
                        if (mounted) setState(() => _isFabHidden = hidden);
                      },
                      builder: (context) =>
                          CreateExerciseScreen(repository: _repository),
                    ),
                  )
                      .then((wasCreated) {
                    if (wasCreated == true) {
                      _runFilter(_searchController.text);
                    }
                  });
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFilter = _selectedCategories.isNotEmpty ||
        _selectedEquipment.isNotEmpty ||
        _selectedUsageTags.isNotEmpty;

    final fillColor = hasFilter
        ? colorScheme.primary
        : (theme.inputDecorationTheme.fillColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF3F3F3)));

    final iconColor =
        hasFilter ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return PlatformAdaptivePopupMenu<String>(
      icon: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
        child: Center(
          child: Icon(
            LucideIcons.list_filter,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
      // One menu, three groups. The values are prefixed so the handler can
      // tell a body region from a dumbbell without three separate menus in a
      // toolbar that has room for one.
      items: [
        for (final category in _allCategories)
          PlatformAdaptivePopupMenuItem<String>(
            value: 'category:$category',
            label: BodySlugMapper.localize(context, category),
            icon: _selectedCategories.contains(category)
                ? LucideIcons.check
                : null,
          ),
        for (final equipment in _allEquipment)
          PlatformAdaptivePopupMenuItem<String>(
            value: 'equipment:${equipment.id}',
            label: equipment.name,
            icon: _selectedEquipment.contains(equipment.id)
                ? LucideIcons.check
                : null,
          ),
        for (final tag in _allUsageTags)
          PlatformAdaptivePopupMenuItem<String>(
            value: 'tag:$tag',
            label: _usageTagLabel(tag),
            icon: _selectedUsageTags.contains(tag) ? LucideIcons.check : null,
          ),
      ],
      onSelected: (value) {
        final separator = value.indexOf(':');
        if (separator < 0) return;
        final kind = value.substring(0, separator);
        final id = value.substring(separator + 1);

        setState(() {
          final target = switch (kind) {
            'equipment' => _selectedEquipment,
            'tag' => _selectedUsageTags,
            _ => _selectedCategories,
          };
          if (target.contains(id)) {
            target.remove(id);
          } else {
            target.add(id);
          }
        });
        _runFilter(_searchController.text);
      },
    );
  }

  /// A readable label for a usage tag.
  ///
  /// The catalog ships these as identifiers, not as prose, and there is no
  /// translation table for them the way there is for muscles and equipment —
  /// so this is a presentation concern until there is.
  String _usageTagLabel(String tag) {
    final words = tag.split('_').where((w) => w.isNotEmpty);
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Widget _buildSourceBadge(BuildContext context, String source) {
    final theme = Theme.of(context);
    const color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.spacingS, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        AppLocalizations.of(context)!.customLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

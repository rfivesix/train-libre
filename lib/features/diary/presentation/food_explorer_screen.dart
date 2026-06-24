// lib/screens/food_explorer_screen.dart (Final & De-Materialisiert)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/sources/product_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_item.dart';
import 'create_food_screen.dart';
import 'food_detail_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/glass_fab.dart';
import 'widgets/off_attribution_widget.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/summary_card.dart'; // Added
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/database_placeholder_widget.dart';

/// A screen for exploring and managing the food database independently of tracking.
///
/// Allows searching for products and managing favorites without requiring
/// a target date or meal context.
class FoodExplorerScreen extends StatefulWidget {
  const FoodExplorerScreen({super.key});

  @override
  State<FoodExplorerScreen> createState() => _FoodExplorerScreenState();
}

class _FoodExplorerScreenState extends State<FoodExplorerScreen>
    with SingleTickerProviderStateMixin {
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = "";
  final _searchController = TextEditingController();

  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  late TabController _tabController;
  Timer? _searchDebounce;
  bool _isOffDbInitialized = false;

  Future<void> _checkDbStatus() async {
    final initialized = await BasisDataManager.instance.isOffDatabaseInitialized();
    if (mounted) {
      setState(() {
        _isOffDbInitialized = initialized;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkDbStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(context);
      await _checkDbStatus();
    });
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runFilter(query);
    });
  }

  void _runFilter(String enteredKeyword) async {
    final l10n = AppLocalizations.of(context)!;

    if (enteredKeyword.isEmpty) {
      setState(() {
        _foundFoodItems = [];
        _searchInitialText = l10n.searchInitialHint;
      });
      return;
    }
    setState(() {
      _isLoadingSearch = true;
    });
    final results = await ProductLocalDataSource.instance.searchProducts(
      enteredKeyword,
    );
    if (mounted) {
      setState(() {
        _foundFoodItems = results;
        _isLoadingSearch = false;
        if (results.isEmpty) {
          _searchInitialText = l10n.searchNoResults;
        }
      });
    }
  }

  void _navigateAndCreateFood() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreateFoodScreen()))
        .then((_) {
      _searchController.clear();
      _runFilter('');
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
    });
    final results = await ProductLocalDataSource.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteFoodItems = results;
        _isLoadingFavorites = false;
      });
    }
  }

  // lib/screens/food_explorer_screen.dart

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // FIX: Query theme mode directly.
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL,
              vertical: DesignConstants.spacingXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addFoodTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: const BoxDecoration(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  dividerColor: Colors.transparent,
                  // FIX: Dynamic color based on theme mode.
                  labelColor: isLightMode ? Colors.black : Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.0,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.0,
                  ),
                  tabs: [
                    Tab(text: l10n.tabSearch),
                    Tab(text: l10n.tabFavorites),
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
            child: TabBarView(
              controller: _tabController,
              children: [_buildSearchTab(l10n), _buildFavoritesTab(l10n)],
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        onPressed: _navigateAndCreateFood,
        label: l10n.createFoodScreenTitle,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    if (!_isOffDbInitialized) {
      return DatabasePlaceholderWidget(
        title: l10n.offDownloadTitle,
        body: l10n.offPlaceholderText,
        icon: LucideIcons.database,
        onDownloadPressed: () async {
          await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(context);
          await _checkDbStatus();
        },
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: DesignConstants.cardPadding,
      child: Column(
        children: [
          // FIX 4: TextField uses global InputDecorationTheme.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchHintText,
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _runFilter('');
                          },
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                    ? ListView.builder(
                        scrollCacheExtent: const ScrollCacheExtent.pixels(1500.0),
                        itemCount: _foundFoodItems.length,
                        itemBuilder: (context, index) =>
                            _buildFoodListItem(_foundFoodItems[index]),
                      )
                    : Center(
                        child: Text(
                          _searchInitialText,
                          style: textTheme.titleMedium,
                        ),
                      ),
          ),
          if (_foundFoodItems.any((item) => item.source == FoodItemSource.off))
            const OffAttributionWidget(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteFoodItems.isEmpty) {
      return Center(
        child: Text(
          l10n.favoritesEmptyState,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollCacheExtent: const ScrollCacheExtent.pixels(1500.0),
            padding: DesignConstants.cardPadding,
            itemCount: _favoriteFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_favoriteFoodItems[index]),
          ),
        ),
        if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
      ],
    );
  }

  // FIX 5: _buildFoodListItem now uses SummaryCard.
  Widget _buildFoodListItem(FoodItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    IconData sourceIcon;
    switch (item.source) {
      case FoodItemSource.base:
        sourceIcon = LucideIcons.star;
        break;
      case FoodItemSource.off:
      case FoodItemSource.user:
        sourceIcon = LucideIcons.archive;
        break;
    }

    return SummaryCard(
      // FIX: Now uses SummaryCard.
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        title: Text(
          item.name.isNotEmpty ? item.name : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              l10n.foodItemSubtitle('', item.calories).replaceFirst(RegExp(r'^.*?-\s*'), ''),
            ),
            if (item.brand.isNotEmpty &&
                item.brand != 'Keine Marke' &&
                item.brand != l10n.noBrand) ...[
              const Text(' • '),
              Expanded(
                child: Text(
                  item.brand,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            LucideIcons.circle_plus,
            color: colorScheme.primary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () => Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => FoodDetailScreen(foodItem: item),
          ),
        )
            .then((_) {
          _loadFavorites();
        }),
      ),
    );
  }
}

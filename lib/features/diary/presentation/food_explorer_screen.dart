// lib/screens/food_explorer_screen.dart (Final & De-Materialisiert)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/sources/product_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_item.dart';
import 'create_food_screen.dart';
import 'food_detail_screen.dart';
import 'scanner_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/card_morph_route.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/summary_card.dart'; // Added
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../services/telemetry/telemetry_service.dart';

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
  bool _isFabHidden = false;

  Future<void> _checkDbStatus() async {
    final initialized =
        await BasisDataManager.instance.isOffDatabaseInitialized();
    if (mounted) {
      setState(() {
        _isOffDbInitialized = initialized;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.foodExplorer));
    _tabController = TabController(length: 2, vsync: this);
    _checkDbStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(
        context,
      );
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

  void _navigateAndCreateFood({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  }) {
    Navigator.of(context)
        .push(
      CardMorphRoute(
        sourceContext: sourceContext,
        sourceBorderRadius: 28.0,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) => const CreateFoodScreen(),
      ),
    )
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
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingL,
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
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: DesignConstants.bottomVignetteHeight,
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
                    label: l10n.createFoodScreenTitle,
                    onPressed: onPressed ?? () {},
                  );

              return GlassFab(
                label: l10n.createFoodScreenTitle,
                onPressed: () {
                  _navigateAndCreateFood(
                    sourceContext: fabCtx,
                    sourceBuilder: (_) => buildFab(),
                    onSourceVisibilityChanged: (hidden) {
                      if (mounted) setState(() => _isFabHidden = hidden);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Compact barcode entry point next to the search field.
  Widget _buildBarcodeButton(AppLocalizations l10n) {
    return Tooltip(
      message: l10n.scann_barcode_capslock,
      child: GestureDetector(
        onTap: _scanBarcodeAndOpenDetail,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFC9EF00),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            LucideIcons.scan_barcode,
            color: Color(0xFF12120F),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Opens the barcode scanner and shows the matching product's detail screen.
  Future<void> _scanBarcodeAndOpenDetail() async {
    final l10n = AppLocalizations.of(context)!;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    final foodItem =
        await ProductLocalDataSource.instance.getProductByBarcode(barcode);
    if (!mounted) return;

    if (foodItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarBarcodeNotFound(barcode))),
      );
      return;
    }

    unawaited(TelemetryService.instance
        .trackFeatureUsed(featureKey: FeatureKey.barcodeScanned));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodDetailScreen(foodItem: foodItem),
      ),
    );
    if (mounted) _loadFavorites();
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    if (!_isOffDbInitialized) {
      return DatabasePlaceholderWidget(
        title: l10n.offDownloadTitle,
        body: l10n.offPlaceholderText,
        icon: LucideIcons.database,
        onDownloadPressed: () async {
          await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(
            context,
          );
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
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
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
                                tooltip: l10n.clearSearch,
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
              ),
              const SizedBox(width: 8),
              _buildBarcodeButton(l10n),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: (_isLoadingSearch && _foundFoodItems.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96.0),
                        scrollCacheExtent:
                            const ScrollCacheExtent.pixels(1500.0),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              DesignConstants.cardPadding.left,
              DesignConstants.cardPadding.top,
              DesignConstants.cardPadding.right,
              96.0,
            ),
            scrollCacheExtent: const ScrollCacheExtent.pixels(1500.0),
            itemCount: _favoriteFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_favoriteFoodItems[index]),
          ),
        ),
      ],
    );
  }

  // FIX 5: _buildFoodListItem now uses SummaryCard.
  Widget _buildFoodListItem(FoodItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SummaryCard(
      // FIX: Now uses SummaryCard.
      child: ListTile(
        title: Text(
          item.name.isNotEmpty ? item.name : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              l10n
                  .foodItemSubtitle('', item.calories)
                  .replaceFirst(RegExp(r'^.*?-\s*'), ''),
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
          tooltip: l10n.add_button,
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

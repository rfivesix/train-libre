// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import '../../../widgets/common/seamless_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/sources/product_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_item.dart';
import 'food_detail_screen.dart';
import 'scanner_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/app_section_header.dart';
import 'widgets/off_attribution_widget.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/database_placeholder_widget.dart';

/// A lightweight, general-purpose food picker that returns a [FoodItem].
///
/// This screen is intentionally minimal and should be used in non-diary
/// contexts that only need to select an item.
class GeneralFoodSelectionScreen extends StatefulWidget {
  const GeneralFoodSelectionScreen({super.key});

  @override
  State<GeneralFoodSelectionScreen> createState() =>
      _GeneralFoodSelectionScreenState();
}

class _GeneralFoodSelectionScreenState
    extends State<GeneralFoodSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<FoodItem> _results = [];
  bool _isLoading = false;
  String _searchInitialText = '';
  List<Map<String, dynamic>> _baseCategories = [];
  final Map<String, List<FoodItem>> _catItems = {};
  final Set<String> _loadingCats = {};
  List<FoodItem> _customFoodItems = [];
  bool _isLoadingCustomFoods = false;

  bool _isOffDbInitialized = false;

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
    _checkDbStatus();
    _loadBaseCategories();
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCustomFoods = true;
    });
    final results = await ProductLocalDataSource.instance.getCustomFoods();
    if (mounted) {
      setState(() {
        _customFoodItems = results;
        _isLoadingCustomFoods = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_searchInitialText.isEmpty) {
      _searchInitialText = AppLocalizations.of(context)!.searchInitialHint;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runFilter(query);
    });
  }

  Future<void> _scanBarcodeAndPop() async {
    final l10n = AppLocalizations.of(context)!;
    final String? barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null && mounted) {
      final foodItem =
          await ProductLocalDataSource.instance.getProductByBarcode(
        barcode,
      );
      if (!mounted) return;

      if (foodItem != null) {
        Navigator.of(context).pop(foodItem);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarBarcodeNotFound(barcode))),
        );
      }
    }
  }

  Future<void> _runFilter(String enteredKeyword) async {
    final l10n = AppLocalizations.of(context)!;
    if (enteredKeyword.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchInitialText = l10n.searchInitialHint;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await ProductLocalDataSource.instance.searchProducts(
      enteredKeyword,
    );
    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
      if (results.isEmpty) {
        _searchInitialText = l10n.searchNoResults;
      }
    });
  }

  Future<void> _loadBaseCategories() async {
    _baseCategories = await ProductLocalDataSource.instance.getBaseCategories();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCategoryItems(String key) async {
    if (_catItems.containsKey(key) || _loadingCats.contains(key)) return;
    _loadingCats.add(key);
    if (mounted) setState(() {});
    final items = await ProductLocalDataSource.instance.getBaseFoods(
      categoryKey: key,
      limit: 500,
    );
    _catItems[key] = items;
    _loadingCats.remove(key);
    if (mounted) setState(() {});
  }

  Widget _buildFoodListItem(FoodItem item, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return SummaryCard(
      child: ListTile(
        title: Text(
          item.getLocalizedName(context).isNotEmpty
              ? item.getLocalizedName(context)
              : l10n.unknown,
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
          icon: Icon(LucideIcons.circle_plus, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(foodItem: item),
            ),
          );

          if (result is FoodItem && mounted) {
            Navigator.of(context).pop(result);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.addFoodTitle),
      body: !_isOffDbInitialized
          ? DatabasePlaceholderWidget(
              title: l10n.offDownloadTitle,
              body: l10n.offPlaceholderText,
              icon: LucideIcons.database,
              onDownloadPressed: () async {
                await BasisDataManager.instance
                    .promptOffDatabaseDownloadIfFirstTime(context);
                await _checkDbStatus();
              },
            )
          : Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _onSearchChanged(val);
                          },
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: l10n.searchHintText,
                            isDense: true,
                            prefixIcon: Icon(
                              LucideIcons.search,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (value.text.isNotEmpty) ...[
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      tooltip: l10n.clearSearch,
                                      icon: Icon(
                                        LucideIcons.x,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _runFilter('');
                                      },
                                    ),
                                  ),
                                ] else ...[
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      tooltip: l10n.scann_barcode_capslock,
                                      icon: Icon(
                                        LucideIcons.scan_barcode,
                                        color: colorScheme.primary,
                                        size: 26,
                                      ),
                                      onPressed: _scanBarcodeAndPop,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.spacingM,
                              vertical: DesignConstants.spacingM,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return value.text.trim().isEmpty
                            ? (_baseCategories.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ListView.builder(
                                    scrollCacheExtent:
                                        const ScrollCacheExtent.pixels(1500.0),
                                    itemCount: _baseCategories.length + 1,
                                    itemBuilder: (context, idx) {
                                      if (idx == 0) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                              dividerColor: Colors.transparent),
                                          child: ExpansionTile(
                                            leading: const Text(
                                              '🍳',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            title: Text(l10n.customFoodsTitle),
                                            initiallyExpanded: false,
                                            children: [
                                              if (_isLoadingCustomFoods)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: DesignConstants
                                                          .spacingM),
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                )
                                              else if (_customFoodItems.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: DesignConstants
                                                          .spacingM),
                                                  child: Center(
                                                      child: Text(
                                                          l10n.emptyCategory)),
                                                )
                                              else
                                                ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 16.0),
                                                  itemCount:
                                                      _customFoodItems.length,
                                                  itemBuilder: (context, i) =>
                                                      _buildFoodListItem(
                                                          _customFoodItems[i],
                                                          l10n),
                                                ),
                                            ],
                                          ),
                                        );
                                      }

                                      final cat = _baseCategories[idx - 1];
                                      final key = cat['key'] as String;
                                      final emoji =
                                          (cat['emoji'] as String?)?.trim();
                                      final locale = Localizations.localeOf(
                                        context,
                                      ).languageCode;
                                      final de =
                                          (cat['name_de'] as String?)?.trim();
                                      final en =
                                          (cat['name_en'] as String?)?.trim();
                                      final title = locale == 'de'
                                          ? (de?.isNotEmpty == true
                                              ? de!
                                              : (en?.isNotEmpty == true
                                                  ? en!
                                                  : key))
                                          : (en?.isNotEmpty == true
                                              ? en!
                                              : (de?.isNotEmpty == true
                                                  ? de!
                                                  : key));

                                      final loading =
                                          _loadingCats.contains(key);
                                      final items = _catItems[key];

                                      return Theme(
                                        data: Theme.of(
                                          context,
                                        ).copyWith(
                                            dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          leading: Text(
                                            emoji?.isNotEmpty == true
                                                ? emoji!
                                                : '🗂️',
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          title: Text(title),
                                          onExpansionChanged: (expanded) {
                                            if (expanded)
                                              _loadCategoryItems(key);
                                          },
                                          children: [
                                            if (loading)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      DesignConstants.spacingM,
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              )
                                            else if (items == null ||
                                                items.isEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical:
                                                      DesignConstants.spacingM,
                                                ),
                                                child: Center(
                                                  child:
                                                      Text(l10n.emptyCategory),
                                                ),
                                              )
                                            else
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                padding: const EdgeInsets.only(
                                                    bottom: 16.0),
                                                itemCount: items.length,
                                                itemBuilder: (_, i) =>
                                                    _buildFoodListItem(
                                                        items[i], l10n),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ))
                            : SeamlessLoadingOverlay(
                                isLoading: _isLoading,
                                isEmpty: _results.isEmpty,
                                fallback: Center(
                                  child: Text(
                                    _searchInitialText,
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                                child: () {
                                  final baseHits = _results
                                      .where((it) =>
                                          it.source == FoodItemSource.base)
                                      .toList();
                                  final offHits = _results
                                      .where((it) =>
                                          it.source == FoodItemSource.off)
                                      .toList();
                                  final customHits = _results
                                      .where((it) =>
                                          it.source == FoodItemSource.user)
                                      .toList();

                                  final listItems = <dynamic>[];
                                  if (customHits.isNotEmpty) {
                                    listItems.add(l10n.customFoodsTitle);
                                    listItems.addAll(customHits);
                                  }
                                  if (baseHits.isNotEmpty) {
                                    listItems.add(l10n.searchSectionBase);
                                    listItems.addAll(baseHits);
                                  }
                                  if (offHits.isNotEmpty) {
                                    listItems.add(l10n.searchSectionOther);
                                    listItems.addAll(offHits);
                                    listItems.add(const OffAttributionWidget());
                                  }

                                  return ListView.builder(
                                    scrollCacheExtent:
                                        const ScrollCacheExtent.pixels(1500.0),
                                    padding:
                                        const EdgeInsets.only(bottom: 56.0),
                                    itemCount: listItems.length,
                                    itemBuilder: (context, index) {
                                      final item = listItems[index];
                                      if (item is String) {
                                        return AppSectionHeader(title: item);
                                      } else if (item is FoodItem) {
                                        return _buildFoodListItem(item, l10n);
                                      } else if (item is Widget) {
                                        return item;
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  );
                                }());
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

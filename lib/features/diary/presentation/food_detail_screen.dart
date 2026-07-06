import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/sources/product_local_data_source.dart';
import 'create_food_screen.dart';
import '../../../config/app_data_sources.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_item.dart';
import '../../../services/catalog_file_migration.dart';
import '../domain/models/tracked_food_item.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'widgets/off_attribution_widget.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// Dev flag: keep disabled for production or remove dev-only sections entirely.
const bool kDevEditEnabled = false;

/// A detailed view for a [FoodItem], showing its full nutritional profile.
///
/// Supports toggling between 100g values and portion-based values if a portion
/// is provided via [trackedItem]. Includes favorite management and source attribution.
class FoodDetailScreen extends StatefulWidget {
  /// Optional tracked entry to show portion-specific values.
  final TrackedFoodItem? trackedItem;

  /// The food item to display if not provided by [trackedItem].
  final FoodItem? foodItem;

  /// When true, hides the "Add to diary" FAB for inspect-only navigation.
  final bool readOnly;

  const FoodDetailScreen({
    super.key,
    this.trackedItem,
    this.foodItem,
    this.readOnly = false,
  }) : assert(trackedItem != null || foodItem != null);

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  bool _isFavorite = false;
  bool _showPer100g = false;
  bool _isLoading = false;

  late FoodItem _displayItem;
  int? _trackedQuantity;
  bool get _hasPortionInfo => _trackedQuantity != null;

  /// True when the food item carries a declared serving size > 1g.
  /// Controls visibility of the portion ↔ 100g toggle across both diary
  /// and catalog contexts.
  bool get _hasPortionToggle =>
      _displayItem.productQuantity != null &&
      _displayItem.productQuantity! > 1.0;

  // ---------- DEV: Inline editing ----------
  bool _devEditing = false; // toggled via secret tap

  final _deCtrl = TextEditingController();
  final _enCtrl = TextEditingController();
  final _catCtrl = TextEditingController();

  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _kjCtrl = TextEditingController();
  final _fibCtrl = TextEditingController();
  final _sugCtrl = TextEditingController();
  final _saltCtrl = TextEditingController();
  final _sodCtrl = TextEditingController();
  final _calciumCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.trackedItem != null) {
      _displayItem = widget.trackedItem!.item;
      _trackedQuantity = widget.trackedItem!.entry.quantityInGrams;
      _showPer100g = false;
    } else {
      _displayItem = widget.foodItem!;
      _trackedQuantity = _displayItem.productQuantity?.round();
      _showPer100g = _trackedQuantity == null;
    }
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _deCtrl.dispose();
    _enCtrl.dispose();
    _catCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _kjCtrl.dispose();
    _fibCtrl.dispose();
    _sugCtrl.dispose();
    _saltCtrl.dispose();
    _sodCtrl.dispose();
    _calciumCtrl.dispose();
    super.dispose();
  }

  // ---------- DEV: Base DB helpers ----------

  Future<String> _getBaseDbPath() async {
    final supportDir = await getApplicationSupportDirectory();
    return CatalogFileMigration.resolveCanonicalPath(
      directoryPath: supportDir.path,
      canonicalFileName: AppDataSources.baseFoodsDbFileName,
      legacyFileName: AppDataSources.legacyBaseFoodsDbFileName,
    );
  }

  Future<Database> _openBaseDb({bool readOnly = false}) async {
    final path = await _getBaseDbPath();
    return openDatabase(path, readOnly: readOnly);
  }

  Future<void> _saveDevEdits() async {
    try {
      final barcode = _displayItem.barcode;
      final Map<String, Object?> fields = {
        // Keep name fields mirrored: `name` follows `name_de`.
        'name_de': _deCtrl.text.trim(),
        'name_en': _enCtrl.text.trim().isEmpty ? null : _enCtrl.text.trim(),
        'name': _deCtrl.text.trim(),
        'category_key': _catCtrl.text.trim().isEmpty
            ? null
            : _catCtrl.text.trim(),
        // Nutrients
        'calories_100g': int.tryParse(_calCtrl.text.trim()),
        'protein_100g': double.tryParse(_proCtrl.text.trim()),
        'carbs_100g': double.tryParse(_carbCtrl.text.trim()),
        'fat_100g': double.tryParse(_fatCtrl.text.trim()),
        'kj_100g': double.tryParse(_kjCtrl.text.trim()),
        'fiber_100g': double.tryParse(_fibCtrl.text.trim()),
        'sugar_100g': double.tryParse(_sugCtrl.text.trim()),
        'salt_100g': double.tryParse(_saltCtrl.text.trim()),
        'sodium_100g': double.tryParse(_sodCtrl.text.trim()),
        'calcium_100g': double.tryParse(_calciumCtrl.text.trim()),
      };

      // Normalize empty values to null; never overwrite the barcode.
      fields.removeWhere((k, v) => v == null);

      final db = await _openBaseDb();
      try {
        await db.update(
          'products',
          fields,
          where: 'barcode = ?',
          whereArgs: [barcode],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } finally {
        await db.close();
      }
      // await ProductLocalDataSource.instance.reloadBaseDb();

      // Reload the updated entry from the base DB so changes are visible immediately.
      final baseDb = await _openBaseDb(readOnly: true);
      Map<String, dynamic>? row;
      try {
        final rows = await baseDb.query(
          'products',
          where: 'barcode = ?',
          whereArgs: [barcode],
          limit: 1,
        );
        if (rows.isNotEmpty) row = rows.first;
      } finally {
        await baseDb.close();
      }
      if (row != null) {
        setState(() {
          _displayItem = FoodItem.fromMap(row!, source: FoodItemSource.base);
        });
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.foodDetailSavedBaseDb)));
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
    }
  }

  Future<void> _exportBaseDb() async {
    try {
      final path = await _getBaseDbPath();
      final file = XFile(path, name: p.basename(path));
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'Export: ${AppDataSources.baseFoodsDbFileName}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.foodDetailExportError(e))));
    }
  }

  // ---------- Favorites / display ----------

  Future<void> _checkIfFavorite() async {
    final isFav = await DatabaseHelper.instance.isFavorite(
      _displayItem.barcode,
    );
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await DatabaseHelper.instance.removeFavorite(_displayItem.barcode);
    } else {
      await DatabaseHelper.instance.addFavorite(_displayItem.barcode);
    }
    _checkIfFavorite();
  }

  double _getDisplayValue(double? valuePer100g) {
    if (valuePer100g == null) return 0.0;
    if (_showPer100g || !_hasPortionInfo) {
      return valuePer100g;
    }
    return (valuePer100g / 100 * _trackedQuantity!);
  }

  String _getCopyPrefix(String languageCode) {
    switch (languageCode) {
      case 'de':
        return 'Kopie von ';
      case 'fr':
        return 'Copie de ';
      case 'it':
        return 'Copia di ';
      case 'ja':
        return 'コピー：';
      case 'en':
      default:
        return 'Copy of ';
    }
  }

  Widget _buildSourceBadge(BuildContext context) {
    final theme = Theme.of(context);
    const color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
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

  Future<void> _showSystemEditMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.copySystemFoodTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingS,
              ),
              child: Text(
                l10n.copySystemFoodBody,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
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
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(l10n.createCopyAndEdit),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _duplicateAndEdit();
    }
  }

  Future<void> _duplicateAndEdit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final barcode = "user_created_${DateTime.now().millisecondsSinceEpoch}";
      final newId = const Uuid().v4();
      final duplicated = FoodItem(
        id: newId,
        barcode: barcode,
        name: _displayItem.name.isNotEmpty
            ? '${_getCopyPrefix('en')}${_displayItem.name}'
            : '',
        nameDe: _displayItem.nameDe.isNotEmpty
            ? '${_getCopyPrefix('de')}${_displayItem.nameDe}'
            : '',
        nameEn: _displayItem.nameEn.isNotEmpty
            ? '${_getCopyPrefix('en')}${_displayItem.nameEn}'
            : '',
        nameFr: _displayItem.nameFr.isNotEmpty
            ? '${_getCopyPrefix('fr')}${_displayItem.nameFr}'
            : '',
        nameIt: _displayItem.nameIt.isNotEmpty
            ? '${_getCopyPrefix('it')}${_displayItem.nameIt}'
            : '',
        nameJa: _displayItem.nameJa.isNotEmpty
            ? '${_getCopyPrefix('ja')}${_displayItem.nameJa}'
            : '',
        brand: _displayItem.brand,
        calories: _displayItem.calories,
        protein: _displayItem.protein,
        carbs: _displayItem.carbs,
        fat: _displayItem.fat,
        source: FoodItemSource.user,
        category: _displayItem.category,
        kj: _displayItem.kj,
        fiber: _displayItem.fiber,
        sugar: _displayItem.sugar,
        salt: _displayItem.salt,
        sodium: _displayItem.sodium,
        calcium: _displayItem.calcium,
        isLiquid: _displayItem.isLiquid,
        isFluid: _displayItem.isFluid,
        caffeineMgPer100ml: _displayItem.caffeineMgPer100ml,
        caffeineMgPer100g: _displayItem.caffeineMgPer100g,
        ingredientsText: _displayItem.ingredientsText,
        ingredientsAnalysisTags: _displayItem.ingredientsAnalysisTags != null
            ? List.from(_displayItem.ingredientsAnalysisTags!)
            : null,
        additivesTags: _displayItem.additivesTags != null
            ? List.from(_displayItem.additivesTags!)
            : null,
        productQuantity: _displayItem.productQuantity,
        productQuantityUnit: _displayItem.productQuantityUnit,
      );

      await ProductLocalDataSource.instance.insertProduct(duplicated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.foodCopyCreated(duplicated.getLocalizedName(context)),
          ),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreateFoodScreen(foodItemToEdit: duplicated),
        ),
      );
    } catch (e) {
      debugPrint("Error duplicating food: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${l10n.error}: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFoodItem() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.deleteFoodConfirmTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingS,
              ),
              child: Text(
                l10n.deleteFoodConfirmBody,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
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
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error,
                      foregroundColor: Theme.of(ctx).colorScheme.onError,
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ProductLocalDataSource.instance.deleteProduct(
          _displayItem.id ?? '',
          _displayItem.barcode,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.foodItemDeleted)));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Explicit top spacing avoids content colliding with status bar/app bar.
    final double topInset = MediaQuery.of(context).padding.top;
    final double totalTopPadding =
        topInset + kToolbarHeight + DesignConstants.cardPaddingInternal;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.readOnly
          ? null
          : GlassFab(
              onPressed: () {
                Navigator.of(context).pop(widget.foodItem);
              },
              label: l10n.mealsAddToDiary,
            ),
      appBar: GlobalAppBar(
        titleWidget: Row(
          children: [
            Expanded(
              child: Text(
                () {
                  final themeService = Provider.of<ThemeService>(context);
                  final baseFoodLang =
                      BaseFoodLanguageService.resolveLanguageCode(
                        choice: themeService.baseFoodLanguage,
                        context: context,
                      );
                  return _displayItem.source == FoodItemSource.base
                      ? _displayItem.getLocalizedName(
                          context,
                          languageCode: baseFoodLang,
                        )
                      : _displayItem.getLocalizedName(context);
                }(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_displayItem.isCustom) ...[
              const SizedBox(width: DesignConstants.spacingS),
              _buildSourceBadge(context),
            ],
          ],
        ),
        actions: [
          if (_displayItem.isCustom) ...[
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(LucideIcons.pencil),
              onPressed: () async {
                final result = await Navigator.of(context).push<FoodItem>(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateFoodScreen(foodItemToEdit: _displayItem),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _displayItem = result;
                  });
                }
              },
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(LucideIcons.trash_2),
              onPressed: _deleteFoodItem,
            ),
          ] else ...[
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(LucideIcons.pencil),
              onPressed: () => _showSystemEditMenu(context),
            ),
          ],
          IconButton(
            tooltip: l10n.tabFavorites,
            icon: Icon(
              LucideIcons.heart,
              color: _isFavorite
                  ? Theme.of(context).colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Use explicit padding instead of copyWith to avoid inherited edge bugs.
            padding: EdgeInsets.fromLTRB(
              DesignConstants.cardPaddingInternal,
              totalTopPadding,
              DesignConstants.cardPaddingInternal,
              DesignConstants.cardPaddingInternal +
                  80.0, // + space for the FAB at the bottom
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_displayItem.brand.isNotEmpty)
                  Text(_displayItem.brand, style: textTheme.bodySmall),
                // Dietary Badges
                if (_displayItem.ingredientsAnalysisTags != null &&
                    _displayItem.ingredientsAnalysisTags!.isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_displayItem.ingredientsAnalysisTags!.contains(
                        'en:vegan',
                      ))
                        _GlassBadge(label: l10n.vegan),
                      if (_displayItem.ingredientsAnalysisTags!.contains(
                            'en:vegetarian',
                          ) &&
                          !_displayItem.ingredientsAnalysisTags!.contains(
                            'en:vegan',
                          ))
                        _GlassBadge(label: l10n.vegetarian),
                    ],
                  ),
                ],
                // Keep vertical rhythm even when brand text is absent.
                Divider(
                  height: 32,
                  thickness: 1,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                ),
                // ── Compact nutrition heading + optional portion toggle ────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        (_showPer100g || !_hasPortionInfo)
                            ? l10n.nutritionPer100g
                            : l10n.nutritionPerPortion(
                                _trackedQuantity ??
                                    _displayItem.productQuantity?.round() ??
                                    100,
                              ),
                        style: textTheme.titleLarge,
                      ),
                    ),
                    if (_hasPortionToggle) ...[
                      const SizedBox(width: DesignConstants.spacingM),
                      _PortionToggleBar(
                        showPer100g: _showPer100g,
                        onChanged: (val) => setState(() => _showPer100g = val),
                        labelPortion: l10n.foodDetailSegmentPortion,
                        label100g: l10n.foodDetailSegment100g,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingS),
                SummaryCard(
                  child: Column(
                    children: [
                      _buildNutrientRow(
                        l10n.calories,
                        "${_getDisplayValue(_displayItem.calories.toDouble()).round()} kcal",
                      ),
                      _buildNutrientRow(
                        l10n.protein,
                        "${_getDisplayValue(_displayItem.protein).toStringAsFixed(1)} g",
                      ),
                      _buildNutrientRow(
                        l10n.carbs,
                        "${_getDisplayValue(_displayItem.carbs).toStringAsFixed(1)} g",
                      ),
                      _buildNutrientRow(
                        l10n.fat,
                        "${_getDisplayValue(_displayItem.fat).toStringAsFixed(1)} g",
                      ),
                    ],
                  ),
                ),
                if (_displayItem.sugar != null ||
                    _displayItem.fiber != null ||
                    _displayItem.salt != null ||
                    (_displayItem.caffeineMgPer100g ?? 0) > 0 ||
                    (_displayItem.caffeineMgPer100ml ?? 0) > 0) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  SummaryCard(
                    child: Column(
                      children: [
                        if (_displayItem.sugar != null)
                          _buildNutrientRow(
                            l10n.sugar,
                            "${_getDisplayValue(_displayItem.sugar).toStringAsFixed(1)} g",
                          ),
                        if (_displayItem.fiber != null)
                          _buildNutrientRow(
                            l10n.fiber,
                            "${_getDisplayValue(_displayItem.fiber).toStringAsFixed(1)} g",
                          ),
                        if (_displayItem.salt != null)
                          _buildNutrientRow(
                            l10n.salt,
                            "${_getDisplayValue(_displayItem.salt).toStringAsFixed(1)} g",
                          ),
                        if ((_displayItem.caffeineMgPer100g ?? 0) > 0 ||
                            (_displayItem.caffeineMgPer100ml ?? 0) > 0)
                          _buildNutrientRow(
                            l10n.caffeine,
                            "${_getDisplayValue(_displayItem.caffeineMgPer100g ?? _displayItem.caffeineMgPer100ml).round()} mg",
                          ),
                      ],
                    ),
                  ),
                ],
                if (_displayItem.ingredientsText != null &&
                    _displayItem.ingredientsText!.isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: SummaryCard(
                      child: ExpansionTile(
                        title: Text(l10n.ingredients),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(
                              DesignConstants.spacingL,
                            ),
                            child: Text(
                              _displayItem.ingredientsText!,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ---------- DEV: Inline edit panel ----------
                if (kDevEditEnabled && _devEditing) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignConstants.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEV: Eintrag bearbeiten',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                          _row('Name (DE)', _deCtrl),
                          const SizedBox(height: DesignConstants.spacingS),
                          _row('Name (EN)', _enCtrl),
                          const SizedBox(height: DesignConstants.spacingS),
                          _row('Kategorie-Key', _catCtrl),
                          const SizedBox(height: DesignConstants.spacingM),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _num('kcal/100g', _calCtrl),
                              _num('Protein/100g', _proCtrl),
                              _num('Carbs/100g', _carbCtrl),
                              _num('Fett/100g', _fatCtrl),
                              _num('kJ/100g', _kjCtrl),
                              _num('Ballastst./100g', _fibCtrl),
                              _num('Zucker/100g', _sugCtrl),
                              _num('Salz/100g', _saltCtrl),
                              _num('Natrium/100g', _sodCtrl),
                              _num('Calcium/100g', _calciumCtrl),
                            ],
                          ),
                          const SizedBox(height: DesignConstants.spacingM),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveDevEdits,
                                icon: const Icon(LucideIcons.save),
                                label: Text(l10n.save),
                              ),
                              const SizedBox(width: DesignConstants.spacingM),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _devEditing = false),
                                icon: const Icon(LucideIcons.x),
                                label: Text(l10n.doneButtonLabel),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: l10n.devExportBaseDb,
                                onPressed: _exportBaseDb,
                                icon: const Icon(LucideIcons.share),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!_displayItem.barcode.startsWith('user_created_'))
                  Padding(
                    padding: const EdgeInsets.only(
                      top: DesignConstants.spacingXL,
                      bottom: DesignConstants.spacingS,
                    ),
                    child: OffAttributionWidget(textStyle: textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.labelLarge),
    );
  }

  // ---------- DEV: small helper inputs ----------

  Widget _row(String label, TextEditingController c) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );

  Widget _num(String label, TextEditingController c) => SizedBox(
    width: 160,
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Portion toggle bar — compact segmented control
// ═══════════════════════════════════════════════════════════════════════════

/// A compact two-chip glass segmented control for toggling between
/// per-portion and per-100g nutrition views.
///
/// The shared track uses the same restrained rounded-card language as the
/// nutrition cards, while each [_PortionChip] handles its own tap gesture and
/// animated selected-state highlight.
class _PortionToggleBar extends StatelessWidget {
  final bool showPer100g;
  final ValueChanged<bool> onChanged;
  final String labelPortion;
  final String label100g;

  const _PortionToggleBar({
    required this.showPer100g,
    required this.onChanged,
    required this.labelPortion,
    required this.label100g,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: showPer100g,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.46)
              : cs.surfaceContainerHighest.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: isDark ? 0.14 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: cs.shadow.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PortionChip(
              label: labelPortion,
              selected: !showPer100g,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 2),
            _PortionChip(
              label: label100g,
              selected: showPer100g,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable chip inside [_PortionToggleBar].
///
/// Uses an [AnimatedContainer] to transition the selection highlight
/// (primary-tinted background + bold primary text) with a 180ms ease.
class _PortionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PortionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 58, minHeight: 30),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: isDark ? 0.34 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(
                  color: cs.primary.withValues(alpha: isDark ? 0.34 : 0.18),
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.88),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dietary Badge — Liquid Glass Aesthetic
// ═══════════════════════════════════════════════════════════════════════════
class _GlassBadge extends StatelessWidget {
  final String label;
  final bool isVegan; // Oder ein Enum für den Status

  const _GlassBadge({required this.label}) : isVegan = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Wir nutzen deine definierten App-Farben statt Hartcodierung
    final primaryBadgeColor = Colors.green;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: DesignConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        // Im Dark Mode helles Glas, im Light Mode dunkles Glas
        color: isDarkMode
            ? primaryBadgeColor.withValues(alpha: 0.15)
            : primaryBadgeColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
        border: Border.all(
          // Border erhält jetzt die Badge-Farbe mit etwas mehr Deckkraft
          color: primaryBadgeColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        //.toUpperCase(), // Optional: Sieht bei Badges oft professioneller aus
        style: theme.textTheme.labelSmall?.copyWith(
          color: isDarkMode ? primaryBadgeColor : primaryBadgeColor.shade800,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/meal_entry.dart';
import '../domain/repositories/diary_repository.dart';
import '../data/meal_photo_store.dart';
import '../domain/models/meal_capture_meta.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/ai_matching_language_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'general_food_selection_screen.dart';
import 'food_detail_screen.dart';
import 'meal_editor_screen.dart';
import 'widgets/meal_review_comparison_card.dart';
import 'widgets/meal_review_validation_summary.dart';
import 'widgets/meal_photo_widget.dart';
import '../../depth_scan/domain/models/depth_scale_facts.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../depth_scan/presentation/meal_scan_debug_view.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';
import 'dart:async';

/// Review screen for AI-suggested food items.
class AiMealReviewScreen extends StatefulWidget {
  final List<AiSuggestedItem> suggestions;
  final AiValidationResult? initialValidation;
  final List<File> originalImages;
  final DateTime? initialDate;
  final String? initialMealType;
  final DepthCaptureResult? depthResult;
  final DepthScaleFacts? depthFacts;
  final String? sentPrompt;
  final String? rawResponse;

  /// Dictated description that accompanied the capture, kept so a later
  /// re-analysis can send the same context again.
  final String? voiceTranscript;

  const AiMealReviewScreen({
    super.key,
    required this.suggestions,
    this.initialValidation,
    required this.originalImages,
    this.initialDate,
    this.initialMealType,
    this.depthResult,
    this.depthFacts,
    this.sentPrompt,
    this.rawResponse,
    this.voiceTranscript,
  });

  @override
  State<AiMealReviewScreen> createState() => _AiMealReviewScreenState();
}

class _AiMealReviewScreenState extends State<AiMealReviewScreen> {
  late List<_ReviewItem> _items;
  final _feedbackController = TextEditingController();
  bool _showFeedback = false;
  bool _isRetrying = false;
  bool _isSaving = false;
  bool _isMatching = true;
  bool _aiWaitingHapticActive = false;
  AiValidationResult? _validation;

  // Meal type selection
  late String _selectedMealType;
  late DateTime _selectedTimestamp;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiMealReview));
    _selectedMealType = widget.initialMealType ??
        MealTypeTimeExtension.fromCurrentTime().toMealTypeKey;
    _selectedTimestamp = (widget.initialDate ?? DateTime.now()).withCurrentTime;
    final initialValidation = widget.initialValidation;
    if (initialValidation != null) {
      _applyValidationResult(initialValidation);
      _isMatching = false;
    } else {
      _items =
          widget.suggestions.map((s) => _ReviewItem(suggestion: s)).toList();
      _validateCurrentItems();
    }
  }

  @override
  void dispose() {
    _stopAiWaitingHaptics();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startAiWaitingHaptics() {
    if (_aiWaitingHapticActive) return;
    _aiWaitingHapticActive = true;
    HapticFeedbackService.instance.startAiWaiting();
  }

  void _stopAiWaitingHaptics() {
    if (!_aiWaitingHapticActive) return;
    _aiWaitingHapticActive = false;
    HapticFeedbackService.instance.stopAiWaiting();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  void _updateItemNutritionLocally(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final food = item.matchedFood;
    if (food != null) {
      final factor = item.suggestion.estimatedGrams / 100.0;
      item.nutrition = AiNutritionTotals(
        kcal: food.calories * factor,
        protein: food.protein * factor,
        carbs: food.carbs * factor,
        fat: food.fat * factor,
      );
    }
  }

  Future<void> _validateCurrentItems({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading) {
      setState(() => _isMatching = true);
    }
    final candidate = _candidateFromReviewItems();
    final result = await AiMealValidationEngine().validateMealCandidate(
      candidate: candidate,
      mode: AiValidationMode.capture,
    );
    if (!mounted) return;
    setState(() {
      _applyValidationResult(result);
      _isMatching = false;
    });
  }

  AiMealCandidate _candidateFromReviewItems() {
    return AiMealCandidate(
      context: _validation?.candidate.context,
      items: _items
          .map(
            (item) => AiMealCandidateItem(
              name: item.suggestion.name,
              grams: item.suggestion.estimatedGrams,
              confidence: item.suggestion.confidence,
              matchedBarcode:
                  item.matchedFood?.barcode ?? item.suggestion.matchedBarcode,
            ),
          )
          .toList(growable: false),
    );
  }

  void _applyValidationResult(AiValidationResult result) {
    _validation = result;
    _items = result.items
        .map(
          (item) => _ReviewItem(
            suggestion: AiSuggestedItem(
              name: item.candidate.name,
              estimatedGrams: item.candidate.grams,
              confidence: item.candidate.confidence ?? 1.0,
              matchedBarcode: item.match.bestMatch?.barcode ??
                  item.candidate.matchedBarcode,
            ),
            matchedFood: item.match.bestMatch,
            issues: item.issues,
            nutrition: item.nutrition,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _validateCurrentItems(showLoading: false);
  }

  void _adjustQuantityBy(int index, int delta) {
    final item = _items[index];
    final newGrams = (item.suggestion.estimatedGrams + delta).clamp(10, 5000);
    if (newGrams != item.suggestion.estimatedGrams) {
      setState(() {
        item.suggestion.estimatedGrams = newGrams;
        _updateItemNutritionLocally(index);
      });
      _validateCurrentItems(showLoading: false);
    }
  }

  void _editQuantity(int index) async {
    final item = _items[index];
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: item.suggestion.estimatedGrams.toString(),
    );

    final result = await showGlassBottomMenu<int?>(
      context: context,
      title: item.suggestion.name,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.amount_in_grams,
                suffixText: l10n.unit_grams,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        close();
                        Navigator.of(ctx).pop(val);
                      }
                    },
                    label: l10n.save,
                    tooltip: l10n.save,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        item.suggestion.estimatedGrams = result;
        _updateItemNutritionLocally(index);
      });
      _validateCurrentItems(showLoading: false);
    }
  }

  Future<void> _replaceWithFood(int index) async {
    final selectedItem = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );
    if (selectedItem != null && mounted) {
      setState(() {
        _items[index].matchedFood = selectedItem;
        _items[index].suggestion.matchedBarcode = selectedItem.barcode;
        _items[index].suggestion.name = (() {
          final themeService =
              Provider.of<ThemeService>(context, listen: false);
          final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
            choice: themeService.baseFoodLanguage,
            context: context,
          );
          return selectedItem.source == FoodItemSource.base
              ? selectedItem.getLocalizedName(context,
                  languageCode: baseFoodLang)
              : selectedItem.getLocalizedName(context);
        })();
      });
      _validateCurrentItems(showLoading: false);
    }
  }

  Future<void> _addManualItem() async {
    final selectedItem = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );
    if (selectedItem != null && mounted) {
      setState(() {
        _items.add(
          _ReviewItem(
            suggestion: AiSuggestedItem(
              name: (() {
                final themeService =
                    Provider.of<ThemeService>(context, listen: false);
                final baseFoodLang =
                    BaseFoodLanguageService.resolveLanguageCode(
                  choice: themeService.baseFoodLanguage,
                  context: context,
                );
                return selectedItem.source == FoodItemSource.base
                    ? selectedItem.getLocalizedName(context,
                        languageCode: baseFoodLang)
                    : selectedItem.getLocalizedName(context);
              })(),
              estimatedGrams: 100,
              confidence: 1.0,
              matchedBarcode: selectedItem.barcode,
            ),
            matchedFood: selectedItem,
          ),
        );
      });
      _validateCurrentItems(showLoading: false);
      HapticFeedbackService.instance.confirmationFeedback();
    }
  }

  // ---------------------------------------------------------------------------
  // Retry
  // ---------------------------------------------------------------------------

  Future<void> _retryWithFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    setState(() => _isRetrying = true);
    _startAiWaitingHaptics();
    try {
      final matchingContext =
          await AiMatchingLanguageService.resolveMatchingContext(
        context: context,
      );
      if (!mounted) return;
      final candidate = await AiService.instance.retry(
        previousResults: _items.map((e) => e.suggestion).toList(),
        feedback: feedback,
        images: widget.originalImages.isNotEmpty ? widget.originalImages : null,
        matchingContext: matchingContext,
      );
      final orchestrator = AiRepairOrchestrator(
        validationEngine: AiMealValidationEngine(),
      );
      final outcome = await orchestrator.run(
        initialCandidate: candidate,
        mode: AiValidationMode.capture,
        repairer: (candidate, validation, attempt) {
          return AiService.instance.repairMealCaptureCandidate(
            candidate: candidate,
            validation: validation,
            images:
                widget.originalImages.isNotEmpty ? widget.originalImages : null,
            matchingContext: matchingContext,
            mealContext: candidate.context,
          );
        },
      );
      if (mounted) {
        setState(() {
          _applyValidationResult(outcome.validation);
          _feedbackController.clear();
          _showFeedback = false;
          _isMatching = false;
        });
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _stopAiWaitingHaptics();
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveToDiary() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSaving || _items.isEmpty) return;
    final validation = _validation ??
        await AiMealValidationEngine().validateMealCandidate(
          candidate: _candidateFromReviewItems(),
          mode: AiValidationMode.capture,
        );
    final savePlan = AiDiarySavePlan.fromValidation(validation);
    if (!savePlan.canSaveAny) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiValidationNoMatchedItemsSaveYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (savePlan.isPartial) {
      final confirmed = await _confirmPartialSave(savePlan);
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final db = DatabaseHelper.instance;
    final diaryRepo = context.read<IDiaryRepository>();
    var saved = false;

    try {
      final mealEntryId = const Uuid().v4();
      final candidateDish = _validation?.candidate.context?.dishType ??
          _validation?.candidate.mealName ??
          (_items.isNotEmpty ? _items.first.suggestion.name : 'Mahlzeit');

      // The captured file lives in a temporary directory the system may purge,
      // so it has to be copied into durable storage before its path is stored.
      MealPhotoPaths? photoPaths;
      final extraPhotoPaths = <String>[];
      for (var i = 0; i < widget.originalImages.length; i++) {
        final saved =
            await MealPhotoStore.instance.save(widget.originalImages[i]);
        if (saved == null) continue;
        if (photoPaths == null) {
          photoPaths = saved;
        } else {
          extraPhotoPaths.add(saved.photoPath);
        }
      }
      final captureMeta = MealCaptureMeta(
        depthFacts: widget.depthFacts,
        extraPhotoPaths: extraPhotoPaths,
      );

      final mealEntry = MealEntry(
        id: mealEntryId,
        title: candidateDish,
        consumedAt: _selectedTimestamp,
        mealType: _selectedMealType,
        photoPath: photoPaths?.photoPath,
        photoThumbPath: photoPaths?.thumbPath,
        voiceTranscript: widget.voiceTranscript,
        captureMeta: captureMeta.isEmpty ? null : captureMeta.toJson(),
        source: widget.originalImages.isEmpty ? 'aiText' : 'aiPhoto',
      );
      await diaryRepo.insertMealEntry(mealEntry);

      for (final item in savePlan.matchedItems) {
        final food = item.match.bestMatch!;

        final entry = FoodEntry(
          barcode: food.barcode,
          quantityInGrams: item.candidate.grams,
          timestamp: _selectedTimestamp,
          mealType: _selectedMealType,
          mealEntryId: mealEntryId,
        );
        await db.insertFoodEntry(entry,
            telemetrySource: FoodLogSource.aiCapture);
      }
      saved = true;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted || !saved) return;
    HapticFeedbackService.instance.confirmationFeedback();
    Navigator.of(context).pop(true);
  }

  Future<bool?> _confirmPartialSave(AiDiarySavePlan savePlan) {
    final l10n = AppLocalizations.of(context)!;
    return showGlassBottomMenu<bool>(
      context: context,
      title: l10n.aiValidationSomeItemsNeedReviewTitle,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiValidationPartialSaveItemsMessage(
              savePlan.unmatchedItems.length,
              savePlan.matchedItems.length,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(false);
                  },
                  label: AppLocalizations.of(context)!.cancel,
                  tooltip: AppLocalizations.of(context)!.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(true);
                  },
                  label: l10n.aiValidationSaveMatchedItemsButton,
                  tooltip: l10n.aiValidationSaveMatchedItemsButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Asks before throwing an unsaved analysis away.
  ///
  /// Leaving this screen returns all the way to where the capture started, so
  /// a stray back swipe would otherwise silently discard a finished analysis
  /// with no way to get it back.
  Future<bool> _confirmDiscard() async {
    if (_isSaving) return true;
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiReviewDiscardTitle),
        content: Text(l10n.aiReviewDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.discard,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          if (!context.mounted) return;
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(
          title: l10n.aiReviewTitle,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.sparkles, size: 20),
              tooltip: 'LiDAR & AI Insights',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealScanDebugView(
                      captureResult: widget.depthResult,
                      scaleFacts:
                          widget.depthFacts ?? widget.depthResult?.scaleFacts,
                      sentPrompt: widget.sentPrompt,
                      rawResponse: widget.rawResponse,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: DesignConstants.cardPadding.copyWith(
                  top: DesignConstants.cardPadding.top + topPadding,
                ),
                children: [
                  // The photo runs edge to edge; OverflowBox lets it escape the
                  // list's horizontal padding without restructuring the list.
                  if (widget.originalImages.isNotEmpty) ...[
                    SizedBox(
                      height: 300,
                      child: OverflowBox(
                        maxWidth: MediaQuery.sizeOf(context).width,
                        maxHeight: 300,
                        child: MealPhotoWidget(
                          photoFiles: widget.originalImages,
                          photoFile: widget.originalImages.first,
                          height: 300,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                  ],

                  // Header
                  Text(
                    l10n.aiReviewFoundItems(_items.length),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  if (_validation != null) ...[
                    MealReviewValidationSummary(
                      validation: _validation!,
                      itemsCount: _items.length,
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                  ],

                  // Meal type selector removed from here — relocated to bottom bar

                  // Items list
                  if (_isMatching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(DesignConstants.spacingXL),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return MealReviewComparisonCard(
                        dismissibleKey: ValueKey(item.hashCode),
                        name: item.suggestion.name,
                        estimatedGrams: item.suggestion.estimatedGrams,
                        confidence: item.suggestion.confidence,
                        matchedFood: item.matchedFood,
                        issues: item.issues,
                        nutrition: item.nutrition,
                        onDismissed: () => _removeItem(index),
                        onTap: item.matchedFood != null
                            ? () => _inspectFood(index)
                            : () => _replaceWithFood(index),
                        onReplace: () => _replaceWithFood(index),
                        onEditQuantity: () => _editQuantity(index),
                        onQuickAdjustQuantity: (delta) =>
                            _adjustQuantityBy(index, delta),
                      );
                    }),

                  // Add item button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesignConstants.spacingS),
                    child: AppButton.secondary(
                      onPressed: _addManualItem,
                      label: l10n.aiReviewAddItem,
                      tooltip: l10n.aiReviewAddItem,
                      icon: LucideIcons.plus,
                    ),
                  ),

                  // Feedback section
                  const SizedBox(height: DesignConstants.spacingM),
                  InkWell(
                    onTap: () => setState(() => _showFeedback = !_showFeedback),
                    child: Row(
                      children: [
                        Icon(
                          _showFeedback
                              ? LucideIcons.chevron_up
                              : LucideIcons.chevron_down,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        Text(
                          l10n.aiReviewFeedbackSection,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showFeedback) ...[
                    const SizedBox(height: DesignConstants.spacingS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildFeedbackChip(theme, 'Larger portions'),
                        _buildFeedbackChip(theme, 'Smaller portions'),
                        _buildFeedbackChip(theme, 'Separate ingredients'),
                        _buildFeedbackChip(theme, 'No sauce/dressing'),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.aiReviewFeedbackHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    AppButton.secondary(
                      onPressed: _isRetrying ? null : _retryWithFeedback,
                      label: l10n.aiReviewRetryButton,
                      tooltip: l10n.aiReviewRetryButton,
                    ),
                  ],

                  const SizedBox(height: 80), // Bottom padding for save button
                ],
              ),
            ),
            // Fixed bottom bar: meal-type selector + save button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Meal-type compact dropdown
                  Expanded(
                    flex: 2,
                    child: PlatformAdaptiveDropdownFormField<String>(
                      initialValue: _selectedMealType,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: DesignConstants.spacingS,
                        ),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'mealtypeBreakfast',
                          child: Text(
                            l10n.mealtypeBreakfast,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'mealtypeLunch',
                          child: Text(
                            l10n.mealtypeLunch,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'mealtypeDinner',
                          child: Text(
                            l10n.mealtypeDinner,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'mealtypeSnack',
                          child: Text(
                            l10n.mealtypeSnack,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedMealType = v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  // Save button
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: AppButton.primary(
                        onPressed:
                            (_items.isNotEmpty && !_isSaving && !_isMatching)
                                ? _saveToDiary
                                : null,
                        label: l10n.aiReviewSaveToDiary,
                        tooltip: l10n.aiReviewSaveToDiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackChip(ThemeData theme, String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        final current = _feedbackController.text.trim();
        if (current.isEmpty) {
          _feedbackController.text = text;
        } else if (!current.contains(text)) {
          _feedbackController.text = '$current, $text';
        }
      },
    );
  }

  /// Opens FoodDetailScreen in read-only mode to inspect the current match.
  void _inspectFood(int index) {
    final item = _items[index];
    if (item.matchedFood == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          foodItem: item.matchedFood,
          readOnly: true,
        ),
      ),
    );
  }
}

/// Internal wrapper around [AiSuggestedItem] that holds the matched food.
class _ReviewItem {
  AiSuggestedItem suggestion;
  FoodItem? matchedFood;
  List<AiValidationIssue> issues;
  AiNutritionTotals nutrition;

  _ReviewItem({
    required this.suggestion,
    this.matchedFood,
    this.issues = const [],
    this.nutrition = AiNutritionTotals.zero,
  });
}

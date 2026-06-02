import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../theme/color_constants.dart';
import '../../../nutrition_recommendation/data/recommendation_service.dart';

/// A premium, glassmorphic dismissible notification banner that alerts the user
/// when calculated adaptive targets deviate from active goals or are unacknowledged.
/// Features a dynamic delta display and immediate apply action.
class RecommendationBanner extends StatefulWidget {
  final int currentCalories;
  final AdaptiveNutritionRecommendationService? recommendationService;

  const RecommendationBanner({
    super.key,
    required this.currentCalories,
    this.recommendationService,
  });

  @override
  State<RecommendationBanner> createState() => _RecommendationBannerState();
}

class _RecommendationBannerState extends State<RecommendationBanner> with SingleTickerProviderStateMixin {
  late final AdaptiveNutritionRecommendationService _recommendationService;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  bool _isDismissed = false;
  bool _shouldShow = false;
  bool _isLoading = true;
  String? _recommendationKey;
  int _recommendedCalories = 0;

  @override
  void initState() {
    super.initState();
    _recommendationService = widget.recommendationService ?? AdaptiveNutritionRecommendationService();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _checkBannerStatus();
  }

  @override
  void didUpdateWidget(RecommendationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCalories != widget.currentCalories) {
      _checkBannerStatus();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkBannerStatus() async {
    try {
      // Load adaptive recommendation state
      final recState = await _recommendationService.loadState(refreshIfDue: false);
      final latestRec = recState.latestGeneratedRecommendation;
      final latestApplied = recState.latestAppliedRecommendation;

      if (latestRec == null) {
        if (mounted) {
          setState(() {
            _shouldShow = false;
            _isLoading = false;
          });
        }
        return;
      }

      final key = latestRec.dueWeekKey ?? latestRec.generatedAt.toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool('dismissed_tdee_banner_$key') ?? false;

      if (isDismissed) {
        if (mounted) {
          setState(() {
            _recommendationKey = key;
            _recommendedCalories = latestRec.recommendedCalories;
            _isDismissed = true;
            _isLoading = false;
          });
        }
        return;
      }

      final recommendedCalories = latestRec.recommendedCalories;
      final isUnacknowledged = latestApplied == null ||
          latestApplied.dueWeekKey != latestRec.dueWeekKey;

      final currentCaloriesMatch = widget.currentCalories == recommendedCalories;
      final shouldShow = !currentCaloriesMatch || isUnacknowledged;

      if (mounted) {
        setState(() {
          _recommendationKey = key;
          _recommendedCalories = recommendedCalories;
          _shouldShow = shouldShow;
          _isLoading = false;
        });
        if (shouldShow && !_isDismissed) {
          _fadeController.forward();
        }
      }
    } catch (e) {
      debugPrint('Error checking recommendation banner status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismissBanner() async {
    if (_recommendationKey == null) return;
    try {
      final key = 'dismissed_tdee_banner_$_recommendationKey';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
      
      if (mounted) {
        _fadeController.stop();
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isDismissed = true;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error dismissing recommendation banner: $e');
    }
  }

  Future<void> _applyRecommendation() async {
    try {
      final success = await _recommendationService.applyLatestRecommendationToActiveTargets();
      if (success && mounted) {
        _fadeController.stop();
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isDismissed = true;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error applying recommendation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_shouldShow || _isDismissed) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode;
    final accent = isDark ? brandAccentColor : brandAccentColorLightMode;

    // Calculate delta and format with prefix sign
    final delta = _recommendedCalories - widget.currentCalories;
    final deltaStr = delta > 0 ? '+$delta' : '$delta';

    return SizeTransition(
      sizeFactor: _fadeAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignConstants.cardPaddingExternal),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: accent,
                        size: DesignConstants.iconSizeL,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.recommendationBannerText(deltaStr),
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Interactive "Apply" Pill Button
                      Semantics(
                        label: 'Apply Recommendation',
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _applyRecommendation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              l10n.recommendationBannerApply,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'Dismiss Banner',
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _dismissBanner,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.close,
                              size: DesignConstants.iconSizeM,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

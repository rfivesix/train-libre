import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_color_choice.dart';
import 'haptic_feedback_service.dart';
import 'base_food_language_service.dart';

/// Service responsible for managing the application's theme and visual style.
///
/// Persists the user's preference for light/dark mode and visual presets.
class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _glassBlurKey = 'glass_blur';
  static const _glassOpacityKey = 'glass_opacity';
  static const _glassAppearanceKey = 'glass_appearance';
  static const _styleKey = 'visual_style';
  static const _aiEnabledKey = 'ai_enabled';
  static const _materialColorsEnabledKey = 'material_colors_enabled';
  static const _appColorChoiceKey = 'app_color_choice';
  static const _customAppColorKey = 'custom_app_color';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _showWorkoutE1rmKey = 'show_workout_e1rm';
  static const _useColorfulMacroBadgesKey = 'use_colorful_macro_badges';

  static const double defaultGlassAppearance = 0.3;

  double _glassAppearance = defaultGlassAppearance;
  bool _glassAppearanceDirty = false;

  /// 0 is clear, 1 is tinted; only the strongest settings add extra blur.
  double get glassAppearance => _glassAppearance;
  // The lightly blurred copy stays crisp through most of the range. Toward
  // the tinted end it softens gradually, in addition to the diffusion layer.
  static const defaultGlassBlur = 0.08;
  static const defaultGlassOpacity = 0.66;
  double get glassBlur {
    final upperRange = ((_glassAppearance - 0.7) / 0.3).clamp(0.0, 1.0);
    return defaultGlassBlur + 1.42 * upperRange * upperRange;
  }

  double get glassOpacity => 0.3 + 1.2 * _glassAppearance;

  ThemeMode _themeMode = ThemeMode.dark;
  int _visualStyle = 0; // 0 = Standard (Glas), 1 = Liquid
  bool _isAiEnabled = true;
  AppColorChoice _appColorChoice = AppColorChoice.trainLibre;
  Color _customAppColor = const Color(0xFF6750A4);
  bool _hapticsEnabled = true;
  bool _showWorkoutE1rm = false;
  bool _showWorkoutE1rmChanged = false;
  bool _useColorfulMacroBadges = true;
  BaseFoodLanguage _baseFoodLanguage = BaseFoodLanguage.auto;

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// The current visual style index.
  /// Hardcoded to 1 (Liquid Glass) since Standard Glass has been removed.
  int get visualStyle => 1;

  /// Whether AI features are enabled globally.
  bool get isAiEnabled => _isAiEnabled;

  /// The selected app accent color mode.
  AppColorChoice get appColorChoice => _appColorChoice;

  /// The user's custom accent seed color.
  Color get customAppColor => _customAppColor;

  /// Compatibility getter for the previous Android Material colors setting.
  bool get materialColorsEnabled => _appColorChoice == AppColorChoice.system;

  /// Whether haptic feedback is enabled globally.
  bool get hapticsEnabled => _hapticsEnabled;

  bool get showWorkoutE1rm => _showWorkoutE1rm;

  Future<void> setShowWorkoutE1rm(bool value) async {
    _showWorkoutE1rmChanged = true;
    _showWorkoutE1rm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWorkoutE1rmKey, value);
  }

  Future<void> _loadShowWorkoutE1rm() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_showWorkoutE1rmChanged) {
      _showWorkoutE1rm = prefs.getBool(_showWorkoutE1rmKey) ?? false;
      notifyListeners();
    }
  }

  /// Whether to use colorful macro badges in the diary.
  /// Hardcoded to always return true per requirements.
  bool get useColorfulMacroBadges => true;

  /// The user's preferred display language for base foods.
  BaseFoodLanguage get baseFoodLanguage => _baseFoodLanguage;

  /// Creates a [ThemeService] and loads saved preferences.
  ThemeService() {
    _loadGlassPreferences();
    _loadThemeMode();
    _loadVisualStyle();
    _loadAiEnabled();
    _loadAppColorSelection();
    _loadHapticsEnabled();
    _loadShowWorkoutE1rm();
    _loadUseColorfulMacroBadges();
    _loadBaseFoodLanguage();
  }

  Future<void> _loadGlassPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_glassAppearanceDirty) {
      final saved = prefs.getDouble(_glassAppearanceKey);
      if (saved != null) {
        _glassAppearance = saved.clamp(0.0, 1.0);
      } else if (prefs.containsKey(_glassBlurKey) ||
          prefs.containsKey(_glassOpacityKey)) {
        // Approximate the previous independent settings with one slider. Keep
        // their original values in storage so migration is non-destructive.
        final oldBlur = prefs.getDouble(_glassBlurKey) ?? 1.0;
        final oldOpacity = prefs.getDouble(_glassOpacityKey) ?? 1.0;
        _glassAppearance = ((oldBlur + oldOpacity) / 2 - 0.5).clamp(0.0, 1.0);
      } else {
        _glassAppearance = defaultGlassAppearance;
      }
    }
    notifyListeners();
  }

  Future<void> setGlassAppearance(double value) async {
    _glassAppearance = value.clamp(0.0, 1.0);
    _glassAppearanceDirty = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_glassAppearanceKey, _glassAppearance);
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _loadVisualStyle() async {
    final prefs = await SharedPreferences.getInstance();
    _visualStyle = prefs.getInt(_styleKey) ?? 0;
    notifyListeners();
  }

  /// Sets the visual style and persists it to storage.
  Future<void> setVisualStyle(int style) async {
    if (style == _visualStyle) return;
    _visualStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, style);
  }

  /// Sets the theme mode and persists it to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> _loadAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _isAiEnabled = prefs.getBool(_aiEnabledKey) ?? true;
    notifyListeners();
  }

  Future<void> _loadAppColorSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt(_customAppColorKey);
    if (savedColor != null) {
      _customAppColor = constrainCustomAppColor(Color(savedColor));
      if (_customAppColor.toARGB32() != savedColor) {
        await prefs.setInt(_customAppColorKey, _customAppColor.toARGB32());
      }
    }

    final savedChoice = prefs.getString(_appColorChoiceKey);
    final parsedChoice = AppColorChoice.values.where(
      (choice) => choice.name == savedChoice,
    );
    if (parsedChoice.isNotEmpty) {
      _appColorChoice = parsedChoice.first;
    } else if (prefs.getBool(_materialColorsEnabledKey) ?? false) {
      // Preserve users who had opted into Android Material You colors before
      // the color picker replaced the separate switch.
      _appColorChoice = AppColorChoice.system;
      await prefs.setString(_appColorChoiceKey, _appColorChoice.name);
    } else {
      _appColorChoice = AppColorChoice.trainLibre;
    }
    notifyListeners();
  }

  Future<void> _loadHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    HapticFeedbackService.instance.setEnabled(_hapticsEnabled);
    notifyListeners();
  }

  Future<void> _loadUseColorfulMacroBadges() async {
    final prefs = await SharedPreferences.getInstance();
    _useColorfulMacroBadges = prefs.getBool(_useColorfulMacroBadgesKey) ?? true;
    notifyListeners();
  }

  Future<void> _loadBaseFoodLanguage() async {
    _baseFoodLanguage = await BaseFoodLanguageService.readChoice();
    notifyListeners();
  }

  /// Sets whether AI features are enabled and persists it to storage.
  Future<void> setAiEnabled(bool enabled) async {
    if (enabled == _isAiEnabled) return;
    _isAiEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledKey, enabled);
  }

  /// Selects and persists the app accent color mode.
  Future<void> setAppColorChoice(AppColorChoice choice) async {
    if (choice == _appColorChoice) return;
    _appColorChoice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appColorChoiceKey, choice.name);
    await prefs.remove(_materialColorsEnabledKey);
  }

  /// Selects a custom accent color and persists it.
  Future<void> setCustomAppColor(Color color) async {
    _customAppColor = constrainCustomAppColor(Color(color.toARGB32()));
    _appColorChoice = AppColorChoice.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appColorChoiceKey, _appColorChoice.name);
    await prefs.setInt(_customAppColorKey, _customAppColor.toARGB32());
    await prefs.remove(_materialColorsEnabledKey);
  }

  /// Compatibility setter for callers using the former Material colors API.
  Future<void> setMaterialColorsEnabled(bool enabled) async {
    await setAppColorChoice(
      enabled ? AppColorChoice.system : AppColorChoice.trainLibre,
    );
  }

  /// Sets whether haptic feedback should be used across the app.
  Future<void> setHapticsEnabled(bool enabled) async {
    if (enabled == _hapticsEnabled) return;
    _hapticsEnabled = enabled;
    HapticFeedbackService.instance.setEnabled(enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, enabled);
  }

  /// Sets whether colorful macro badges should be used in the diary.
  Future<void> setUseColorfulMacroBadges(bool enabled) async {
    if (enabled == _useColorfulMacroBadges) return;
    _useColorfulMacroBadges = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useColorfulMacroBadgesKey, enabled);
  }

  /// Sets the base food display language and persists it to storage.
  Future<void> setBaseFoodLanguage(BaseFoodLanguage language) async {
    if (language == _baseFoodLanguage) return;
    _baseFoodLanguage = language;
    notifyListeners();
    await BaseFoodLanguageService.writeChoice(language);
  }
}

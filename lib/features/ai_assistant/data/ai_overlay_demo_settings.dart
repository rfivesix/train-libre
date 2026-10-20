import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AiOverlayDemoConfiguration {
  final bool enabled;
  final double liveliness;
  final bool showResizeHandles;
  final bool openDirectlyFullscreen;
  final bool useLiveAi;

  const AiOverlayDemoConfiguration({
    this.enabled = false,
    this.liveliness = 0.10,
    this.showResizeHandles = false,
    this.openDirectlyFullscreen = true,
    this.useLiveAi = false,
  });

  AiOverlayDemoConfiguration copyWith({
    bool? enabled,
    double? liveliness,
    bool? showResizeHandles,
    bool? openDirectlyFullscreen,
    bool? useLiveAi,
  }) =>
      AiOverlayDemoConfiguration(
        enabled: enabled ?? this.enabled,
        liveliness: liveliness ?? this.liveliness,
        showResizeHandles: showResizeHandles ?? this.showResizeHandles,
        openDirectlyFullscreen:
            openDirectlyFullscreen ?? this.openDirectlyFullscreen,
        useLiveAi: useLiveAi ?? this.useLiveAi,
      );
}

/// Local settings for showing and configuring the in-memory AI overlay demo.
/// Only preferences are persisted; overlay conversations remain transient.
class AiOverlayDemoSettings {
  AiOverlayDemoSettings._();

  static const _enabledKey = 'ai_overlay_demo_enabled';
  static const _livelinessKey = 'ai_overlay_demo_liveliness';
  static const _resizeHandlesKey = 'ai_overlay_demo_resize_handles';
  static const _fullscreenKey = 'ai_overlay_demo_direct_fullscreen';
  static const _liveAiKey = 'ai_overlay_demo_live_ai';

  static final ValueNotifier<AiOverlayDemoConfiguration> configuration =
      ValueNotifier<AiOverlayDemoConfiguration>(
    const AiOverlayDemoConfiguration(),
  );

  static void initialize(SharedPreferences preferences) {
    configuration.value = AiOverlayDemoConfiguration(
      enabled: preferences.getBool(_enabledKey) ?? false,
      liveliness: preferences.getDouble(_livelinessKey) ?? 0.10,
      showResizeHandles: preferences.getBool(_resizeHandlesKey) ?? false,
      openDirectlyFullscreen: preferences.getBool(_fullscreenKey) ?? true,
      useLiveAi: preferences.getBool(_liveAiKey) ?? false,
    );
  }

  static Future<void> update({
    bool? enabled,
    double? liveliness,
    bool? showResizeHandles,
    bool? openDirectlyFullscreen,
    bool? useLiveAi,
  }) async {
    final next = configuration.value.copyWith(
      enabled: enabled,
      liveliness: liveliness,
      showResizeHandles: showResizeHandles,
      openDirectlyFullscreen: openDirectlyFullscreen,
      useLiveAi: useLiveAi,
    );
    configuration.value = next;

    final preferences = await SharedPreferences.getInstance();
    if (enabled != null) await preferences.setBool(_enabledKey, next.enabled);
    if (liveliness != null) {
      await preferences.setDouble(_livelinessKey, next.liveliness);
    }
    if (showResizeHandles != null) {
      await preferences.setBool(_resizeHandlesKey, next.showResizeHandles);
    }
    if (openDirectlyFullscreen != null) {
      await preferences.setBool(_fullscreenKey, next.openDirectlyFullscreen);
    }
    if (useLiveAi != null) {
      await preferences.setBool(_liveAiKey, next.useLiveAi);
    }
  }
}

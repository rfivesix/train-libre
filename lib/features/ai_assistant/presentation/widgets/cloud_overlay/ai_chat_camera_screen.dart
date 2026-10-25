import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import '../../../../depth_scan/platform/depth_scan_channel.dart';
import 'header_glass_button.dart';

/// Presents the camera as a floating panel above the current app screen.
class AiChatCameraOverlay extends StatefulWidget {
  const AiChatCameraOverlay({
    super.key,
    required this.sourceRect,
    required this.onComplete,
  });

  final Rect? sourceRect;
  final ValueChanged<File?> onComplete;

  @override
  State<AiChatCameraOverlay> createState() => _AiChatCameraOverlayState();
}

class _AiChatCameraOverlayState extends State<AiChatCameraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 320),
  );
  bool _isClosing = false;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
  }

  Future<void> _finish(File? image) async {
    if (_isClosing) return;
    _isClosing = true;
    if (image == null) {
      // Stop capture as soon as any cancel path begins, while keeping the
      // preview mounted for the reverse animation.
      unawaited(DepthScanChannel.instance.stopSession());
    }
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      // Removing the overlay can cancel the reverse animation. Completion
      // still needs to release the caller waiting for the capture result.
    } finally {
      if (mounted && !_completionSent) {
        _completionSent = true;
        widget.onComplete(image);
      }
    }
  }

  void _finishFromBackdrop() {
    // Match the close button: animate the panel back to its source and stop the
    // native camera session while the reverse animation is running.
    unawaited(_finish(null));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final targetRect = Rect.fromLTRB(
      0,
      size.height * 0.38,
      size.width,
      size.height,
    );
    final origin = widget.sourceRect ??
        Rect.fromCenter(
          center: targetRect.center,
          width: 48,
          height: 48,
        );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_finish(null));
      },
      child: AnimatedBuilder(
        animation: curved,
        child: AiChatCameraScreen(
          onDismiss: () => _finish(null),
          onCaptured: (file) => _finish(file),
        ),
        builder: (context, child) {
          final progress = curved.value;
          final rect = Rect.lerp(origin, targetRect, progress)!;
          // iOS doesn't expose the device's physical corner radius to Flutter.
          // Scale the panel radius with the display width as a close
          // approximation of the hardware's rounded display corners.
          final displayCornerRadius =
              (size.width * 0.14).clamp(44.0, 60.0).toDouble();
          final radius = lerpDouble(24, displayCornerRadius, progress)!;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _isClosing,
                  child: GestureDetector(
                    onTap: () => _finishFromBackdrop(),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28 * progress),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  ignoring: _isClosing,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF202124),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.26),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact camera panel used by chat attachments.
class AiChatCameraScreen extends StatefulWidget {
  const AiChatCameraScreen({
    super.key,
    required this.onDismiss,
    required this.onCaptured,
  });

  final VoidCallback onDismiss;
  final ValueChanged<File> onCaptured;

  @override
  State<AiChatCameraScreen> createState() => _AiChatCameraScreenState();
}

class _AiChatCameraScreenState extends State<AiChatCameraScreen>
    with WidgetsBindingObserver {
  final _camera = DepthScanChannel.instance;
  bool _ready = false;
  bool _previewMounted = false;
  bool _debugGlassPreview = false;
  bool _busy = false;
  bool _optionsOpen = false;
  bool _torchOn = false;
  bool _usingFrontCamera = false;
  bool _starting = false;
  PermissionStatus? _permissionStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startCamera());
  }

  Future<void> _startCamera({bool requestPermission = true}) async {
    if (_starting || _ready) return;
    _starting = true;
    if (mounted) setState(() => _error = null);
    try {
      var permission = await Permission.camera.status;
      if (!permission.isGranted && requestPermission && permission.isDenied) {
        permission = await Permission.camera.request();
      }
      if (!mounted) return;
      _permissionStatus = permission;
      if (!permission.isGranted) {
        setState(() {
          _error = AppLocalizations.of(context)!.aiChatCameraPermission;
        });
        return;
      }
      final capability = await _camera.capability();
      if (!mounted) return;
      if (!capability.cameraAvailable) {
        _showCameraUnavailableOrGlassTest();
        return;
      }
      // Attach the native preview view to the widget tree before starting
      // AVFoundation. The session can then render its first frame immediately
      // instead of waiting for Flutter to create the platform view afterwards.
      setState(() => _previewMounted = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final started = await _camera.startChatCameraSession();
      if (!mounted) return;
      setState(() {
        _ready = started;
        _debugGlassPreview = !started && kDebugMode && Platform.isIOS;
        _previewMounted = started || _debugGlassPreview;
        _error = started || _debugGlassPreview
            ? null
            : AppLocalizations.of(context)!.aiChatCameraUnavailable;
      });
    } finally {
      _starting = false;
    }
  }

  void _showCameraUnavailableOrGlassTest() {
    if (kDebugMode && Platform.isIOS) {
      setState(() {
        _debugGlassPreview = true;
        _previewMounted = true;
        _error = null;
      });
      return;
    }
    setState(() {
      _error = AppLocalizations.of(context)!.aiChatCameraUnavailable;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _ready = false;
      unawaited(_camera.stopSession());
    } else if (state == AppLifecycleState.resumed && !_ready) {
      unawaited(_startCamera(requestPermission: false));
    }
  }

  Future<void> _capture() async {
    if (!_ready || _busy) return;
    setState(() => _busy = true);
    final result = await _camera.capturePhoto();
    if (!mounted) return;
    if (result == null || !await result.imageFile.exists()) {
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context)!.aiChatCameraUnavailable;
      });
      return;
    }
    await _camera.stopSession();
    if (mounted) widget.onCaptured(result.imageFile);
  }

  void _dismiss() {
    widget.onDismiss();
  }

  Future<void> _toggleFlash() async {
    if (!_ready || _usingFrontCamera) return;
    final value = await _camera.toggleTorch();
    if (mounted) setState(() => _torchOn = value);
  }

  Future<void> _switchCamera() async {
    if (!_ready || _busy) return;
    final switched = await _camera.switchCamera();
    if (!mounted) return;
    if (switched) {
      setState(() {
        _usingFrontCamera = !_usingFrontCamera;
        _torchOn = false;
      });
    } else {
      setState(
          () => _error = AppLocalizations.of(context)!.aiChatCameraUnavailable);
    }
  }

  @override
  void dispose() {
    unawaited(_camera.stopSession());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const shutterSize = 76.0;
    const sideButtonSize = 44.0;
    const controlSpacing = 12.0;
    const controlBottomInset = 16.0;
    const controlBaselineBottom = (shutterSize - sideButtonSize) / 2;
    const controlEdgeInset = controlBottomInset + controlBaselineBottom;
    const minimumPanelWidthForControls =
        controlEdgeInset * 2 + shutterSize + sideButtonSize * 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_previewMounted || _ready)
              UiKitView(
                key: ValueKey(
                  _debugGlassPreview
                      ? 'ai-chat-camera-glass-test'
                      : 'ai-chat-camera-preview',
                ),
                viewType: DepthScanChannel.previewViewType,
                creationParams: <String, Object>{
                  'glassTestPattern': _debugGlassPreview,
                },
                creationParamsCodec: const StandardMessageCodec(),
              )
            else
              const ColoredBox(color: Color(0xFF202124)),
            if (_debugGlassPreview &&
                constraints.maxWidth >= minimumPanelWidthForControls)
              const Center(
                child: Text(
                  'PLATFORM VIEW\nGLASS TEST',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            if (!_debugGlassPreview && !_ready)
              Center(
                child: _error == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              textScaler: const TextScaler.linear(1),
                              maxLines: 4,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_permissionStatus != null &&
                                !_permissionStatus!.isGranted &&
                                _error == l10n.aiChatCameraPermission) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed:
                                    _permissionStatus!.isPermanentlyDenied ||
                                            _permissionStatus!.isRestricted
                                        ? openAppSettings
                                        : () => _startCamera(),
                                icon: Icon(
                                  _permissionStatus!.isPermanentlyDenied ||
                                          _permissionStatus!.isRestricted
                                      ? Icons.settings_outlined
                                      : Icons.refresh,
                                ),
                                label: Text(
                                  _permissionStatus!.isPermanentlyDenied ||
                                          _permissionStatus!.isRestricted
                                      ? l10n.settingsTitle
                                      : l10n.retry,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            if (constraints.maxWidth >= minimumPanelWidthForControls)
              Positioned(
                left: controlEdgeInset,
                right: controlEdgeInset,
                bottom: controlBottomInset,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HeaderGlassButton(
                      tooltip: l10n.cancel,
                      icon: LucideIcons.chevron_left,
                      onPressed: _dismiss,
                      isDarkSurface: true,
                      platformViewBackdrop: true,
                      dimension: sideButtonSize,
                      iconSize: 20,
                    ),
                    GestureDetector(
                      key: const ValueKey('ai-chat-camera-shutter'),
                      onTap: _ready ? _capture : null,
                      child: Semantics(
                        button: true,
                        label: l10n.aiChatCapture,
                        child: SizedBox.square(
                          dimension: shutterSize,
                          child: GlassAdaptiveScope(
                            maxQuality: DesignConstants.defaultGlassQuality,
                            minQuality: DesignConstants.minGlassQuality,
                            child: AdaptiveGlass(
                              settings:
                                  DesignConstants.liquidGlassSettings(true),
                              quality: DesignConstants.defaultGlassQuality,
                              platformViewBackdrop: true,
                              useOwnLayer: true,
                              allowElevation: false,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 40,
                              ),
                              child: Center(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: sideButtonSize,
                      height: shutterSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (_optionsOpen) ...[
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: controlBaselineBottom +
                                  sideButtonSize +
                                  controlSpacing,
                              child: HeaderGlassButton(
                                tooltip: l10n.aiChatSwitchCamera,
                                icon: LucideIcons.switch_camera,
                                onPressed: _switchCamera,
                                isDarkSurface: true,
                                platformViewBackdrop: true,
                                dimension: sideButtonSize,
                                iconSize: 20,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: controlBaselineBottom +
                                  2 * (sideButtonSize + controlSpacing),
                              child: HeaderGlassButton(
                                tooltip: l10n.aiChatFlash,
                                icon: _torchOn
                                    ? LucideIcons.zap
                                    : LucideIcons.zap_off,
                                onPressed: _toggleFlash,
                                isDarkSurface: true,
                                backgroundColor: _torchOn
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : null,
                                foregroundColor: _usingFrontCamera
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.white,
                                platformViewBackdrop: true,
                                dimension: sideButtonSize,
                                iconSize: 20,
                              ),
                            ),
                          ],
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: controlBaselineBottom,
                            child: HeaderGlassButton(
                              tooltip: l10n.aiChatCameraOptions,
                              icon: _optionsOpen
                                  ? LucideIcons.x
                                  : LucideIcons.ellipsis,
                              onPressed: () => setState(
                                () => _optionsOpen = !_optionsOpen,
                              ),
                              isDarkSurface: true,
                              platformViewBackdrop: true,
                              dimension: sideButtonSize,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_busy)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        );
      },
    );
  }
}

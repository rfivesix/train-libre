// lib/screens/ai_meal_capture_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/app_localizations.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/ai_meal_scan_runner.dart';
import '../../../services/ai_meal_scan_log_service.dart';
import '../../../services/ai_service.dart';
import 'util/photo_pre_processor.dart';
import '../../../services/ai_matching_language_service.dart';
import '../../../services/ai_meal_context.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../depth_scan/data/depth_map_attachment.dart';
import '../../depth_scan/data/depth_scan_settings.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'ai_meal_review_reveal_route.dart';
import 'ai_meal_review_screen.dart';
import 'meal_analysis_morph_route.dart';
import 'meal_analysis_screen.dart';
import 'meal_editor_screen.dart';
import '../../settings/presentation/ai_settings_screen.dart';
import '../../../util/design_constants.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../data/sources/product_local_data_source.dart';
import '../domain/models/food_item.dart';
import 'dialogs/quantity_log_flow.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../services/telemetry/telemetry_buckets.dart';
import '../../../services/voice/voice_dictation_service.dart';
import '../../../services/voice/voice_dictation_settings.dart';
import '../../../services/ai_meal_capture_tour_service.dart';
import 'widgets/ai_meal_capture_tour_overlay.dart';
import '../../../util/permission_dialogs.dart';
import '../../ai_assistant/presentation/ai_global_cloud_visibility.dart';
import '../../ai_assistant/presentation/widgets/cloud_overlay/header_glass_button.dart';
import 'widgets/ai_neural_cloud_orb_widget.dart';
import 'widgets/animated_transcript_text.dart';

/// Screen for capturing meal input via live camera, photo(s), barcode or text (Screens A1–A6).
class AiMealCaptureScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialMealType;

  const AiMealCaptureScreen({
    super.key,
    this.initialDate,
    this.initialMealType,
  });

  @override
  State<AiMealCaptureScreen> createState() => _AiMealCaptureScreenState();
}

class _AiMealCaptureScreenState extends State<AiMealCaptureScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  static const double _scannerControlSideInset = 24;
  static const double _scannerPreviewTopInset = 12;
  static const double _scannerPreviewBottomInset = 18;

  late final AiGlobalCloudVisibilityLease _cloudVisibilityLease;
  final _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode(debugLabel: 'ai-meal-text-input');
  final ImagePicker _picker = ImagePicker();

  // Navigation & Lifecycle state
  bool _isRouteObserverAttached = false;
  bool _isTopRoute = true;
  bool _isCameraSuspended = false;

  // Camera & Barcode state
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR_Capture');
  QRViewController? _qrController;
  PermissionStatus _cameraPermission = PermissionStatus.denied;
  bool _isFlashOn = false;
  bool _isIosSimulator = false;
  String? _detectedBarcode;
  FoodItem? _detectedProduct;
  bool _isLoggingBarcode = false;

  /// Passive barcode detection. On by default — most packaged foods are logged
  /// this way — but switchable, because on a plated meal the constant chip is
  /// noise rather than help.
  bool _barcodeDetectionEnabled = true;
  bool _hasLidar = false;

  /// True once the unified native session (preview + barcodes + photo + depth)
  /// is available. Only then does the separate scanner camera stay out of the
  /// picture — two sessions cannot own the back camera at the same time.
  bool _useNativeSession = false;
  StreamSubscription<String>? _barcodeSubscription;

  /// Set when the last capture measured a distance outside the range LiDAR can
  /// be trusted at. Replaces the previous hard-coded distance pill.
  String? _distanceHint;

  // Voice dictation state
  bool _isDictating = false;
  bool _isVoiceStarting = false;
  bool _isVoiceStopping = false;
  bool _isVoiceDemo = false;
  bool _voiceHoldActivated = false;
  bool _voiceReleasedBeforeStart = false;
  bool _voicePermissionFlow = false;
  int? _voiceHoldPointer;
  Offset? _voiceHoldOrigin;
  Timer? _voiceHoldTimer;
  Timer? _voiceDemoTimer;
  double _voiceLevel = 0;
  String _voiceTranscript = '';
  String _voiceBaseText = '';
  bool _voiceTextWasVisible = false;
  final Stopwatch _voiceRecordingStopwatch = Stopwatch();
  bool _textCameFromVoice = false;

  // Photo state
  final List<File> _images = [];
  final Map<String, DepthCaptureResult> _depthCaptures = {};
  DepthCaptureResult? _lastDepthCapture;
  static const int _maxImages = 4;
  final PhotoPreProcessor _preProcessor = PhotoPreProcessor();

  // Analysis state
  bool _isAnalyzing = false;
  MealAnalysisController? _analysisController;
  Route<void>? _analysisRoute;
  bool _analysisCancelled = false;
  bool _aiWaitingHapticActive = false;
  bool _showTextInput = false;

  late AnimationController _analyzeButtonAnimationController;
  bool _isOffDbInitialized = false;

  // Interactive Tour State & Global Keys
  final GlobalKey _overlayKey = GlobalKey();
  final GlobalKey _keyShutter = GlobalKey();
  final GlobalKey _keyBarcode = GlobalKey();
  final GlobalKey _keyBarcodeBanner = GlobalKey();
  final GlobalKey _keyGallery = GlobalKey();
  final GlobalKey _keyVoice = GlobalKey();
  final GlobalKey _keyText = GlobalKey();
  final GlobalKey _keyAnalyze = GlobalKey();

  bool _isTourActive = false;
  int _tourStep = 0;
  List<Rect> _tourTargetRects = const [];

  @override
  void reassemble() {
    super.reassemble();
    if (_useNativeSession) return;
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      if (_isTopRoute && !_isCameraSuspended && !_isAnalyzing) {
        _qrController?.resumeCamera();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cloudVisibilityLease = AiGlobalCloudVisibility.suppress();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiMealCapture));
    WidgetsBinding.instance.addObserver(this);
    _checkDbStatus();
    unawaited(_prepareCamera());
    unawaited(AiService.instance.prewarm());

    _analyzeButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tourCompleted =
          await AiMealCaptureTourService.instance.isTourCompleted();
      if (!tourCompleted && mounted) {
        _startTour();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteObserverAttached && route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _isRouteObserverAttached = true;
    }
  }

  @override
  void didPush() {
    _isTopRoute = true;
  }

  @override
  void didPushNext() {
    _isTopRoute = false;
    unawaited(_suspendCamera());
  }

  @override
  void didPopNext() {
    _isTopRoute = true;
    if (!_isAnalyzing) {
      unawaited(_resumeCamera());
    }
  }

  @override
  void didPop() {
    _isTopRoute = false;
    unawaited(_suspendCamera());
  }

  @override
  void dispose() {
    _cloudVisibilityLease.dispose();
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _stopAiWaitingHaptics();
    _voiceHoldTimer?.cancel();
    _voiceDemoTimer?.cancel();
    _barcodeSubscription?.cancel();
    _analysisController?.dispose();
    unawaited(VoiceDictationService.instance.cancel());
    if (_useNativeSession) {
      unawaited(DepthScanChannel.instance.stopSession());
    }
    // The QR controller is not disposed here: it self-disposes when the
    // QRView is unmounted, and calling it again is deprecated.
    _preProcessor.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _analyzeButtonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_isTopRoute && !_isCameraSuspended && !_isAnalyzing) {
        unawaited(_resumeCamera());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_useNativeSession) {
        unawaited(DepthScanChannel.instance.stopSession());
      } else {
        unawaited(_qrController?.pauseCamera());
      }
    }
  }

  /// Suspends active camera preview and depth/barcode hardware.
  Future<void> _suspendCamera() async {
    _isCameraSuspended = true;
    if (_isFlashOn && mounted) {
      setState(() => _isFlashOn = false);
    }
    if (_useNativeSession) {
      await DepthScanChannel.instance.stopSession();
    } else {
      await _qrController?.pauseCamera();
    }
  }

  Future<void> _toggleFlash() async {
    if (!_cameraPermission.isGranted || _isCameraSuspended || _isAnalyzing) {
      return;
    }
    HapticFeedbackService.instance.selectionFeedback();
    if (_isIosSimulator && !_useNativeSession) {
      setState(() => _isFlashOn = !_isFlashOn);
      return;
    }
    if (_useNativeSession) {
      final isOn = await DepthScanChannel.instance.toggleTorch();
      if (mounted) {
        setState(() => _isFlashOn = isOn);
      }
    } else if (_qrController != null) {
      try {
        await _qrController?.toggleFlash();
        final status = await _qrController?.getFlashStatus();
        if (mounted) {
          setState(() => _isFlashOn = status ?? !_isFlashOn);
        }
      } catch (e) {
        debugPrint('[AiMealCapture] toggleFlash error: $e');
      }
    }
  }

  /// Resumes active camera preview and depth/barcode hardware if the screen is currently active.
  Future<void> _resumeCamera() async {
    _isCameraSuspended = false;
    if (!mounted ||
        !_cameraPermission.isGranted ||
        !_isTopRoute ||
        _isAnalyzing) {
      return;
    }
    if (_useNativeSession) {
      await DepthScanChannel.instance.startSession();
    } else {
      await _qrController?.resumeCamera();
    }
  }

  /// Permission first, session second — the native session cannot configure an
  /// input without camera access.
  Future<void> _prepareCamera() async {
    await _detectIosSimulator();
    await _checkPermission();
    if (!mounted || !_cameraPermission.isGranted) return;
    await _initCaptureSession();
  }

  Future<void> _detectIosSimulator() async {
    if (!Platform.isIOS) return;

    try {
      final info = await DeviceInfoPlugin().iosInfo;
      if (mounted) {
        setState(() => _isIosSimulator = !info.isPhysicalDevice);
      }
    } catch (_) {
      // If device detection fails, keep the real-camera path. The demo preview
      // must only be shown when the platform confirms this is an iOS simulator.
    }
  }

  Future<void> _checkDbStatus() async {
    final initialized =
        await BasisDataManager.instance.isOffDatabaseInitialized();
    if (mounted) {
      setState(() {
        _isOffDbInitialized = initialized;
      });
    }
  }

  /// Brings up the unified native session when the device has one, and only
  /// then subscribes to its barcode stream. Falls back silently to the scanner
  /// camera plus image picker everywhere else.
  Future<void> _initCaptureSession() async {
    final capability = await DepthScanChannel.instance.capability();
    if (!mounted) return;

    setState(() {
      _hasLidar = capability.depthSupported;
      _useNativeSession = capability.cameraAvailable;
    });

    if (!capability.cameraAvailable) return;
    if (_isCameraSuspended || !_isTopRoute || _isAnalyzing) {
      return;
    }

    final started = await DepthScanChannel.instance.startSession();
    if (!mounted) return;

    if (!started) {
      // Native session refused; the scanner camera path still works.
      setState(() => _useNativeSession = false);
      return;
    }

    _barcodeSubscription?.cancel();
    _barcodeSubscription =
        DepthScanChannel.instance.barcodes.listen(_onBarcodeDetected);
  }

  Future<void> _onBarcodeDetected(String code) async {
    if (!_barcodeDetectionEnabled) return;
    if (code.isEmpty || code == _detectedBarcode || !mounted) return;

    HapticFeedbackService.instance.confirmationFeedback();
    setState(() {
      _detectedBarcode = code;
      _detectedProduct = null;
    });

    try {
      final item =
          await ProductLocalDataSource.instance.getProductByBarcode(code);
      if (item != null && mounted && _detectedBarcode == code) {
        setState(() => _detectedProduct = item);
      }
    } catch (_) {}
  }

  /// Logs the product behind the recognised code straight from the viewfinder.
  ///
  /// This used to `pop` the raw barcode string, but both callers push this
  /// screen as a `Route<bool>` — the mismatched result blew up inside the
  /// navigator and left the app wedged with an unfinished pop. Logging here and
  /// returning the plain "something was saved" flag keeps the contract the
  /// callers already expect.
  Future<void> _logDetectedBarcode() async {
    final code = _detectedBarcode;
    if (code == null || _isLoggingBarcode) return;

    final l10n = AppLocalizations.of(context)!;
    final product = _detectedProduct ??
        await ProductLocalDataSource.instance.getProductByBarcode(code);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarBarcodeNotFound(code)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoggingBarcode = true);
    await _suspendCamera();
    if (!mounted) return;
    try {
      final logged = await logFoodItemWithQuantity(
        context,
        product,
        initialDate: widget.initialDate,
        initialMealType: widget.initialMealType ??
            MealTypeTimeExtension.fromCurrentTime().toMealTypeKey,
        telemetrySource: 'ai_meal_capture_barcode',
      );
      if (!mounted) return;
      if (logged) {
        unawaited(TelemetryService.instance
            .trackFeatureUsed(featureKey: FeatureKey.barcodeScanned));
        Navigator.of(context).pop(true);
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingBarcode = false);
        if (_isTopRoute && !_isAnalyzing) {
          unawaited(_resumeCamera());
        }
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraPermission = status;
        });
      }
    } else {
      final req = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _cameraPermission = req;
        });
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.getFlashStatus().then((status) {
      if (mounted && status != null) {
        setState(() => _isFlashOn = status);
      }
    }).catchError((_) {});
    controller.scannedDataStream.listen((scanData) async {
      final code = scanData.code;
      if (!_barcodeDetectionEnabled || !mounted) return;
      if (code != null && code != _detectedBarcode && code.isNotEmpty) {
        HapticFeedbackService.instance.confirmationFeedback();
        setState(() {
          _detectedBarcode = code;
          _detectedProduct = null;
        });

        // Lookup product name asynchronously in background
        try {
          final item =
              await ProductLocalDataSource.instance.getProductByBarcode(code);
          if (item != null && mounted && _detectedBarcode == code) {
            setState(() {
              _detectedProduct = item;
            });
          }
        } catch (_) {}
      }
    });
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

  String? _detectMealTypeFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('breakfast') || lower.contains('frühstück')) {
      return 'mealtypeBreakfast';
    }
    if (lower.contains('lunch') || lower.contains('mittag')) {
      return 'mealtypeLunch';
    }
    if (lower.contains('dinner') || lower.contains('abend')) {
      return 'mealtypeDinner';
    }
    if (lower.contains('snack') || lower.contains('zwischenmahlzeit')) {
      return 'mealtypeSnack';
    }
    return null;
  }

  /// A short, non-alarming note when the measurement fell outside the range
  /// LiDAR is dependable at. Null means everything was fine — the common case,
  /// which deliberately shows nothing at all.
  String? _distanceHintFor(AppLocalizations l10n, DepthCaptureResult result) {
    final facts = result.scaleFacts;
    if (facts == null) return null;
    if (facts.isValid) return null;
    if (facts.accuracy != 'absolute') return null;

    if (facts.subjectDistanceCm < 15) {
      return l10n.aiCaptureMoveAway;
    }
    if (facts.subjectDistanceCm > 120) {
      return l10n.aiCaptureMoveCloser;
    }
    return null;
  }

  Future<void> _takeShutterPhoto() async {
    if (_images.length >= _maxImages) return;

    HapticFeedbackService.instance.selectionFeedback();

    // The running session takes the photo — including on devices without
    // LiDAR, where it simply returns no depth map. Opening the system camera
    // on top of a live preview would be the wrong thing everywhere.
    if (_useNativeSession) {
      // One retry through a restart before giving up: the session is stopped on
      // every backgrounding, and a shutter tap that lost that race used to fall
      // straight through to the system camera — which is a photo with no depth
      // map, silently, for the rest of the session.
      var res = await DepthScanChannel.instance.capture();
      if (res == null) {
        final restarted = await DepthScanChannel.instance.startSession();
        if (!mounted) return;
        if (restarted) {
          res = await DepthScanChannel.instance.capture();
        }
      }

      if (res != null && mounted) {
        final capture = res;
        setState(() {
          _lastDepthCapture = capture;
          _depthCaptures[capture.imageFile.path] = capture;
          _images.add(capture.imageFile);
          _distanceHint =
              _distanceHintFor(AppLocalizations.of(context)!, capture);
        });
        if (capture.scaleFacts?.isValid == true ||
            capture.depthBuffer != null) {
          unawaited(TelemetryService.instance
              .trackFeatureUsed(featureKey: FeatureKey.lidarDepthCaptured));
        }
        _preProcessor.processImages([capture.imageFile]);
        return;
      }
      if (!mounted) return;
      debugPrint('[AiMealCapture] native capture unavailable, '
          'falling back to the system camera without depth');
    }

    // Fallback: Camera image picker
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (photo != null && mounted) {
      final file = File(photo.path);
      setState(() => _images.add(file));
      _preProcessor.processImages([file]);
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    await _suspendCamera();
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (picked.isNotEmpty && mounted) {
        final newFiles =
            picked.take(remaining).map((x) => File(x.path)).toList();
        setState(() {
          _images.addAll(newFiles);
        });
        _preProcessor.processImages(newFiles);
      }
    } finally {
      if (mounted && _isTopRoute && !_isAnalyzing) {
        unawaited(_resumeCamera());
      }
    }
  }

  void _removeImage(int index) {
    final file = _images[index];
    _depthCaptures.remove(file.path);
    _preProcessor.cancelAndRemove(file);
    setState(() => _images.removeAt(index));
  }

  bool get _hasInput =>
      _images.isNotEmpty || _textController.text.trim().isNotEmpty;

  /// Closes the blocking analysis screen if it is still up.
  void _dismissAnalysisScreen() {
    final route = _analysisRoute;
    _analysisRoute = null;
    if (route != null && route.isActive) {
      if (route.isCurrent) {
        route.navigator?.pop();
      } else {
        route.navigator?.removeRoute(route);
      }
    }
    _isTopRoute = true;
  }

  Future<void> _analyze() async {
    if (!_hasInput) return;
    // The text field can keep the system keyboard alive while the analysis
    // route is shown. Clear focus and hide keyboard before pushing it so it stays dismissed
    // when the scan screen closes.
    _textFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    if (_showTextInput) {
      setState(() => _showTextInput = false);
    }
    final stopwatch = Stopwatch()..start();
    final startedAt = DateTime.now();
    final requestId = const Uuid().v4();
    final scanLog = AiMealScanLogService.instance;
    final usageCollector = AiUsageCollector(onRequestCompleted: (report) {
      unawaited(scanLog.event(
          requestId, AiMealScanLogStage.providerUsageReported,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
          durationMilliseconds: report.durationMilliseconds,
          callIndex: report.requestIndex,
          inputTokens: report.usage?.inputTokens,
          outputTokens: report.usage?.outputTokens,
          totalTokens: report.usage?.totalTokens,
          usageComplete: report.usage?.isComplete ?? false));
    });
    var completionScheduled = false;
    var requestedSent = false;
    var provider = 'unknown';
    Completer<AiValidationResult>? pendingValidation;
    var reviewNavigated = false;
    int? reviewVisibleMilliseconds;
    int? preliminaryNutritionMilliseconds;
    int? revealDurationMilliseconds;
    final reviewVisibleCompleter = Completer<void>();
    void failPendingReview(Object error, StackTrace stackTrace) {
      final completer = pendingValidation;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }

    final text = _textController.text.trim();
    final hasImages = _images.isNotEmpty;
    final hasText = text.isNotEmpty;
    final hasVoice = hasText && _textCameFromVoice;
    final hasLidar = _depthCaptures.values.any((c) => c.depthBuffer != null);
    final inputMode = hasImages && hasText
        ? 'multimodal'
        : (hasImages ? 'photo' : 'text_only');
    unawaited(scanLog.start(
      id: requestId,
      provider: provider,
      inputMode: inputMode,
      photoCount: _images.length,
      startedAt: startedAt,
    ));
    unawaited(scanLog.event(requestId, AiMealScanLogStage.requested,
        elapsedMilliseconds: 0));
    void sendRequested() {
      if (requestedSent) return;
      requestedSent = true;
      unawaited(TelemetryService.instance.trackAiMealScanRequested(
        requestId: requestId,
        provider: provider,
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
    }

    var usageScheduled = false;
    void scheduleUsage() {
      if (usageScheduled || usageCollector.requestCount == 0) return;
      usageScheduled = true;
      unawaited(() async {
        await usageCollector.whenIdle;
        await scanLog.usage(requestId,
            calls: usageCollector.requestCount,
            inputTokens: usageCollector.inputTokens,
            outputTokens: usageCollector.outputTokens,
            totalTokens: usageCollector.totalTokens,
            complete: usageCollector.usageComplete);
        await TelemetryService.instance
            .track('ai_meal_scan_usage', properties: {
          'request_id': requestId,
          'provider': provider,
          'input_tokens': usageCollector.inputTokens,
          'output_tokens': usageCollector.outputTokens,
          'total_tokens': usageCollector.totalTokens,
          'usage_complete': usageCollector.usageComplete,
          'provider_calls_count': usageCollector.requestCount,
        });
      }());
    }

    setState(() => _isAnalyzing = true);
    _startAiWaitingHaptics();
    final cameraSuspended = _suspendCamera();

    // A blocking screen while the request is in flight: previously the capture
    // screen stayed editable underneath, so images could be added or removed
    // while they were already being analysed.
    final controller = MealAnalysisController();
    _analysisController?.dispose();
    _analysisController = controller;
    final sourceRect =
        MealAnalysisMorphRoute.measureRect(_keyAnalyze.currentContext);
    _analysisRoute = MealAnalysisScreen.route(
      controller: controller,
      sourceContext: _keyAnalyze.currentContext,
      sourceRect: sourceRect,
      previewImage: _images.isNotEmpty ? _images.first : null,
      onCancel: () {
        _analysisCancelled = true;
        if (!completionScheduled) {
          completionScheduled = true;
          stopwatch.stop();
          unawaited(scanLog.finish(requestId,
              result: AiMealScanLogResult.cancelled,
              durationMilliseconds: stopwatch.elapsedMilliseconds));
          sendRequested();
          scheduleUsage();
          unawaited(TelemetryService.instance.trackAiMealScanCompleted(
            requestId: requestId,
            provider: provider,
            durationSeconds: (stopwatch.elapsedMilliseconds / 1000).round(),
            success: false,
            errorCode: 'cancelled',
            inputMode: inputMode,
            photoCount: _images.length,
            hasLidar: hasLidar,
            hasVoiceInput: hasVoice,
            hasTextInput: hasText,
          ));
        }
        _stopAiWaitingHaptics();
        _dismissAnalysisScreen();
        if (mounted) {
          setState(() => _isAnalyzing = false);
          if (_isTopRoute) {
            unawaited(_resumeCamera());
          }
        }
      },
    );
    _analysisCancelled = false;
    if (mounted) unawaited(Navigator.of(context).push(_analysisRoute!));

    try {
      final selectedProvider = await AiService.instance.getSelectedProvider();
      provider = selectedProvider.name;
      unawaited(scanLog.setProvider(requestId, provider));
      unawaited(() async {
        try {
          final model =
              await AiService.instance.getSelectedModel(selectedProvider);
          await scanLog.setModel(requestId, model);
        } catch (_) {
          // Diagnostic metadata must not affect the scan.
        }
      }());
      sendRequested();
      if (!mounted || _analysisCancelled) return;
      final matchingContextFuture =
          AiMatchingLanguageService.resolveMatchingContext(context: context);
      final imagesReady = _images.isNotEmpty
          ? _preProcessor.waitForCompletion(_images)
          : Future<void>.value();
      final depthReady = () async {
        final enabled = await DepthScanSettings.instance.isDepthImageEnabled();
        return enabled && _lastDepthCapture != null
            ? buildDepthMapAttachment(_lastDepthCapture!)
            : null;
      }();
      await Future.wait([cameraSuspended, imagesReady]);
      final matchingContext = await matchingContextFuture;
      if (!mounted || _analysisCancelled) return;

      // Switchable so the same meal can be shot with and without the hint;
      // otherwise there is no way to tell whether the measurement helps.
      final scaleHintEnabled =
          await DepthScanSettings.instance.isScaleHintEnabled();
      final depthFacts =
          scaleHintEnabled ? _lastDepthCapture?.scaleFacts : null;

      // The relief of the meal, as a second image. Rendered here rather than kept
      // around: the band scale is fitted to the frame, so it only exists once the
      // capture it belongs to does.
      final depthMap = await depthReady;
      if (!mounted || _analysisCancelled) return;

      if (_analysisCancelled) return;
      controller.value = MealAnalysisPhase.analyzing;

      final preparationSeconds = (stopwatch.elapsedMilliseconds / 1000).round();
      final runBaseMilliseconds = stopwatch.elapsedMilliseconds;
      unawaited(scanLog.event(requestId, AiMealScanLogStage.preparationFinished,
          elapsedMilliseconds: runBaseMilliseconds,
          durationMilliseconds: runBaseMilliseconds));
      final fastMode = await AiService.instance.isFastModeEnabled();
      final nutritionMode = await AiService.instance.getMealNutritionMode();
      final useDirectNutrition =
          nutritionMode == AiMealNutritionMode.directEstimate;
      final cloudProvider = provider != 'ollama' && provider != 'custom';
      final engine = AiMealValidationEngine(
        matchLoader: useDirectNutrition
            ? (item) async =>
                item.selectedFood == null ? const [] : [item.selectedFood!]
            : null,
      );
      final validationCompleter = Completer<AiValidationResult>();
      pendingValidation = validationCompleter;
      // The route may not have built yet when a fast validation fails.
      unawaited(validationCompleter.future
          .then<void>((_) {}, onError: (Object _, StackTrace __) {}));
      final progressiveValidation = ValueNotifier<AiValidationResult?>(null);
      final savedCompleter = Completer<bool?>();
      int revealStartedMilliseconds = 0;

      Future<void> navigateToReview({
        required List<AiMealCandidateItem> items,
        AiValidationResult? validation,
        AiMealContext? mealContext,
      }) async {
        if (reviewNavigated || !mounted || _analysisCancelled) return;
        reviewNavigated = true;
        _stopAiWaitingHaptics();

        // Let the living cloud return to its calm circle, then hold that shape
        // briefly before the reveal route disperses it into vapor. The startup
        // initializer has its own contraction timing and does not use this path.
        await controller.contractToCircle();
        if (!mounted || _analysisCancelled) return;

        if (mounted) {
          setState(() => _isAnalyzing = false);
        }

        // Hide the orb and its UI beneath the review route after the contraction.
        controller.isFinished.value = true;

        final detectedType = _detectMealTypeFromText(text);
        final resolvedMealType = widget.initialMealType ??
            detectedType ??
            MealTypeTimeExtension.fromCurrentTime().toMealTypeKey;

        final reviewRoute = AiMealReviewRevealRoute<bool>(
          builder: (context) => AiMealReviewScreen(
            suggestions: items
                .map(
                  (item) => AiSuggestedItem(
                    name: item.name,
                    estimatedGrams: item.grams,
                    servedGrams: item.servedGrams,
                    confidence: item.confidence ?? 1.0,
                    matchedBarcode: item.matchedBarcode,
                    stateHint: item.stateHint,
                    catalogSearchTerm: item.catalogSearchTerm,
                    packagedProductEvidence: item.packagedProductEvidence,
                    searchTerms: item.searchTerms,
                    nutritionPer100g: item.nutritionPer100g,
                  ),
                )
                .toList(growable: false),
            initialValidation: validation,
            validationFuture:
                validation == null ? validationCompleter.future : null,
            progressiveValidation: progressiveValidation,
            mealContext: mealContext,
            originalImages: _images,
            initialDate: widget.initialDate,
            initialMealType: resolvedMealType,
            depthResult: _lastDepthCapture,
            depthResultsByPath: _depthCaptures,
            depthFacts: _lastDepthCapture?.scaleFacts,
            voiceTranscript: text.isNotEmpty ? text : null,
            scanRequestId: requestId,
            usageCollector: usageCollector,
            directNutritionMode: useDirectNutrition,
          ),
        );

        final oldAnalysisRoute = _analysisRoute;
        _analysisRoute = null;
        revealStartedMilliseconds = stopwatch.elapsedMilliseconds;
        final navFuture = Navigator.of(context).push<bool>(reviewRoute);
        // Navigator.push resolves when pop starts, but the transparent reveal
        // route still occupies the top of the stack during its reverse fade.
        // Wait for the transition to finish before letting this capture route
        // pop too; otherwise the two routes can overlap their removals and
        // leave the Diary visually exposed but unable to receive input.
        unawaited(() async {
          try {
            final result = await navFuture;
            await reviewRoute.completed;
            if (!savedCompleter.isCompleted) savedCompleter.complete(result);
          } catch (error, stackTrace) {
            if (!savedCompleter.isCompleted) {
              savedCompleter.completeError(error, stackTrace);
            }
          }
        }());
        if (oldAnalysisRoute != null && oldAnalysisRoute.isActive) {
          Navigator.of(context).removeRoute(oldAnalysisRoute);
        }
        completionScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final durationMilliseconds = stopwatch.elapsedMilliseconds;
          reviewVisibleMilliseconds = durationMilliseconds;
          revealDurationMilliseconds =
              durationMilliseconds - revealStartedMilliseconds;
          if (!reviewVisibleCompleter.isCompleted) {
            reviewVisibleCompleter.complete();
          }
          unawaited(scanLog.event(requestId, AiMealScanLogStage.reviewVisible,
              elapsedMilliseconds: durationMilliseconds));
        });
      }

      final runResult = await AiMealScanRunner(validationEngine: engine).run(
        fastMode: fastMode && cloudProvider,
        isCancelled: () => _analysisCancelled || !mounted,
        onCandidateReady: (candidate) {
          unawaited(navigateToReview(
            items: candidate.items,
            mealContext: candidate.context,
          ));
        },
        onValidationReady: (validation, _) {
          if (!reviewNavigated || !mounted) return;
          if (!validation.items.any((item) => item.match.bestMatch != null)) {
            return;
          }
          progressiveValidation.value = validation;
          if (preliminaryNutritionMilliseconds == null) {
            preliminaryNutritionMilliseconds = stopwatch.elapsedMilliseconds;
            unawaited(scanLog.event(
                requestId, AiMealScanLogStage.preliminaryNutritionReady,
                elapsedMilliseconds: preliminaryNutritionMilliseconds!));
          }
        },
        onValidating: () {
          if (!_analysisCancelled &&
              mounted &&
              controller.value != MealAnalysisPhase.repairing) {
            controller.value = MealAnalysisPhase.matching;
          }
        },
        onProgress: (stage, elapsedMilliseconds,
            {durationMilliseconds,
            result,
            round,
            candidate,
            validationScore,
            issueCategories}) {
          unawaited(scanLog.event(requestId, stage,
              elapsedMilliseconds: runBaseMilliseconds + elapsedMilliseconds,
              durationMilliseconds: durationMilliseconds,
              result: result,
              round: round,
              candidate: candidate,
              validationScore: validationScore,
              issueCategories: issueCategories));
        },
        analyze: () => useDirectNutrition
            ? (_images.isNotEmpty
                ? AiService.instance.analyzeDirectNutritionImages(
                    _images,
                    textHint: text.isNotEmpty ? text : null,
                    languageCode: matchingContext.appLanguage,
                    depthFacts: depthFacts,
                    depthMap: depthMap?.file,
                    depthMapLegend: depthMap?.describeForPrompt(),
                    usageCollector: usageCollector,
                  )
                : AiService.instance.analyzeDirectNutritionText(
                    text,
                    languageCode: matchingContext.appLanguage,
                    usageCollector: usageCollector,
                  ))
            : _images.isNotEmpty
                ? AiService.instance.analyzeImages(
                    _images,
                    textHint: text.isNotEmpty ? text : null,
                    matchingContext: matchingContext,
                    depthFacts: depthFacts,
                    depthMap: depthMap?.file,
                    depthMapLegend: depthMap?.describeForPrompt(),
                    usageCollector: usageCollector,
                  )
                : AiService.instance.analyzeText(
                    text,
                    matchingContext: matchingContext,
                    usageCollector: usageCollector,
                  ),
        repairer: (candidate, validation, attempt) {
          controller.value = MealAnalysisPhase.repairing;
          return useDirectNutrition
              ? AiService.instance.retryDirectNutrition(
                  previousItems: candidate.items,
                  feedback: validation.toRepairFeedback(),
                  images: _images.isNotEmpty ? _images : null,
                  languageCode: matchingContext.appLanguage,
                  usageCollector: usageCollector,
                )
              : AiService.instance.repairMealCaptureCandidate(
                  candidate: candidate,
                  validation: validation,
                  images: _images.isNotEmpty ? _images : null,
                  matchingContext: matchingContext,
                  mealContext: candidate.context,
                  usageCollector: usageCollector,
                );
        },
      );
      final validationOutcome = runResult.outcome;
      if (!validationCompleter.isCompleted) {
        validationCompleter.complete(validationOutcome.validation);
      }
      final readyMilliseconds = stopwatch.elapsedMilliseconds;
      unawaited(scanLog.event(requestId, AiMealScanLogStage.reviewReady,
          elapsedMilliseconds: readyMilliseconds));
      if (!reviewNavigated) {
        await navigateToReview(
          items: validationOutcome.validation.candidate.items,
          validation: validationOutcome.validation,
          mealContext: validationOutcome.validation.candidate.context,
        );
      }
      if (reviewNavigated) await reviewVisibleCompleter.future;

      if (!mounted) return;
      // The user walked away from the wait; their result is no longer wanted.
      if (_analysisCancelled) return;

      final itemCountBucket = TelemetryBuckets.getItemCountBucket(
          validationOutcome.validation.candidate.items.length);

      final durationSeconds = (readyMilliseconds / 1000).round();
      final durationMilliseconds = readyMilliseconds;
      final reviewVisibleSeconds = reviewVisibleMilliseconds == null
          ? null
          : (reviewVisibleMilliseconds! / 1000).round();
      final preliminaryNutritionSeconds =
          preliminaryNutritionMilliseconds == null
              ? null
              : (preliminaryNutritionMilliseconds! / 1000).round();
      final revealSeconds = revealDurationMilliseconds == null
          ? null
          : (revealDurationMilliseconds! / 1000).round();
      unawaited(() async {
        final firstPass = await runResult.primaryFirstPassAccepted;
        final categories = await runResult.primaryIssueCategories;
        final validationRuns = await runResult.validationRunsTotalCount;
        final providerSeconds = await runResult.providerSeconds;
        final validationSeconds = await runResult.validationSeconds;
        await scanLog.finish(requestId,
            result: validationOutcome.validation.passed
                ? AiMealScanLogResult.accepted
                : AiMealScanLogResult.needsRepair,
            durationMilliseconds: durationMilliseconds,
            selectedValidationRounds: validationOutcome.validationRunsCount,
            totalValidationRuns: validationRuns,
            repairRounds: validationOutcome.repairPassesUsed,
            primaryFirstPassAccepted: firstPass,
            hedgeStarted: runResult.hedgeStarted);
        await TelemetryService.instance.trackAiMealScanCompleted(
          requestId: requestId,
          provider: provider,
          durationSeconds: durationSeconds,
          reviewVisibleSeconds: reviewVisibleSeconds,
          preliminaryNutritionSeconds: preliminaryNutritionSeconds,
          success: true,
          inputMode: inputMode,
          photoCount: _images.length,
          hasLidar: hasLidar,
          hasVoiceInput: hasVoice,
          hasTextInput: hasText,
          validationPassed: validationOutcome.validation.passed,
          repairAttemptsCount: validationOutcome.repairPassesUsed,
          suggestedItemsCountBucket: itemCountBucket,
          preparationSeconds: preparationSeconds,
          providerSeconds: providerSeconds,
          validationSeconds: validationSeconds,
          repairSeconds: runResult.repairSeconds,
          revealSeconds: revealSeconds,
          primaryFirstPassAccepted: firstPass,
          selectedValidationRoundsCount: validationOutcome.validationRunsCount,
          validationRunsTotalCount: validationRuns,
          repairLimitReached: validationOutcome.repairLimitReached,
          firstPassIssueCategories: categories,
          fastMode: fastMode && cloudProvider,
          hedgeStarted: runResult.hedgeStarted,
        );
      }());

      final saved = await savedCompleter.future;
      // Leaving the review returns to wherever the capture was started from,
      // saved or not. Dropping back into the viewfinder after reviewing a meal
      // is never what the user meant by "back".
      if (mounted) {
        Navigator.of(context).pop(saved == true);
      }
    } on AiKeyMissingException catch (e, stackTrace) {
      failPendingReview(e, stackTrace);
      if (_analysisCancelled) return;
      stopwatch.stop();
      unawaited(scanLog.finish(requestId,
          result: AiMealScanLogResult.failed,
          durationMilliseconds: stopwatch.elapsedMilliseconds));
      completionScheduled = true;
      sendRequested();
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        durationSeconds: (stopwatch.elapsedMilliseconds / 1000).round(),
        reviewVisibleSeconds: reviewVisibleMilliseconds == null
            ? null
            : (reviewVisibleMilliseconds! / 1000).round(),
        preliminaryNutritionSeconds: preliminaryNutritionMilliseconds == null
            ? null
            : (preliminaryNutritionMilliseconds! / 1000).round(),
        success: false,
        errorCode: 'key_missing',
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
      _dismissAnalysisScreen();
      if (!mounted) return;
      if (!reviewNavigated) _showKeyMissingDialog();
    } on AiServiceException catch (e, stackTrace) {
      failPendingReview(e, stackTrace);
      if (_analysisCancelled) return;
      stopwatch.stop();
      unawaited(scanLog.finish(requestId,
          result: AiMealScanLogResult.failed,
          durationMilliseconds: stopwatch.elapsedMilliseconds));
      completionScheduled = true;
      sendRequested();
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        durationSeconds: (stopwatch.elapsedMilliseconds / 1000).round(),
        reviewVisibleSeconds: reviewVisibleMilliseconds == null
            ? null
            : (reviewVisibleMilliseconds! / 1000).round(),
        preliminaryNutritionSeconds: preliminaryNutritionMilliseconds == null
            ? null
            : (preliminaryNutritionMilliseconds! / 1000).round(),
        success: false,
        errorCode: aiServiceErrorCode(e),
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
      _dismissAnalysisScreen();
      if (!mounted) return;
      if (!reviewNavigated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AiMealCapture] Unexpected scan failure: $e');
      debugPrintStack(stackTrace: stackTrace);
      failPendingReview(e, stackTrace);
      if (_analysisCancelled) return;
      stopwatch.stop();
      unawaited(scanLog.finish(requestId,
          result: AiMealScanLogResult.failed,
          durationMilliseconds: stopwatch.elapsedMilliseconds));
      completionScheduled = true;
      sendRequested();
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        durationSeconds: (stopwatch.elapsedMilliseconds / 1000).round(),
        reviewVisibleSeconds: reviewVisibleMilliseconds == null
            ? null
            : (reviewVisibleMilliseconds! / 1000).round(),
        preliminaryNutritionSeconds: preliminaryNutritionMilliseconds == null
            ? null
            : (preliminaryNutritionMilliseconds! / 1000).round(),
        success: false,
        errorCode: 'unexpected',
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
      _dismissAnalysisScreen();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (!reviewNavigated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      sendRequested();
      scheduleUsage();
      if (!completionScheduled) {
        unawaited(TelemetryService.instance.trackAiMealScanCompleted(
          requestId: requestId,
          provider: provider,
          durationSeconds: (stopwatch.elapsedMilliseconds / 1000).round(),
          success: false,
          errorCode: 'cancelled',
          inputMode: inputMode,
        ));
      }
      _stopAiWaitingHaptics();
      _dismissAnalysisScreen();
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (!reviewNavigated && _textController.text.isNotEmpty) {
            _showTextInput = true;
          }
        });
        if (_isTopRoute) {
          unawaited(_resumeCamera());
        }
      }
    }
  }

  void _showKeyMissingDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await _suspendCamera();
    if (!mounted) return;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.aiValidationApiKeyRequiredTitle,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiErrorNoKey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => Navigator.of(ctx).pop(),
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AiSettingsScreen()),
                    );
                  },
                  label: l10n.aiSettingsTitle,
                  tooltip: l10n.aiSettingsTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (mounted && _isTopRoute && !_isAnalyzing) {
      unawaited(_resumeCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final primaryAccent = theme.colorScheme.primary;

    if (!_isOffDbInitialized) {
      return Scaffold(
        body: DatabasePlaceholderWidget(
          title: l10n.offDownloadTitle,
          body: l10n.offPlaceholderText,
          icon: LucideIcons.database,
          onDownloadPressed: () async {
            await BasisDataManager.instance
                .promptOffDatabaseDownloadIfFirstTime(context);
            await _checkDbStatus();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: GlobalAppBar(
        title: l10n.aiScannerTitle,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info, size: 20),
            tooltip: l10n.aiCaptureTourReplayTooltip,
            onPressed: _startTour,
          ),
          if (_hasLidar)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white30 : Colors.black26,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'LiDAR',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        key: _overlayKey,
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: Column(
              children: [
                // 1. The camera preview runs to the side edges; controls keep
                // their own inset from the display.
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: _scannerPreviewTopInset,
                            bottom: _scannerPreviewBottomInset,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (!_cameraPermission.isGranted)
                                  _buildCameraFallback()
                                else if (_isIosSimulator && !_useNativeSession)
                                  _buildSimulatorCameraDemo()
                                else if (_useNativeSession)
                                  const UiKitView(
                                    viewType: DepthScanChannel.previewViewType,
                                    creationParamsCodec: StandardMessageCodec(),
                                  )
                                else
                                  QRView(
                                    key: qrKey,
                                    onQRViewCreated: _onQRViewCreated,
                                    overlay: null,
                                  ),

                                // Distance guidance overlay if needed
                                if (_distanceHint != null)
                                  Positioned(
                                    top: 16,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.65),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: Colors.white24, width: 1),
                                        ),
                                        child: Text(
                                          _distanceHint!,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildScannerCameraActions(l10n),
                    ],
                  ),
                ),

                // 2. Bottom Controls Area (compact, pinned to bottom)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: AnimatedSize(
                    alignment: Alignment.bottomCenter,
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubic,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _scannerControlSideInset,
                          ),
                          child: _buildScannerBottomActions(l10n),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Captured Photos Strip
                              if (_images.isNotEmpty)
                                Container(
                                  height: 88,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: SizedBox.square(
                                                dimension: 80,
                                                child: Image.file(
                                                  _images[idx],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: -4,
                                            child: Semantics(
                                              button: true,
                                              label: l10n.aiChatRemoveImage,
                                              child: HeaderGlassButton(
                                                key: ValueKey(
                                                    'remove-meal-image-$idx'),
                                                icon: LucideIcons.x,
                                                iconSize: 12,
                                                dimension: 26,
                                                tooltip: l10n.aiChatRemoveImage,
                                                isDarkSurface: true,
                                                foregroundColor: Colors.white,
                                                platformViewBackdrop: true,
                                                onPressed: () =>
                                                    _removeImage(idx),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                              // Expandable Text Input Row
                              if (_showTextInput)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: DesignConstants.spacingS),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E1E1E)
                                          : const Color(0xFFE8E8E0),
                                      borderRadius: BorderRadius.circular(
                                          DesignConstants.borderRadiusL),
                                      border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.black12),
                                    ),
                                    padding: const EdgeInsets.only(
                                        left: DesignConstants.spacingL),
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _textFocusNode,
                                      onChanged: (_) {
                                        _textCameFromVoice = false;
                                        setState(() {});
                                      },
                                      minLines: 1,
                                      maxLines: 4,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF12120F)),
                                      decoration: InputDecoration(
                                        hintText: l10n.aiCaptureDescribeHint,
                                        hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45),
                                        filled: false,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical:
                                                    DesignConstants.spacingM),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        suffixIconConstraints:
                                            const BoxConstraints(
                                                minWidth: 44, minHeight: 44),
                                        suffixIcon: Align(
                                          alignment: Alignment.topCenter,
                                          widthFactor: 1,
                                          heightFactor: 1,
                                          child: IconButton(
                                            tooltip: l10n.doneButtonLabel,
                                            icon: Icon(LucideIcons.check,
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.8)
                                                    : Colors.black87,
                                                size: 18),
                                            onPressed: () {
                                              _textFocusNode.unfocus();
                                              FocusScope.of(context).unfocus();
                                              unawaited(SystemChannels.textInput
                                                  .invokeMethod<void>(
                                                      'TextInput.hide'));
                                              setState(
                                                  () => _showTextInput = false);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Passive Barcode Detection Banner (if detected or during tour step 1)
                              if (_isTourActive && _tourStep == 1)
                                _buildDemoBarcodeBanner(l10n, primaryAccent)
                              else if (_barcodeDetectionEnabled &&
                                  _detectedBarcode != null)
                                _buildBarcodeBanner(l10n, primaryAccent),

                              // "Analysieren" Button (Appears when input is ready or during tour step 5)
                              if (_hasInput ||
                                  (_isTourActive && _tourStep == 5)) ...[
                                const SizedBox(height: 8),
                                Opacity(
                                  opacity: _isAnalyzing ? 0.0 : 1.0,
                                  child: IgnorePointer(
                                    ignoring: _isAnalyzing,
                                    child: SizedBox(
                                      key: _keyAnalyze,
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryAccent,
                                          foregroundColor: isDark
                                              ? const Color(0xFF12120F)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed:
                                            _isAnalyzing ? null : _analyze,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(LucideIcons.sparkles,
                                                size: 18,
                                                color: isDark
                                                    ? const Color(0xFF12120F)
                                                    : Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              _images.isNotEmpty
                                                  ? l10n.aiCaptureAnalyzeMeal(
                                                      _images.length)
                                                  : l10n.aiCaptureAnalyzeText,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: isDark
                                                    ? const Color(0xFF12120F)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isTourActive)
            AiMealCaptureTourOverlay(
              targetRects: _tourTargetRects,
              title: _tourTitleForStep(_tourStep, l10n),
              description: _tourDescForStep(_tourStep, l10n),
              progressLabel: '${_tourStep + 1}/6',
              nextLabel: _tourStep == 5 ? l10n.appTourDone : l10n.appTourNext,
              skipLabel: l10n.appTourSkip,
              onNext: _nextTourStep,
              onSkip: _skipTour,
            ),
        ],
      ),
    );
  }

  void _startTour() {
    if (!mounted) return;
    final initialRects = _tourTargetRectsForStep(0);
    setState(() {
      _isTourActive = true;
      _tourStep = 0;
      _tourTargetRects = initialRects;
    });
    _showTourStep(0);
  }

  void _showTourStep(int step) {
    if (!mounted || !_isTourActive) return;
    HapticFeedbackService.instance.selectionFeedback();
    final targetRects = _tourTargetRectsForStep(step);
    setState(() {
      _tourStep = step;
      if (targetRects.isNotEmpty) {
        _tourTargetRects = targetRects;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTourActive || _tourStep != step) return;
      final updatedRects = _tourTargetRectsForStep(step);
      if (updatedRects.isNotEmpty) {
        setState(() => _tourTargetRects = updatedRects);
      }
    });
  }

  List<Rect> _tourTargetRectsForStep(int step) {
    final List<Rect> rects = [];
    final primaryKey = _keyForTourStep(step);
    final primaryRect = _rectForKey(primaryKey);
    if (primaryRect != null) {
      rects.add(primaryRect);
    }
    if (step == 1) {
      final bannerRect = _rectForKey(_keyBarcodeBanner);
      if (bannerRect != null) {
        rects.add(bannerRect);
      }
    }
    return rects;
  }

  GlobalKey? _keyForTourStep(int step) {
    switch (step) {
      case 0:
        return _keyShutter;
      case 1:
        return _keyBarcode;
      case 2:
        return _keyGallery;
      case 3:
        return _keyVoice;
      case 4:
        return _keyText;
      case 5:
        return (_hasInput || _isTourActive) ? _keyAnalyze : _keyShutter;
      default:
        return null;
    }
  }

  Rect? _rectForKey(GlobalKey? key) {
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final overlayBox =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return null;
    final localTopLeft =
        overlayBox.globalToLocal(renderBox.localToGlobal(Offset.zero));
    return localTopLeft & renderBox.size;
  }

  void _nextTourStep() {
    if (!mounted || !_isTourActive) return;
    if (_tourStep < 5) {
      _showTourStep(_tourStep + 1);
    } else {
      _completeTour();
    }
  }

  Future<void> _skipTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRects = const [];
    });
    await AiMealCaptureTourService.instance.markTourCompleted();
  }

  Future<void> _completeTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRects = const [];
    });
    await AiMealCaptureTourService.instance.markTourCompleted();
    HapticFeedbackService.instance.confirmationFeedback();
  }

  String _tourTitleForStep(int step, AppLocalizations l10n) {
    switch (step) {
      case 0:
        return l10n.aiCaptureTourStepShutterTitle;
      case 1:
        return l10n.aiCaptureTourStepBarcodeTitle;
      case 2:
        return l10n.aiCaptureTourStepGalleryTitle;
      case 3:
        return l10n.aiCaptureTourStepVoiceTitle;
      case 4:
        return l10n.aiCaptureTourStepTextTitle;
      case 5:
        return l10n.aiCaptureTourStepAnalyzeTitle;
      default:
        return '';
    }
  }

  String _tourDescForStep(int step, AppLocalizations l10n) {
    switch (step) {
      case 0:
        return l10n.aiCaptureTourStepShutterDesc;
      case 1:
        return l10n.aiCaptureTourStepBarcodeDesc;
      case 2:
        return l10n.aiCaptureTourStepGalleryDesc;
      case 3:
        return l10n.aiCaptureTourStepVoiceDesc;
      case 4:
        return l10n.aiCaptureTourStepTextDesc;
      case 5:
        return l10n.aiCaptureTourStepAnalyzeDesc;
      default:
        return '';
    }
  }

  Widget _buildDemoBarcodeBanner(AppLocalizations l10n, Color primaryAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Material(
        key: _keyBarcodeBanner,
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFE8),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryAccent.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryAccent.withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(LucideIcons.scan_barcode, color: primaryAccent, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.aiCaptureTourBarcodeDemoHint,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.4,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiCaptureTourBarcodeDemoProduct,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF12120F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.aiCaptureLogBarcode,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? const Color(0xFF12120F) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera_off, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Kamerazugriff erforderlich',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bitte erlaube den Kamerazugriff in den Einstellungen, um Mahlzeiten direkt live zu erfassen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: openAppSettings,
              child: Text(l10n.aiCaptureOpenSettings,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorCameraDemo() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.12),
              radius: 1.15,
              colors: [
                Color(0xFF78543B),
                Color(0xFF38291F),
                Color(0xFF171411),
              ],
              stops: [0, 0.58, 1],
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth;
                  Widget foodPiece({
                    required double left,
                    required double top,
                    required double width,
                    required double height,
                    required Color color,
                    double angle = 0,
                    double radius = 0.12,
                  }) {
                    return Positioned(
                      left: size * left,
                      top: size * top,
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: size * width,
                          height: size * height,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(size * radius),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(1, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE4D7C0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.38),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(size * 0.07),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0xFFFFFCF3), Color(0xFFF1E9D8)],
                            ),
                          ),
                        ),
                      ),
                      foodPiece(
                        left: 0.20,
                        top: 0.28,
                        width: 0.34,
                        height: 0.19,
                        color: const Color(0xFFB86A35),
                        angle: -0.38,
                      ),
                      foodPiece(
                        left: 0.47,
                        top: 0.22,
                        width: 0.30,
                        height: 0.16,
                        color: const Color(0xFF8E4C2D),
                        angle: 0.25,
                      ),
                      foodPiece(
                        left: 0.48,
                        top: 0.49,
                        width: 0.32,
                        height: 0.17,
                        color: const Color(0xFFCF8644),
                        angle: -0.2,
                      ),
                      foodPiece(
                        left: 0.22,
                        top: 0.57,
                        width: 0.29,
                        height: 0.16,
                        color: const Color(0xFF9A512C),
                        angle: 0.3,
                      ),
                      foodPiece(
                        left: 0.35,
                        top: 0.40,
                        width: 0.29,
                        height: 0.16,
                        color: const Color(0xFF678249),
                        angle: 0.15,
                      ),
                      foodPiece(
                        left: 0.25,
                        top: 0.43,
                        width: 0.16,
                        height: 0.11,
                        color: const Color(0xFFE8AE58),
                        angle: -0.6,
                      ),
                      foodPiece(
                        left: 0.61,
                        top: 0.39,
                        width: 0.15,
                        height: 0.11,
                        color: const Color(0xFF719352),
                        angle: 0.45,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeBanner(AppLocalizations l10n, Color primaryAccent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = _detectedProduct?.name ??
        l10n.aiCaptureBarcodeFallback(_detectedBarcode!);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFE8),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoggingBarcode ? null : _logDetectedBarcode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: primaryAccent.withValues(alpha: 0.8), width: 2),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.scan_barcode, color: primaryAccent, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.aiCaptureBarcodeDetected,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.4,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color:
                              isDark ? Colors.white : const Color(0xFF12120F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoggingBarcode
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color:
                                isDark ? const Color(0xFF12120F) : Colors.white,
                          ),
                        )
                      : Text(
                          l10n.aiCaptureLogBarcode,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color:
                                isDark ? const Color(0xFF12120F) : Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerBottomActions(AppLocalizations l10n) {
    return Row(
      children: [
        Opacity(
          opacity: _isDictating ? 0.42 : 1,
          child: _buildFrostedButton(
            key: _keyGallery,
            icon: LucideIcons.image,
            onTap: _isDictating ? null : _pickFromGallery,
            tooltip: l10n.aiCaptureTourStepGalleryTitle,
          ),
        ),
        Expanded(
          child: Center(
            child: _buildMealVoiceControl(l10n),
          ),
        ),
        Opacity(
          opacity: _isDictating ? 0.42 : 1,
          child: _buildFrostedButton(
            key: _keyText,
            icon: LucideIcons.pencil,
            isActive: _showTextInput || _textController.text.isNotEmpty,
            onTap: _isDictating ? null : _toggleTextInput,
            tooltip: l10n.aiCaptureTabText,
          ),
        ),
      ],
    );
  }

  Widget _buildMealVoiceControl(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final transcriptWidth = math
        .max(
          44.0,
          MediaQuery.sizeOf(context).width - 2 * _scannerControlSideInset,
        )
        .toDouble();
    final transcriptSideOffset = (transcriptWidth - 44) / 2;
    final accent = theme.colorScheme.primary;

    return Listener(
      key: _keyVoice,
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleVoicePointerDown,
      onPointerMove: _handleVoicePointerMove,
      onPointerUp: _handleVoicePointerUp,
      onPointerCancel: _handleVoicePointerCancel,
      child: Semantics(
        button: true,
        label: l10n.aiCaptureTourStepVoiceTitle,
        hint: l10n.voiceHoldToTalk,
        onTap: () => unawaited(
          _isDictating ? _finishMealVoiceInput() : _startMealVoiceInput(),
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: _isDictating ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                child: _buildFrostedButton(
                  icon: LucideIcons.mic,
                  isActive: _isDictating,
                  onTap: null,
                  tooltip: l10n.aiCaptureTourStepVoiceTitle,
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isDictating ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: SizedBox.square(
                    dimension: 56,
                    child: AiNeuralCloudOrbWidget(
                      size: 56,
                      morph: _isDictating ? 1 : 0,
                      energy: _voiceLevel,
                      accentColor: const Color(0xFFFF453A),
                      showDetachedSatellite: false,
                      tint: 0.24,
                      tintEnergyGain: 0.2,
                      flowSpeed: 0.55,
                      animate: true,
                      enableInteraction: false,
                    ),
                  ),
                ),
              ),
              if (_isDictating)
                Positioned(
                  left: -transcriptSideOffset,
                  width: transcriptWidth,
                  bottom: 56,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 56),
                          child: SingleChildScrollView(
                            child: AnimatedTranscriptText(
                              text: _voiceTranscript,
                              animateWords: false,
                              placeholder: _isVoiceStarting
                                  ? l10n.voiceStarting
                                  : (_images.isEmpty
                                      ? l10n.voiceExampleStandalone
                                      : l10n.voiceExampleWithPhoto),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 14,
                                height: 1.35,
                              ),
                              placeholderStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isVoiceStopping)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerCameraActions(AppLocalizations l10n) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _scannerControlSideInset,
            right: _scannerControlSideInset,
            bottom: 26,
            child: Row(
              children: [
                HeaderGlassButton(
                  key: _keyBarcode,
                  icon: LucideIcons.scan_barcode,
                  onPressed: () {
                    setState(() {
                      _barcodeDetectionEnabled = !_barcodeDetectionEnabled;
                      if (!_barcodeDetectionEnabled) {
                        _detectedBarcode = null;
                        _detectedProduct = null;
                      }
                    });
                  },
                  tooltip: l10n.aiCaptureTourStepBarcodeTitle,
                  isDarkSurface: true,
                  platformViewBackdrop: true,
                  foregroundColor: _barcodeDetectionEnabled
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.white,
                  backgroundColor: _barcodeDetectionEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: l10n.aiCaptureTourStepShutterTitle,
                      child: GestureDetector(
                        key: _keyShutter,
                        behavior: HitTestBehavior.opaque,
                        onTap: _takeShutterPhoto,
                        child: SizedBox.square(
                          dimension: 76,
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
                                        color: Colors.black
                                            .withValues(alpha: 0.22),
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
                  ),
                ),
                HeaderGlassButton(
                  icon: _isFlashOn ? LucideIcons.zap : LucideIcons.zap_off,
                  tooltip: l10n.aiChatFlash,
                  isDarkSurface: true,
                  platformViewBackdrop: true,
                  backgroundColor:
                      _isFlashOn ? Theme.of(context).colorScheme.primary : null,
                  foregroundColor: _isFlashOn
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.white,
                  onPressed: _cameraPermission.isGranted &&
                          !_isCameraSuspended &&
                          !_isAnalyzing
                      ? () => unawaited(_toggleFlash())
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTextInput() {
    final willShow = !_showTextInput;
    setState(() => _showTextInput = willShow);
    if (willShow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_showTextInput) return;
        _textFocusNode.requestFocus();
        unawaited(
            SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
      });
      return;
    }
    _textFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  Widget _buildFrostedButton({
    Key? key,
    required IconData icon,
    required VoidCallback? onTap,
    bool isActive = false,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final isDarkSurface = theme.brightness == Brightness.dark;
    return HeaderGlassButton(
      key: key,
      icon: icon,
      tooltip: tooltip ?? '',
      isDarkSurface: isDarkSurface,
      foregroundColor: isActive
          ? theme.colorScheme.onPrimary
          : isDarkSurface
              ? Colors.white
              : theme.colorScheme.onSurface,
      backgroundColor: isActive ? theme.colorScheme.primary : null,
      platformViewBackdrop: true,
      dimension: 44,
      onPressed: onTap,
    );
  }

  void _handleVoicePointerDown(PointerDownEvent event) {
    if (_voiceHoldPointer != null || _isDictating) return;
    _voiceHoldPointer = event.pointer;
    _voiceHoldOrigin = event.position;
    _voiceHoldActivated = false;
    _voiceReleasedBeforeStart = false;
    _voiceHoldTimer?.cancel();
    _voiceHoldTimer = Timer(const Duration(milliseconds: 360), () {
      if (!mounted || _voiceHoldPointer != event.pointer) return;
      _voiceHoldActivated = true;
      unawaited(_startMealVoiceInput());
    });
  }

  void _handleVoicePointerMove(PointerMoveEvent event) {
    if (event.pointer != _voiceHoldPointer || _voiceHoldActivated) return;
    final origin = _voiceHoldOrigin;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
      _voiceHoldTimer?.cancel();
      _voiceHoldPointer = null;
      _voiceHoldOrigin = null;
    }
  }

  void _handleVoicePointerUp(PointerUpEvent event) {
    if (event.pointer != _voiceHoldPointer) return;
    _voiceHoldTimer?.cancel();
    _voiceHoldPointer = null;
    _voiceHoldOrigin = null;
    if (!_voiceHoldActivated) return;
    if (_voicePermissionFlow || _isVoiceStarting || !_isDictating) {
      _voiceReleasedBeforeStart = true;
      return;
    }
    if (_isDictating) {
      unawaited(_finishMealVoiceInput());
    }
  }

  void _handleVoicePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _voiceHoldPointer) return;
    _voiceHoldTimer?.cancel();
    _voiceHoldPointer = null;
    _voiceHoldOrigin = null;
    if (!_voiceHoldActivated) return;
    if (_voicePermissionFlow || _isVoiceStarting || !_isDictating) {
      _voiceReleasedBeforeStart = true;
    } else {
      unawaited(_finishMealVoiceInput(cancel: true));
    }
  }

  void _resetVoiceHoldState() {
    _voiceHoldTimer?.cancel();
    _voiceHoldTimer = null;
    _voiceHoldPointer = null;
    _voiceHoldOrigin = null;
    _voiceHoldActivated = false;
    _voiceReleasedBeforeStart = false;
    _voicePermissionFlow = false;
  }

  Future<void> _startMealVoiceInput() async {
    if (_isDictating || _isVoiceStarting || !mounted) return;

    if (Platform.isIOS && !_isIosSimulator) {
      await _detectIosSimulator();
      if (!mounted) return;
    }

    _voiceTextWasVisible = _showTextInput;
    _textFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));

    final simulatorDemo = _isIosSimulator;
    if (!simulatorDemo &&
        !await VoiceDictationService.instance.hasPermissions()) {
      if (!mounted) return;
      _voicePermissionFlow = true;
      final l10n = AppLocalizations.of(context)!;
      final proceed = await showPrePermissionDialog(
        context: context,
        title: l10n.voicePermissionTitle,
        body: l10n.voicePermissionBody,
        continueLabel: l10n.voicePermissionContinue,
        cancelLabel: l10n.cancel,
      );
      _voicePermissionFlow = false;
      if (!mounted || !proceed) {
        _resetVoiceHoldState();
        return;
      }
    }

    if (!simulatorDemo) {
      final availability = await VoiceDictationService.instance.prepare();
      if (!mounted) return;
      if (!availability.available) {
        final l10n = AppLocalizations.of(context)!;
        final message = switch (availability.reason) {
          VoiceUnavailableReason.permissionDenied =>
            l10n.voiceUnavailablePermission,
          VoiceUnavailableReason.unsupported =>
            l10n.voiceUnavailableUnsupported,
          _ => l10n.voiceUnavailableFailed,
        };
        _resetVoiceHoldState();
        _showDictationFallback(message);
        return;
      }
    }

    _voiceBaseText = _textController.text.trim();
    _voiceRecordingStopwatch
      ..reset()
      ..start();
    setState(() {
      _isDictating = true;
      _isVoiceDemo = simulatorDemo;
      _isVoiceStarting = !simulatorDemo;
      _isVoiceStopping = false;
      _voiceTranscript = '';
      _voiceLevel = 0;
      _showTextInput = false;
    });

    if (simulatorDemo) {
      _startSimulatorVoiceDemo();
      return;
    }

    final localeId = await VoiceDictationSettings.instance.localeId();
    if (!mounted || !_isDictating) return;
    final started = await VoiceDictationService.instance.start(
      localeId: localeId,
      onPartial: (text) {
        if (!mounted || !_isDictating) return;
        setState(() => _voiceTranscript = text);
      },
      onFinal: (text) {
        if (!mounted || !_isDictating) return;
        setState(() => _voiceTranscript = text);
      },
      onSoundLevel: (level) {
        if (!mounted || !_isDictating) return;
        setState(() => _voiceLevel = level);
      },
      onStopped: () {
        if (mounted && _isDictating && !_isVoiceStopping) {
          unawaited(_finishMealVoiceInput());
        }
      },
    );

    if (!mounted || !_isDictating) return;
    if (!started) {
      _voiceRecordingStopwatch.stop();
      setState(() {
        _isDictating = false;
        _isVoiceStarting = false;
        _voiceLevel = 0;
      });
      _resetVoiceHoldState();
      _showDictationFallback(
        AppLocalizations.of(context)!.voiceUnavailableFailed,
      );
      return;
    }

    setState(() => _isVoiceStarting = false);
    if (_voiceReleasedBeforeStart) {
      unawaited(_finishMealVoiceInput());
    } else if (!VoiceDictationService.instance.isListening) {
      unawaited(_finishMealVoiceInput());
    }
  }

  void _startSimulatorVoiceDemo() {
    const sample = 'Hähnchen-Dürüm mit Salat und Joghurtsauce.';
    var elapsedMs = 0;
    _voiceDemoTimer?.cancel();
    _voiceDemoTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (timer) {
        if (!mounted || !_isDictating || !_isVoiceDemo) {
          timer.cancel();
          return;
        }
        elapsedMs += 80;
        final characterCount =
            ((elapsedMs - 300) / 42).floor().clamp(0, sample.length);
        final pulse = (math.sin(elapsedMs / 170) + 1) / 2;
        final variation = (math.sin(elapsedMs / 73) + 1) / 2;
        setState(() {
          _voiceTranscript = sample.substring(0, characterCount);
          _voiceLevel = 0.12 + pulse * 0.58 + variation * 0.22;
          _isVoiceStarting = false;
        });
      },
    );
  }

  Future<void> _finishMealVoiceInput({bool cancel = false}) async {
    if (!_isDictating || _isVoiceStopping) return;
    setState(() => _isVoiceStopping = true);
    _voiceRecordingStopwatch.stop();
    _voiceDemoTimer?.cancel();
    final durationBucket = TelemetryBuckets.getVoiceDurationBucket(
      _voiceRecordingStopwatch.elapsed,
    );

    if (cancel) {
      if (!_isVoiceDemo) await VoiceDictationService.instance.cancel();
      if (!mounted) return;
      setState(() {
        _isDictating = false;
        _isVoiceDemo = false;
        _isVoiceStarting = false;
        _isVoiceStopping = false;
        _voiceLevel = 0;
        _voiceTranscript = '';
        _showTextInput = _voiceTextWasVisible;
      });
      _resetVoiceHoldState();
      return;
    }

    if (!_isVoiceDemo) await VoiceDictationService.instance.stop();
    await Future<void>.delayed(
      Duration(milliseconds: _isVoiceDemo ? 180 : 350),
    );
    if (!mounted) return;

    final spokenText = _voiceTranscript.trim();
    final combinedText = [
      if (_voiceBaseText.isNotEmpty) _voiceBaseText,
      if (spokenText.isNotEmpty) spokenText,
    ].join(' ');
    _textController.text = combinedText;
    _textCameFromVoice = _textCameFromVoice || spokenText.isNotEmpty;
    if (!_isVoiceDemo) {
      unawaited(TelemetryService.instance.trackFeatureUsed(
        featureKey: FeatureKey.voiceDictationUsed,
      ));
      unawaited(TelemetryService.instance.trackVoiceDictationCompleted(
        durationBucket: durationBucket,
        aiTidyUpEnabled: false,
        surface: 'ai_meal_capture',
        success: true,
      ));
    }
    setState(() {
      _isDictating = false;
      _isVoiceDemo = false;
      _isVoiceStarting = false;
      _isVoiceStopping = false;
      _voiceLevel = 0;
      _showTextInput = combinedText.isNotEmpty;
    });
    _resetVoiceHoldState();
    HapticFeedbackService.instance.confirmationFeedback();
  }

  /// Dictation is a convenience; when it is unavailable the typed path must
  /// still be one tap away rather than a dead end.
  void _showDictationFallback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
    setState(() => _showTextInput = true);
  }
}

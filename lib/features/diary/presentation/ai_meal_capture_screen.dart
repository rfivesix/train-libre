// lib/screens/ai_meal_capture_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/app_localizations.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/ai_service.dart';
import 'util/photo_pre_processor.dart';
import '../../../services/ai_matching_language_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../depth_scan/data/depth_map_attachment.dart';
import '../../depth_scan/data/depth_scan_settings.dart';
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'ai_meal_review_screen.dart';
import 'meal_analysis_screen.dart';
import 'meal_editor_screen.dart';
import '../../settings/presentation/ai_settings_screen.dart';
import '../../../util/design_constants.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../data/sources/product_local_data_source.dart';
import '../domain/models/food_item.dart';
import 'dialogs/quantity_log_flow.dart';
import 'dialogs/voice_dictation_sheet.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../services/telemetry/telemetry_buckets.dart';
import '../../../services/voice/voice_dictation_service.dart';
import '../../../util/permission_dialogs.dart';

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
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Navigation & Lifecycle state
  bool _isRouteObserverAttached = false;
  bool _isTopRoute = true;
  bool _isCameraSuspended = false;

  // Camera & Barcode state
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR_Capture');
  QRViewController? _qrController;
  PermissionStatus _cameraPermission = PermissionStatus.denied;
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

  @override
  void reassemble() {
    super.reassemble();
    if (_useNativeSession) return;
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      if (_isTopRoute && !_isCameraSuspended && !_isAnalyzing && !_isDictating) {
        _qrController?.resumeCamera();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.aiMealCapture));
    WidgetsBinding.instance.addObserver(this);
    _checkDbStatus();
    unawaited(_prepareCamera());

    _analyzeButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
    if (!_isAnalyzing && !_isDictating) {
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
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _stopAiWaitingHaptics();
    _barcodeSubscription?.cancel();
    _analysisController?.dispose();
    unawaited(VoiceDictationService.instance.cancel());
    if (_useNativeSession) {
      unawaited(DepthScanChannel.instance.stopSession());
    } else {
      _qrController?.dispose();
    }
    _preProcessor.dispose();
    _textController.dispose();
    _analyzeButtonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_isTopRoute &&
          !_isCameraSuspended &&
          !_isAnalyzing &&
          !_isDictating) {
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
    if (_useNativeSession) {
      await DepthScanChannel.instance.stopSession();
    } else {
      await _qrController?.pauseCamera();
    }
  }

  /// Resumes active camera preview and depth/barcode hardware if the screen is currently active.
  Future<void> _resumeCamera() async {
    _isCameraSuspended = false;
    if (!mounted ||
        !_cameraPermission.isGranted ||
        !_isTopRoute ||
        _isAnalyzing ||
        _isDictating) {
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
    await _checkPermission();
    if (!mounted || !_cameraPermission.isGranted) return;
    await _initCaptureSession();
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
    if (_isCameraSuspended || !_isTopRoute || _isAnalyzing || _isDictating) {
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
        if (_isTopRoute && !_isAnalyzing && !_isDictating) {
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
        if (capture.scaleFacts?.isValid == true || capture.depthBuffer != null) {
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
        final newFiles = picked.take(remaining).map((x) => File(x.path)).toList();
        setState(() {
          _images.addAll(newFiles);
        });
        _preProcessor.processImages(newFiles);
      }
    } finally {
      if (mounted && _isTopRoute && !_isAnalyzing && !_isDictating) {
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
    if (_analysisRoute == null) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.removeRoute(_analysisRoute!);
    }
    _analysisRoute = null;
  }

  Future<void> _analyze() async {
    if (!_hasInput) return;
    setState(() => _isAnalyzing = true);
    _startAiWaitingHaptics();
    await _suspendCamera();

    // A blocking screen while the request is in flight: previously the capture
    // screen stayed editable underneath, so images could be added or removed
    // while they were already being analysed.
    final controller = MealAnalysisController();
    _analysisController?.dispose();
    _analysisController = controller;
    _analysisRoute = MealAnalysisScreen.route(
      controller: controller,
      previewImage: _images.isNotEmpty ? _images.first : null,
      onCancel: () {
        _analysisCancelled = true;
        _stopAiWaitingHaptics();
        _dismissAnalysisScreen();
        if (mounted) {
          setState(() => _isAnalyzing = false);
          if (_isTopRoute && !_isDictating) {
            unawaited(_resumeCamera());
          }
        }
      },
    );
    _analysisCancelled = false;
    unawaited(Navigator.of(context).push(_analysisRoute!));

    if (!mounted) return;
    final matchingContext =
        await AiMatchingLanguageService.resolveMatchingContext(
      context: context,
    );

    if (_images.isNotEmpty) {
      await _preProcessor.waitForCompletion(_images);
    }
    if (!mounted) return;

    // Switchable so the same meal can be shot with and without the hint;
    // otherwise there is no way to tell whether the measurement helps.
    final scaleHintEnabled =
        await DepthScanSettings.instance.isScaleHintEnabled();
    final depthFacts = scaleHintEnabled ? _lastDepthCapture?.scaleFacts : null;

    // The relief of the meal, as a second image. Rendered here rather than kept
    // around: the band scale is fitted to the frame, so it only exists once the
    // capture it belongs to does.
    final capture = _lastDepthCapture;
    DepthMapAttachment? depthMap;
    if (capture != null &&
        await DepthScanSettings.instance.isDepthImageEnabled()) {
      depthMap = await buildDepthMapAttachment(capture);
    }
    if (!mounted) return;

    controller.value = MealAnalysisPhase.analyzing;

    final stopwatch = Stopwatch()..start();
    final requestId = const Uuid().v4();
    final provider = (await AiService.instance.getSelectedProvider()).name;
    final text = _textController.text.trim();
    final hasImages = _images.isNotEmpty;
    final hasText = text.isNotEmpty;
    final hasVoice = _isDictating || text.isNotEmpty;
    final hasLidar = _depthCaptures.values.any((c) => c.depthBuffer != null);
    final inputMode = hasImages && hasText
        ? 'multimodal'
        : (hasImages ? 'photo' : 'text_only');

    unawaited(TelemetryService.instance.trackAiMealScanRequested(
      requestId: requestId,
      provider: provider,
      inputMode: inputMode,
      photoCount: _images.length,
      hasLidar: hasLidar,
      hasVoiceInput: hasVoice,
      hasTextInput: hasText,
    ));

    try {
      AiMealCandidate candidate;

      if (_images.isNotEmpty) {
        candidate = await AiService.instance.analyzeImages(
          _images,
          textHint: text.isNotEmpty ? text : null,
          matchingContext: matchingContext,
          depthFacts: depthFacts,
          depthMap: depthMap?.file,
          depthMapLegend: depthMap?.describeForPrompt(),
        );
      } else {
        candidate = await AiService.instance.analyzeText(
          text,
          matchingContext: matchingContext,
        );
      }

      controller.value = MealAnalysisPhase.matching;
      final validationOutcome =
          await _validateAndRepair(candidate, matchingContext);

      if (!mounted) return;
      // The user walked away from the wait; their result is no longer wanted.
      if (_analysisCancelled) return;

      stopwatch.stop();
      final latencyBucket =
          TelemetryBuckets.getLatencyBucket(stopwatch.elapsed);
      final itemCountBucket = TelemetryBuckets.getItemCountBucket(
          validationOutcome.validation.candidate.items.length);

      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: latencyBucket,
        success: true,
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
        validationPassed: validationOutcome.validation.passed,
        repairAttemptsCount: validationOutcome.repairPassesUsed,
        suggestedItemsCountBucket: itemCountBucket,
      ));

      _stopAiWaitingHaptics();
      _dismissAnalysisScreen();
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }

      final detectedType = _detectMealTypeFromText(text);
      final resolvedMealType = widget.initialMealType ??
          detectedType ??
          MealTypeTimeExtension.fromCurrentTime().toMealTypeKey;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AiMealReviewScreen(
            suggestions: validationOutcome.validation.candidate.items
                .map(
                  (item) => AiSuggestedItem(
                    name: item.name,
                    estimatedGrams: item.grams,
                    confidence: item.confidence ?? 1.0,
                    matchedBarcode: item.matchedBarcode,
                  ),
                )
                .toList(growable: false),
            initialValidation: validationOutcome.validation,
            originalImages: _images,
            initialDate: widget.initialDate,
            initialMealType: resolvedMealType,
            depthResult: _lastDepthCapture,
            depthResultsByPath: _depthCaptures,
            depthFacts: _lastDepthCapture?.scaleFacts,
            voiceTranscript: text.isNotEmpty ? text : null,
          ),
        ),
      );
      // Leaving the review returns to wherever the capture was started from,
      // saved or not. Dropping back into the viewfinder after reviewing a meal
      // is never what the user meant by "back".
      if (mounted) {
        Navigator.of(context).pop(saved == true);
      }
    } on AiKeyMissingException {
      stopwatch.stop();
      final latencyBucket =
          TelemetryBuckets.getLatencyBucket(stopwatch.elapsed);
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: latencyBucket,
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
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
      stopwatch.stop();
      final latencyBucket =
          TelemetryBuckets.getLatencyBucket(stopwatch.elapsed);
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: latencyBucket,
        success: false,
        errorCode: e.runtimeType.toString(),
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
      _dismissAnalysisScreen();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      final latencyBucket =
          TelemetryBuckets.getLatencyBucket(stopwatch.elapsed);
      unawaited(TelemetryService.instance.trackAiMealScanCompleted(
        requestId: requestId,
        provider: provider,
        latencyBucket: latencyBucket,
        success: false,
        errorCode: e.runtimeType.toString(),
        inputMode: inputMode,
        photoCount: _images.length,
        hasLidar: hasLidar,
        hasVoiceInput: hasVoice,
        hasTextInput: hasText,
      ));
      _dismissAnalysisScreen();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      _stopAiWaitingHaptics();
      _dismissAnalysisScreen();
      if (mounted) {
        setState(() => _isAnalyzing = false);
        if (_isTopRoute && !_isDictating) {
          unawaited(_resumeCamera());
        }
      }
    }
  }

  Future<AiRepairOutcome> _validateAndRepair(
    AiMealCandidate candidate,
    AiMatchingContext matchingContext,
  ) {
    final engine = AiMealValidationEngine();
    final orchestrator = AiRepairOrchestrator(validationEngine: engine);
    return orchestrator.run(
      initialCandidate: candidate,
      mode: AiValidationMode.capture,
      repairer: (candidate, validation, attempt) {
        return AiService.instance.repairMealCaptureCandidate(
          candidate: candidate,
          validation: validation,
          images: _images.isNotEmpty ? _images : null,
          matchingContext: matchingContext,
          mealContext: candidate.context,
        );
      },
    );
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
    if (mounted && _isTopRoute && !_isAnalyzing && !_isDictating) {
      unawaited(_resumeCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primaryAccent = isDark
        ? const Color(0xFFC9EF00)
        : DesignConstants.brandAccentColorLightMode;

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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Live Camera Viewfinder (full width, maximum screen height with rounded corners)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_cameraPermission.isGranted)
                        _buildCameraFallback()
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
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white24, width: 1),
                              ),
                              child: Text(
                                _distanceHint!,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
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

            // 2. Bottom Controls Area (compact, pinned to bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Captured Photos Strip
                  if (_images.isNotEmpty)
                    Container(
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _images[idx],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(idx),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xCC000000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.x,
                                        size: 11, color: Colors.white),
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
                              color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        padding: const EdgeInsets.only(
                            left: DesignConstants.spacingL),
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
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
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: DesignConstants.spacingM),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIconConstraints: const BoxConstraints(
                                minWidth: 44, minHeight: 44),
                            suffixIcon: Align(
                              alignment: Alignment.topCenter,
                              widthFactor: 1,
                              heightFactor: 1,
                              child: IconButton(
                                icon: Icon(LucideIcons.check,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black87,
                                    size: 18),
                                onPressed: () =>
                                    setState(() => _showTextInput = false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Passive Barcode Detection Banner (if detected)
                  if (_barcodeDetectionEnabled && _detectedBarcode != null)
                    _buildBarcodeBanner(l10n, primaryAccent),

                  // Shutter & Primary Action Bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery Button
                            _buildFrostedButton(
                              icon: LucideIcons.image,
                              onTap: _pickFromGallery,
                            ),

                            // Barcode detection toggle
                            _buildFrostedButton(
                              icon: LucideIcons.scan_barcode,
                              isActive: _barcodeDetectionEnabled,
                              onTap: () {
                                setState(() {
                                  _barcodeDetectionEnabled =
                                      !_barcodeDetectionEnabled;
                                  if (!_barcodeDetectionEnabled) {
                                    _detectedBarcode = null;
                                    _detectedProduct = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Shutter Button (68px diameter)
                      GestureDetector(
                        onTap: _takeShutterPhoto,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF12120F)
                                      .withValues(alpha: 0.8),
                              width: 3.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF12120F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Voice Dictation Button (Microphone)
                            _buildFrostedButton(
                              icon: LucideIcons.mic,
                              isActive: _isDictating,
                              onTap: _openVoiceDictationModal,
                            ),

                            // Text Note Toggle Button
                            _buildFrostedButton(
                              icon: LucideIcons.pencil,
                              isActive: _showTextInput ||
                                  _textController.text.isNotEmpty,
                              onTap: () {
                                setState(() {
                                  _showTextInput = !_showTextInput;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // "Analysieren" Button (Appears when input is ready)
                  if (_hasInput) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark
                              ? const Color(0xFF12120F)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isAnalyzing ? null : _analyze,
                        child: _isAnalyzing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: isDark
                                          ? const Color(0xFF12120F)
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.aiCaptureAnalyzing,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? const Color(0xFF12120F)
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      fontFamily: 'Plus Jakarta Sans',
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
                  ],
                ],
              ),
            ),
          ],
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
                fontFamily: 'Plus Jakarta Sans',
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
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9EF00),
                foregroundColor: const Color(0xFF12120F),
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

  Widget _buildBarcodeBanner(AppLocalizations l10n, Color primaryAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          fontFamily: 'Plus Jakarta Sans',
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
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF12120F),
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
                            fontFamily: 'Plus Jakarta Sans',
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

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark
        ? const Color(0xFFC9EF00)
        : DesignConstants.brandAccentColorLightMode;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? primaryAccent.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? primaryAccent
                  : (isDark ? Colors.white24 : Colors.black12),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isActive
                ? primaryAccent
                : (isDark ? Colors.white : const Color(0xFF12120F)),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Opens the dictation sheet and folds the result back into the note field.
  ///
  /// The transcript is always shown for editing before it is used: dictation
  /// mishears numbers, and "150 g" turning into "115 g" would silently produce
  /// a wrong meal.
  Future<void> _openVoiceDictationModal() async {
    // The camera stands down for the duration. An `AVAudioEngine` starting up
    // against a live capture session is the one configuration where the
    // recogniser reliably fell over, and the viewfinder is behind a full-height
    // sheet anyway.
    await _suspendCamera();

    // Explained before the system prompt appears, the same way every other
    // permission in the app is. Apple rejects builds that fire the microphone
    // and speech-recognition prompts with no context, and the user deserves to
    // know what is being asked for before deciding.
    if (!await VoiceDictationService.instance.hasPermissions()) {
      if (!mounted) {
        await _resumeCamera();
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final proceed = await showPrePermissionDialog(
        context: context,
        title: l10n.voicePermissionTitle,
        body: l10n.voicePermissionBody,
        continueLabel: l10n.voicePermissionContinue,
        cancelLabel: l10n.cancel,
      );
      if (!proceed) {
        await _resumeCamera();
        return;
      }
    }
    if (!mounted) {
      await _resumeCamera();
      return;
    }

    final availability = await VoiceDictationService.instance.prepare();
    if (!mounted) {
      await _resumeCamera();
      return;
    }

    if (!availability.available) {
      await _resumeCamera();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = switch (availability.reason) {
        VoiceUnavailableReason.permissionDenied =>
          l10n.voiceUnavailablePermission,
        VoiceUnavailableReason.unsupported => l10n.voiceUnavailableUnsupported,
        _ => l10n.voiceUnavailableFailed,
      };
      _showDictationFallback(message);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isDictating = true);
    final result = await showVoiceDictationSheet(
      context: context,
      initialText: _textController.text,
      exampleHint: _images.isEmpty
          ? l10n.voiceExampleStandalone
          : l10n.voiceExampleWithPhoto,
      // Same wording as the button on this screen, so the sheet's primary
      // action reads as the same step rather than a different one.
      analyzeLabel: _images.isNotEmpty
          ? l10n.aiCaptureAnalyzeMeal(_images.length)
          : l10n.aiCaptureAnalyzeText,
    );

    if (!mounted) {
      await _resumeCamera();
      return;
    }

    setState(() {
      _isDictating = false;
      if (result != null) {
        _textController.text = result.text.trim();
        _showTextInput = _textController.text.isNotEmpty;
      }
    });

    if (result != null && result.analyzeNow && _hasInput) {
      await _analyze();
    } else {
      await _resumeCamera();
    }
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

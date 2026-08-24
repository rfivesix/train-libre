// lib/screens/ai_meal_capture_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/ai_service.dart';
import 'util/photo_pre_processor.dart';
import '../../../services/ai_matching_language_service.dart';
import '../../../services/haptic_feedback_service.dart';
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
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../services/voice/voice_dictation_service.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Camera & Barcode state
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR_Capture');
  QRViewController? _qrController;
  PermissionStatus _cameraPermission = PermissionStatus.denied;
  String? _detectedBarcode;
  String? _detectedBarcodeName;

  /// Passive barcode detection. On by default — most packaged foods are logged
  /// this way — but switchable, because on a plated meal the constant chip is
  /// noise rather than help.
  bool _barcodeDetectionEnabled = true;
  bool _hasLidar = false;

  /// True once the unified native session (preview + barcodes + photo + depth)
  /// is available. Only then does the separate scanner camera stay out of the
  /// picture — two sessions cannot own the back camera at the same time.
  bool _useNativeSession = false;
  bool _nativeSessionRunning = false;
  StreamSubscription<String>? _barcodeSubscription;

  /// Set when the last capture measured a distance outside the range LiDAR can
  /// be trusted at. Replaces the previous hard-coded distance pill.
  String? _distanceHint;

  // Voice dictation state
  bool _isDictating = false;
  double _dictationLevel = 0;

  // Photo state
  final List<File> _images = [];
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
      _qrController?.resumeCamera();
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAiWaitingHaptics();
    _barcodeSubscription?.cancel();
    _analysisController?.dispose();
    unawaited(VoiceDictationService.instance.cancel());
    if (_useNativeSession) {
      unawaited(DepthScanChannel.instance.stopSession());
    }
    _preProcessor.dispose();
    _textController.dispose();
    _analyzeButtonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_useNativeSession) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(DepthScanChannel.instance.startSession());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(DepthScanChannel.instance.stopSession());
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

    final started = await DepthScanChannel.instance.startSession();
    if (!mounted) return;

    if (!started) {
      // Native session refused; the scanner camera path still works.
      setState(() => _useNativeSession = false);
      return;
    }

    setState(() => _nativeSessionRunning = true);
    _barcodeSubscription =
        DepthScanChannel.instance.barcodes.listen(_onBarcodeDetected);
  }

  Future<void> _onBarcodeDetected(String code) async {
    if (!_barcodeDetectionEnabled) return;
    if (code.isEmpty || code == _detectedBarcode || !mounted) return;

    HapticFeedbackService.instance.confirmationFeedback();
    setState(() {
      _detectedBarcode = code;
      _detectedBarcodeName = 'Barcode $code';
    });

    try {
      final item =
          await ProductLocalDataSource.instance.getProductByBarcode(code);
      if (item != null && mounted && _detectedBarcode == code) {
        setState(() => _detectedBarcodeName = item.name);
      }
    } catch (_) {}
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
      if (code != null && code != _detectedBarcode && code.isNotEmpty) {
        HapticFeedbackService.instance.confirmationFeedback();
        setState(() {
          _detectedBarcode = code;
          _detectedBarcodeName = 'Barcode $code';
        });

        // Lookup product name asynchronously in background
        try {
          final item =
              await ProductLocalDataSource.instance.getProductByBarcode(code);
          if (item != null && mounted) {
            setState(() {
              _detectedBarcodeName = item.name;
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
    if (lower.contains('breakfast') || lower.contains('frühstück')) return 'mealtypeBreakfast';
    if (lower.contains('lunch') || lower.contains('mittag')) return 'mealtypeLunch';
    if (lower.contains('dinner') || lower.contains('abend')) return 'mealtypeDinner';
    if (lower.contains('snack') || lower.contains('zwischenmahlzeit')) return 'mealtypeSnack';
    return null;
  }

  /// A short, non-alarming note when the measurement fell outside the range
  /// LiDAR is dependable at. Null means everything was fine — the common case,
  /// which deliberately shows nothing at all.
  String? _distanceHintFor(DepthCaptureResult result) {
    final facts = result.scaleFacts;
    if (facts == null) return null;
    if (facts.isValid) return null;
    if (facts.accuracy != 'absolute') return null;

    if (facts.subjectDistanceCm < 15) {
      return 'Etwas weiter weg gehen';
    }
    if (facts.subjectDistanceCm > 120) {
      return 'Etwas näher herangehen';
    }
    return null;
  }

  Future<void> _takeShutterPhoto() async {
    if (_images.length >= _maxImages) return;

    HapticFeedbackService.instance.selectionFeedback();

    // The running session takes the photo — including on devices without
    // LiDAR, where it simply returns no depth map. Opening the system camera
    // on top of a live preview would be the wrong thing everywhere.
    if (_useNativeSession && _nativeSessionRunning) {
      try {
        final res = await DepthScanChannel.instance.capture();
        if (res != null && mounted) {
          setState(() {
            _lastDepthCapture = res;
            _images.add(res.imageFile);
            _distanceHint = _distanceHintFor(res);
          });
          _preProcessor.processImages([res.imageFile]);
          return;
        }
      } catch (_) {}
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
  }

  void _removeImage(int index) {
    final file = _images[index];
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
        if (mounted) setState(() => _isAnalyzing = false);
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
    if (!mounted) return;

    controller.value = MealAnalysisPhase.analyzing;

    try {
      AiMealCandidate candidate;
      final text = _textController.text.trim();

      if (_images.isNotEmpty) {
        candidate = await AiService.instance.analyzeImages(
          _images,
          textHint: text.isNotEmpty ? text : null,
          matchingContext: matchingContext,
          depthFacts: depthFacts,
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
      _dismissAnalysisScreen();
      if (!mounted) return;
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
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
      if (mounted) setState(() => _isAnalyzing = false);
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

  void _showKeyMissingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showGlassBottomMenu<void>(
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lime = const Color(0xFFC9EF00);

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

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: GlobalAppBar(
        title: 'AI Scanner',
        actions: [
          if (_hasLidar)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Text(
                    'LiDAR',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Viewfinder
          if (!_cameraPermission.isGranted)
            _buildCameraFallback()
          else if (_useNativeSession)
            // Preview, barcode detection and the photo all come from one native
            // session; a second camera client here would black this out.
            UiKitView(
              viewType: DepthScanChannel.previewViewType,
              creationParamsCodec: const StandardMessageCodec(),
            )
          else
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: null,
            ),

          // 2. Subtle Dark Gradients for contrast
          Positioned.fill(
            child: IgnorePointer(
              child: Column(
                children: [
                  Container(
                    height: 140,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCC000000),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 240,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xD9000000),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Distance guidance, only when the last measurement was out of
          // range. No pill in the normal case — there is nothing to say.
          if (_distanceHint != null)
            Positioned(
              top: kToolbarHeight + topPadding + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24, width: 1),
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

          // 4. Passive Barcode Detection Banner (if detected)
          if (_barcodeDetectionEnabled && _detectedBarcode != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(_detectedBarcode);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: lime.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.scan_barcode, color: lime, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _detectedBarcodeName ?? _detectedBarcode!,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lime,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Loggen',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF12120F),
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

          // 5. Bottom Controls (Thumbnails, Shutter, Text & Analyze)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Captured Photos Strip
                    if (_images.isNotEmpty)
                      Container(
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _images[idx],
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xCC000000),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.x,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // Expandable Text Input Row
                    //
                    // Plain surface, no accent outline: lime marks the one
                    // primary action on a screen, and a focused text field is
                    // already obvious from the cursor and the keyboard.
                    if (_showTextInput)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingM),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1E1E1E).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(
                                DesignConstants.borderRadiusL),
                            border: Border.all(color: Colors.white12),
                          ),
                          padding: const EdgeInsets.only(
                              left: DesignConstants.spacingL),
                          child: TextField(
                            controller: _textController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText:
                                  'Mahlzeit beschreiben (z.B. 2 Eier mit Toast)...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5)),
                              // The theme fills inputs by default, which drew a
                              // second, lighter pill inside this container.
                              filled: false,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: DesignConstants.spacingL),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(LucideIcons.check,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 18),
                                onPressed: () =>
                                    setState(() => _showTextInput = false),
                              ),
                            ),
                            onSubmitted: (_) =>
                                setState(() => _showTextInput = false),
                          ),
                        ),
                      ),

                    // Shutter & Primary Action Bar
                    //
                    // Three columns of equal weight rather than four evenly
                    // spread buttons: with four, the shutter ends up right of
                    // the screen centre, which every camera app gets right and
                    // the eye notices immediately.
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
                                      _detectedBarcodeName = null;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Shutter Button (76px diameter Screen A1)
                        GestureDetector(
                          onTap: _takeShutterPhoto,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 3.5),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lime,
                            foregroundColor: const Color(0xFF12120F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isAnalyzing ? null : _analyze,
                          // A bare spinner on an otherwise empty bar read as a
                          // broken button; the wait itself now has its own
                          // screen, so this only has to stay recognisable.
                          child: _isAnalyzing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF12120F),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Analysiere…',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.sparkles,
                                        size: 18, color: Color(0xFF12120F)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _images.isNotEmpty
                                          ? 'Mahlzeit analysieren (${_images.length})'
                                          : 'Text analysieren',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFallback() {
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
              child: const Text('Einstellungen öffnen',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    const lime = Color(0xFFC9EF00);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? lime.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? lime : Colors.white24,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? lime : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Hold-to-talk dictation.
  ///
  /// The transcript is always shown for editing before it is used: dictation
  /// mishears numbers, and "150 g" turning into "115 g" would silently produce
  /// a wrong meal.
  Future<void> _openVoiceDictationModal() async {
    final availability = await VoiceDictationService.instance.prepare();
    if (!mounted) return;

    if (!availability.available) {
      final message = switch (availability.reason) {
        VoiceUnavailableReason.permissionDenied =>
          'Ohne Mikrofon- und Spracherkennungsfreigabe geht das Diktat nicht. Du kannst den Text weiterhin eintippen.',
        VoiceUnavailableReason.unsupported =>
          'Dieses Gerät bietet keine Spracherkennung an. Du kannst den Text eintippen.',
        _ =>
          'Die Spracherkennung ließ sich nicht starten. Du kannst den Text eintippen.',
      };
      _showDictationFallback(message);
      return;
    }

    final textEditController =
        TextEditingController(text: _textController.text);
    final baseText = _textController.text.trim();

    await showGlassBottomMenu<void>(
      context: context,
      title: 'Mahlzeit diktieren',
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> beginDictation() async {
              final started = await VoiceDictationService.instance.start(
                localeId: Localizations.localeOf(ctx)
                    .toLanguageTag()
                    .replaceAll('-', '_'),
                onPartial: (text) {
                  textEditController.text =
                      baseText.isEmpty ? text : '$baseText $text';
                  textEditController.selection = TextSelection.collapsed(
                    offset: textEditController.text.length,
                  );
                },
                onFinal: (text) {
                  textEditController.text =
                      baseText.isEmpty ? text : '$baseText $text';
                  textEditController.selection = TextSelection.collapsed(
                    offset: textEditController.text.length,
                  );
                  setSheetState(() {});
                },
                onSoundLevel: (level) {
                  setSheetState(() => _dictationLevel = level);
                },
              );
              setSheetState(() => _isDictating = started);
              if (started) {
                HapticFeedbackService.instance.selectionFeedback();
              }
            }

            Future<void> endDictation() async {
              await VoiceDictationService.instance.stop();
              setSheetState(() {
                _isDictating = false;
                _dictationLevel = 0;
              });
            }

            final level = (_dictationLevel.clamp(-2.0, 10.0) + 2) / 12;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: (_) => beginDictation(),
                        onTapUp: (_) => endDictation(),
                        onTapCancel: endDictation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 72 + (_isDictating ? level * 24 : 0),
                          height: 72 + (_isDictating ? level * 24 : 0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9EF00)
                                .withValues(alpha: _isDictating ? 0.45 : 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.mic,
                            color: Color(0xFFC9EF00),
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isDictating
                            ? 'Sprich jetzt — loslassen zum Beenden'
                            : 'Zum Sprechen gedrückt halten',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _images.isEmpty
                            ? 'z. B. „Ein Teller Gemüsedöner mit Fladenbrot und Knoblauchsauce“'
                            : 'Ergänze, was das Foto nicht zeigt — z. B. „in zwei Esslöffeln Olivenöl gebraten“',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (VoiceDictationService
                          .instance.lastRunUsedNetwork) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Dieses Gerät erkennt Sprache nicht lokal. Die Aufnahme wird zur Umwandlung an die Spracherkennung des Systems gesendet.',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 11.5,
                            color: Colors.orange.withValues(alpha: 0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textEditController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Erkannter Text — hier korrigierbar',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AppButton.primary(
                  onPressed: () async {
                    await endDictation();
                    setState(() {
                      _textController.text = textEditController.text.trim();
                      _showTextInput = _textController.text.isNotEmpty;
                    });
                    close();
                  },
                  label: 'Text übernehmen',
                  tooltip: 'Text übernehmen',
                ),
              ],
            );
          },
        );
      },
    );

    await VoiceDictationService.instance.cancel();
    if (mounted) {
      setState(() {
        _isDictating = false;
        _dictationLevel = 0;
      });
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

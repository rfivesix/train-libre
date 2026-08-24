// lib/screens/ai_meal_capture_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
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
import '../../depth_scan/platform/depth_scan_channel.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'ai_meal_review_screen.dart';
import 'meal_editor_screen.dart';
import '../../settings/presentation/ai_settings_screen.dart';
import '../../../util/design_constants.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../data/sources/product_local_data_source.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';

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
  bool _hasLidar = false;

  // Photo state
  final List<File> _images = [];
  DepthCaptureResult? _lastDepthCapture;
  static const int _maxImages = 4;
  final PhotoPreProcessor _preProcessor = PhotoPreProcessor();

  // Analysis state
  bool _isAnalyzing = false;
  bool _aiWaitingHapticActive = false;
  bool _showTextInput = false;

  late AnimationController _analyzeButtonAnimationController;
  bool _isOffDbInitialized = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      _qrController?.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance.trackScreenView(screenName: ScreenName.aiMealCapture));
    WidgetsBinding.instance.addObserver(this);
    _checkDbStatus();
    _checkPermission();
    _checkLidar();

    _analyzeButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAiWaitingHaptics();
    _preProcessor.dispose();
    _textController.dispose();
    _analyzeButtonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkDbStatus() async {
    final initialized = await BasisDataManager.instance.isOffDatabaseInitialized();
    if (mounted) {
      setState(() {
        _isOffDbInitialized = initialized;
      });
    }
  }

  Future<void> _checkLidar() async {
    final supported = await DepthScanChannel.instance.isLiDARSupported();
    if (mounted) {
      setState(() {
        _hasLidar = supported;
      });
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
      if (code != null && code != _detectedBarcode && code.isNotEmpty) {
        HapticFeedbackService.instance.confirmationFeedback();
        setState(() {
          _detectedBarcode = code;
          _detectedBarcodeName = 'Barcode $code';
        });

        // Lookup product name asynchronously in background
        try {
          final item = await ProductLocalDataSource.instance.getProductByBarcode(code);
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

  Future<void> _takeShutterPhoto() async {
    if (_images.length >= _maxImages) return;

    HapticFeedbackService.instance.selectionFeedback();

    if (_hasLidar) {
      try {
        final res = await DepthScanChannel.instance.capture();
        if (res != null && mounted) {
          setState(() {
            _lastDepthCapture = res;
            _images.add(res.imageFile);
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

  bool get _hasInput => _images.isNotEmpty || _textController.text.trim().isNotEmpty;

  Future<void> _analyze() async {
    if (!_hasInput) return;
    setState(() => _isAnalyzing = true);
    _startAiWaitingHaptics();

    if (!mounted) return;
    final matchingContext = await AiMatchingLanguageService.resolveMatchingContext(
      context: context,
    );

    if (_images.isNotEmpty) {
      await _preProcessor.waitForCompletion(_images);
    }
    if (!mounted) return;

    try {
      AiMealCandidate candidate;
      final text = _textController.text.trim();

      if (_images.isNotEmpty) {
        candidate = await AiService.instance.analyzeImages(
          _images,
          textHint: text.isNotEmpty ? text : null,
          matchingContext: matchingContext,
          depthFacts: _lastDepthCapture?.scaleFacts,
        );
      } else {
        candidate = await AiService.instance.analyzeText(
          text,
          matchingContext: matchingContext,
        );
      }

      final validationOutcome = await _validateAndRepair(candidate, matchingContext);

      if (!mounted) return;

      _stopAiWaitingHaptics();
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
                    regions: item.regions,
                  ),
                )
                .toList(growable: false),
            initialValidation: validationOutcome.validation,
            originalImages: _images,
            initialDate: widget.initialDate,
            initialMealType: resolvedMealType,
            depthResult: _lastDepthCapture,
            depthFacts: _lastDepthCapture?.scaleFacts,
          ),
        ),
      );
      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AiKeyMissingException {
      if (!mounted) return;
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
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
                      MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
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
            await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(context);
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          // 1. Live Camera Viewfinder (QRView)
          if (_cameraPermission.isGranted)
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: null,
            )
          else
            _buildCameraFallback(),

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

          // 3. Distance Guidance Pill below AppBar
          Positioned(
            top: kToolbarHeight + topPadding + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Text(
                  '35 cm · Optimaler Abstand',
                  style: TextStyle(
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
          if (_detectedBarcode != null)
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lime.withValues(alpha: 0.6), width: 1.5),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
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
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.14),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _textController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Mahlzeit beschreiben (z.B. 2 Eier mit Toast)...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: const Icon(LucideIcons.check, color: Colors.white, size: 18),
                                    onPressed: () => setState(() => _showTextInput = false),
                                  ),
                                ),
                                onSubmitted: (_) => setState(() => _showTextInput = false),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Shutter & Primary Action Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gallery Button
                        _buildFrostedButton(
                          icon: LucideIcons.image,
                          onTap: _pickFromGallery,
                        ),

                        // Voice Dictation Button (Microphone)
                        _buildFrostedButton(
                          icon: LucideIcons.mic,
                          isActive: _textController.text.isNotEmpty,
                          onTap: _openVoiceDictationModal,
                        ),

                        // Shutter Button (76px diameter Screen A1)
                        GestureDetector(
                          onTap: _takeShutterPhoto,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3.5),
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

                        // Text Note Toggle Button
                        _buildFrostedButton(
                          icon: LucideIcons.pencil,
                          isActive: _showTextInput || _textController.text.isNotEmpty,
                          onTap: () {
                            setState(() {
                              _showTextInput = !_showTextInput;
                            });
                          },
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
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF12120F)),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFF12120F)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: openAppSettings,
              child: const Text('Einstellungen öffnen', style: TextStyle(fontWeight: FontWeight.w700)),
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
              color: isActive ? lime.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.14),
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

  void _openVoiceDictationModal() {
    final textEditController = TextEditingController(text: _textController.text);

    showGlassBottomMenu<void>(
      context: context,
      title: 'Spracheingabe / Diktat',
      contentBuilder: (ctx, close) {
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
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9EF00).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.mic, color: Color(0xFFC9EF00), size: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mahlzeit beschreiben oder diktieren',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'z. B. „Ein Teller Gemüsedöner mit Fladenbrot und Knoblauchsauce“',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textEditController,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Diktat-Text hier eingeben oder ergänzen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppButton.primary(
              onPressed: () {
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
  }
}

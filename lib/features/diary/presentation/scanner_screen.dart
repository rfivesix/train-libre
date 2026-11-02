// lib/features/diary/presentation/scanner_screen.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../ai_assistant/presentation/ai_global_cloud_visibility.dart';
import '../../ai_assistant/presentation/widgets/cloud_overlay/header_glass_button.dart';
import '../data/sources/product_local_data_source.dart';
import '../domain/models/food_item.dart';
import 'widgets/ai_barcode_banner.dart';
import 'widgets/barcode_camera_preview_demo.dart';

/// A screen that utilizes the device camera to scan barcodes for product identification.
///
/// Uses the `qr_code_scanner_plus` package (FLOSS-compatible) to detect
/// barcodes. The user confirms a detected product from the bottom banner before
/// the code is returned to the calling screen. This is the standalone barcode
/// entrance; `AiMealCaptureScreen` detects barcodes passively on its camera.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, RouteAware {
  late final AiGlobalCloudVisibilityLease _cloudVisibilityLease;
  bool _isDone = false;
  bool _isIosSimulator = false;
  String? _detectedBarcode;
  FoodItem? _detectedProduct;
  bool _isFlashOn = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isRequestingPermission = false;
  bool _isRouteObserverAttached = false;
  bool _isTopRoute = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      if (_isTopRoute) {
        controller?.resumeCamera();
      }
    }
  }

  bool _isOffDbInitialized = false;

  Future<void> _checkDbStatus() async {
    final initialized =
        await BasisDataManager.instance.isOffDatabaseInitialized();
    if (mounted) {
      setState(() {
        _isOffDbInitialized = initialized;
      });
    }
  }

  Future<void> _detectIosSimulator() async {
    if (!Platform.isIOS) return;
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      if (mounted) {
        setState(() => _isIosSimulator = !info.isPhysicalDevice);
      }
    } catch (_) {
      // Keep the camera preview when the runtime cannot confirm a simulator.
    }
  }

  Future<void> _prepareScanner() async {
    await _detectIosSimulator();
    await _checkPermission(initial: true);
  }

  @override
  void initState() {
    super.initState();
    _cloudVisibilityLease = AiGlobalCloudVisibility.suppress();
    unawaited(
      TelemetryService.instance.trackScreenView(
        screenName: ScreenName.barcodeScanner,
      ),
    );
    _checkDbStatus();
    unawaited(_prepareScanner());
    WidgetsBinding.instance.addObserver(this);

    // Lock viewfinder strictly to Portrait mode.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    controller?.pauseCamera();
    if (_isFlashOn && mounted) {
      setState(() => _isFlashOn = false);
    }
  }

  @override
  void didPopNext() {
    _isTopRoute = true;
    controller?.resumeCamera();
  }

  @override
  void didPop() {
    _isTopRoute = false;
    controller?.pauseCamera();
    if (_isFlashOn && mounted) {
      setState(() => _isFlashOn = false);
    }
  }

  @override
  void dispose() {
    _cloudVisibilityLease.dispose();
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    // The QR controller self-disposes when the QRView is unmounted; disposing
    // it here as well is deprecated.
    WidgetsBinding.instance.removeObserver(this);
    // Restore default app orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.getFlashStatus().then((status) {
      if (mounted && status != null) {
        setState(() => _isFlashOn = status);
      }
    }).catchError((_) {});
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code;
      if (code != null && code.isNotEmpty && !_isDone) {
        developer.log(
          'Barcode detected: $code (${scanData.format})',
        );
        HapticFeedbackService.instance.confirmationFeedback();
        if (mounted) {
          setState(() {
            _isDone = true;
            _detectedBarcode = code;
            _detectedProduct = null;
          });
          unawaited(_loadDetectedProduct(code));
        }
      }
    });
  }

  Future<void> _loadDetectedProduct(String code) async {
    try {
      final product =
          await ProductLocalDataSource.instance.getProductByBarcode(code);
      if (mounted && _detectedBarcode == code && product != null) {
        setState(() => _detectedProduct = product);
      }
    } catch (_) {}
  }

  void _returnDetectedBarcode() {
    final code = _detectedBarcode;
    if (code == null) return;
    Navigator.of(context).pop(code);
  }

  Future<void> _toggleFlash() async {
    if (controller == null) return;
    HapticFeedbackService.instance.selectionFeedback();
    try {
      await controller?.toggleFlash();
      final status = await controller?.getFlashStatus();
      if (mounted) {
        setState(() {
          _isFlashOn = status ?? !_isFlashOn;
        });
      }
    } catch (e) {
      debugPrint('[ScannerScreen] toggleFlash error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission if returning from settings or another app
      _checkPermission();
      if (_isTopRoute) {
        controller?.resumeCamera();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller?.pauseCamera();
      if (_isFlashOn && mounted) {
        setState(() => _isFlashOn = false);
      }
    }
  }

  /// Reads the current camera permission status without triggering a native
  /// permission dialog. Safe to call at any point in the lifecycle.
  Future<void> _checkPermission({bool initial = false}) async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraPermissionStatus = status;
        if (initial) {
          _isCheckingPermission = false;
        }
      });
    }
  }

  /// Triggers the native camera permission dialog. Must only be called from
  /// an explicit user action (CTA button tap) so that the native QRView
  /// lifecycle is never invoked before the widget is mounted.
  Future<void> _requestPermission() async {
    if (_isRequestingPermission) return;
    if (mounted) {
      setState(() => _isRequestingPermission = true);
    }
    try {
      final result = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _cameraPermissionStatus = result;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  void _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isOffDbInitialized) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Text(
            l10n.scann_barcode_capslock,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
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

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: GlobalAppBar(title: l10n.scann_barcode_capslock),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isCheckingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraPermissionStatus.isGranted) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(48),
                child: LayoutBuilder(
                  builder: (context, previewConstraints) {
                    final previewWidth = previewConstraints.maxWidth;
                    final previewHeight = previewConstraints.maxHeight;
                    final boxWidth = previewWidth * 0.86;
                    final boxHeight = boxWidth * 0.42;
                    final left = (previewWidth - boxWidth) / 2;
                    final top = ((previewHeight - boxHeight) / 2.2)
                        .clamp(0.0, previewHeight - boxHeight);
                    final scanBox = Rect.fromLTWH(
                      left,
                      top,
                      boxWidth,
                      boxHeight,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_isIosSimulator)
                          const BarcodeCameraPreviewDemo()
                        else
                          QRView(
                            key: qrKey,
                            onQRViewCreated: _onQRViewCreated,
                            formatsAllowed: const [
                              BarcodeFormat.ean8,
                              BarcodeFormat.ean13,
                            ],
                          ),
                        CustomPaint(
                          painter: ScannerOverlayPainter(
                            scanBox: scanBox,
                            barrierColor: Colors.black.withValues(
                              alpha: 0.62,
                            ),
                            borderColor: Theme.of(context).colorScheme.primary,
                            borderRadius: 22,
                            borderWidth: 3,
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 20,
                          child: HeaderGlassButton(
                            icon: _isFlashOn
                                ? LucideIcons.zap
                                : LucideIcons.zap_off,
                            tooltip: l10n.scannerToggleFlash,
                            isDarkSurface: true,
                            platformViewBackdrop: true,
                            backgroundColor: _isFlashOn
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: _isFlashOn
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.white,
                            onPressed: _toggleFlash,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (_detectedBarcode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: AiBarcodeBanner(
                detectedBarcode: _detectedBarcode,
                detectedProduct: _detectedProduct,
                isLoggingBarcode: false,
                primaryAccent: Theme.of(context).colorScheme.primary,
                onLogBarcode: _returnDetectedBarcode,
              ),
            ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.camera, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _cameraPermissionStatus.isPermanentlyDenied
                  ? l10n.scannerPermissionPermanentlyDenied
                  : l10n.scannerPermissionRequired,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              onPressed: _isRequestingPermission
                  ? null
                  : (_cameraPermissionStatus.isPermanentlyDenied
                      ? _openSettings
                      : _requestPermission),
              label: _cameraPermissionStatus.isPermanentlyDenied
                  ? l10n.scannerOpenSettings
                  : l10n.scannerGrantPermission,
              tooltip: _cameraPermissionStatus.isPermanentlyDenied
                  ? l10n.scannerOpenSettings
                  : l10n.scannerGrantPermission,
              isLoading: _isRequestingPermission,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims the camera around the barcode target and draws a modern corner frame.
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanBox;
  final Color barrierColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;

  ScannerOverlayPainter({
    required this.scanBox,
    required this.barrierColor,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barrierColor
      ..style = PaintingStyle.fill;

    // Use Path.combine to cut out the scanBox from the full screen mask
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanBox, Radius.circular(borderRadius)),
      );
    final maskPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    canvas.drawPath(maskPath, paint);

    final markerOffset = borderWidth * 1.5;
    final frameRect = scanBox.inflate(markerOffset);

    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cornerLength = (frameRect.width * 0.085).clamp(22.0, 38.0);
    final radius = borderRadius + markerOffset;
    final corners = <Path>[
      Path()
        ..moveTo(frameRect.left, frameRect.top + radius + cornerLength)
        ..lineTo(frameRect.left, frameRect.top + radius)
        ..arcToPoint(
          Offset(frameRect.left + radius, frameRect.top),
          radius: Radius.circular(radius),
          clockwise: true,
        )
        ..lineTo(frameRect.left + radius + cornerLength, frameRect.top),
      Path()
        ..moveTo(frameRect.right - radius - cornerLength, frameRect.top)
        ..lineTo(frameRect.right - radius, frameRect.top)
        ..arcToPoint(
          Offset(frameRect.right, frameRect.top + radius),
          radius: Radius.circular(radius),
          clockwise: true,
        )
        ..lineTo(frameRect.right, frameRect.top + radius + cornerLength),
      Path()
        ..moveTo(frameRect.left, frameRect.bottom - radius - cornerLength)
        ..lineTo(frameRect.left, frameRect.bottom - radius)
        ..arcToPoint(
          Offset(frameRect.left + radius, frameRect.bottom),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(frameRect.left + radius + cornerLength, frameRect.bottom),
      Path()
        ..moveTo(frameRect.right - radius - cornerLength, frameRect.bottom)
        ..lineTo(frameRect.right - radius, frameRect.bottom)
        ..arcToPoint(
          Offset(frameRect.right, frameRect.bottom - radius),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(frameRect.right, frameRect.bottom - radius - cornerLength),
    ];
    for (final corner in corners) {
      canvas.drawPath(corner, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanBox != scanBox ||
        oldDelegate.barrierColor != barrierColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}

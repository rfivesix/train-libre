// lib/features/diary/presentation/scanner_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../generated/app_localizations.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:developer' as developer;
import '../../../services/haptic_feedback_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../widgets/common/database_placeholder_widget.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';

/// A screen that utilizes the device camera to scan barcodes for product identification.
///
/// Uses the `qr_code_scanner_plus` package (FLOSS-compatible) to detect
/// barcodes and returns the first successfully scanned code to the calling
/// screen. This is the standalone barcode entrance; `AiMealCaptureScreen`
/// additionally detects barcodes passively on its unified camera session.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  bool _isDone = false;
  bool _isFlashOn = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isRequestingPermission = false;
  bool _isRouteObserverAttached = false;
  bool _isTopRoute = true;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

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

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.barcodeScanner));
    _checkDbStatus();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission(initial: true);

    // Lock viewfinder strictly to Portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize looping laser sweep animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
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
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    // The QR controller self-disposes when the QRView is unmounted; disposing
    // it here as well is deprecated.
    _animationController.dispose();
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
      if (scanData.code != null && !_isDone) {
        developer
            .log('Barcode detected: ${scanData.code} (${scanData.format})');
        HapticFeedbackService.instance.confirmationFeedback();
        if (mounted) {
          setState(() {
            _isDone = true;
          });
          Navigator.of(context).pop(scanData.code);
        }
      }
    });
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Text(
            l10n.scann_barcode_capslock,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (_cameraPermissionStatus.isGranted)
              IconButton(
                icon: Icon(
                  _isFlashOn ? LucideIcons.zap : LucideIcons.zap_off,
                  size: 20,
                  color: _isFlashOn
                      ? (isDark
                          ? const Color(0xFFC9EF00)
                          : Theme.of(context).colorScheme.primary)
                      : null,
                ),
                tooltip: l10n.scannerToggleFlash,
                onPressed: _toggleFlash,
              ),
          ],
        ),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isCheckingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraPermissionStatus.isGranted) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Compute scan target box size and position dynamically
          final boxWidth = screenWidth * 0.8;
          final boxHeight =
              boxWidth * 0.45; // Optimal aspect ratio for barcodes
          final left = (screenWidth - boxWidth) / 2;
          final top = (screenHeight - boxHeight) /
              2.2; // Optically balanced slightly above center

          final scanBox = Rect.fromLTWH(left, top, boxWidth, boxHeight);

          return Stack(
            children: [
              // 1. Scanner Camera View
              Positioned.fill(
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  formatsAllowed: const [
                    BarcodeFormat.ean8,
                    BarcodeFormat.ean13
                  ],
                ),
              ),

              // 2. Custom Translucent Mask Overlay with transparent cutout
              Positioned.fill(
                child: CustomPaint(
                  painter: ScannerOverlayPainter(
                    scanBox: scanBox,
                    barrierColor: Colors.black.withValues(alpha: 0.65),
                    borderColor: Theme.of(context)
                        .colorScheme
                        .primary, // Sleek primary brand border
                    borderRadius: 16.0,
                    borderWidth: 2.5,
                  ),
                ),
              ),

              // 3. Sweeping red laser line
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final currentTop = top + (boxHeight * _animation.value);
                  return Positioned(
                    top: currentTop,
                    left: left + 12,
                    width: boxWidth - 24,
                    height: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DesignConstants.brandRedColor,
                        boxShadow: [
                          BoxShadow(
                            color: DesignConstants.brandRedColor
                                .withValues(alpha: 0.8),
                            blurRadius: 6,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Guided instructions at the bottom of the scan frame
              Positioned(
                top: top + boxHeight + 36,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.scann_barcode_capslock,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.scannerAlignInstruction,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

/// A custom painter that draws a dark semi-transparent mask with a cleared centered cutout.
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
          RRect.fromRectAndRadius(scanBox, Radius.circular(borderRadius)));
    final maskPath =
        Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(maskPath, paint);

    // Draw the rounded border around the transparent cutout
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanBox, Radius.circular(borderRadius)),
      borderPaint,
    );
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

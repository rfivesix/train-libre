import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../domain/models/food_item.dart';

/// Type alias for [FoodItem] allowing compatibility with Product naming.
typedef Product = FoodItem;

/// Barcode banner displayed when a barcode is actively detected by the scanner.
class AiBarcodeBanner extends StatelessWidget {
  const AiBarcodeBanner({
    super.key,
    required this.detectedBarcode,
    this.detectedProduct,
    required this.isLoggingBarcode,
    required this.onLogBarcode,
    required this.primaryAccent,
  });

  final String? detectedBarcode;
  final Product? detectedProduct;
  final bool isLoggingBarcode;
  final VoidCallback onLogBarcode;
  final Color primaryAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final label = detectedProduct?.name ??
        (detectedBarcode != null
            ? l10n.aiCaptureBarcodeFallback(detectedBarcode!)
            : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFE8),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoggingBarcode ? null : onLogBarcode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryAccent.withValues(alpha: 0.8),
                width: 2,
              ),
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
                  child: isLoggingBarcode
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
}

/// Demo barcode banner displayed during interactive onboarding tour step 1.
class AiDemoBarcodeBanner extends StatelessWidget {
  const AiDemoBarcodeBanner({
    super.key,
    this.bannerKey,
    required this.primaryAccent,
  });

  final GlobalKey? bannerKey;
  final Color primaryAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Material(
        key: bannerKey,
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
}

// lib/features/diary/presentation/widgets/meal_photo_overlay_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../depth_scan/domain/models/item_region.dart';

class OverlayItemDisplay {
  final String name;
  final int grams;
  final int kcal;
  final List<ItemRegion> regions;
  final Color color;
  final String? pieceBadge;

  const OverlayItemDisplay({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.regions,
    required this.color,
    this.pieceBadge,
  });
}

/// Palette for organic overlay blobs in Review & Details screens.
class MealOverlayColors {
  static const Color orange = Color(0xFFFFA854);
  static const Color blue = Color(0xFF72CBFF);
  static const Color green = Color(0xFFA8E868);
  static const Color yellow = Color(0xFFFFD043);
  static const Color purple = Color(0xFFC58BE8);
  static const Color selectedBorder = Color(0xFF3FAEF0);

  static const List<Color> palette = [
    orange,
    blue,
    green,
    yellow,
    purple,
  ];

  static Color forIndex(int index) => palette[index % palette.length];
}

/// Widget displaying a meal photo (or multi-photo carousel) with organic soft region blobs,
/// leader lines, and floating frosted-glass labels.
class MealPhotoOverlayWidget extends StatefulWidget {
  final File? photoFile;
  final List<File> photoFiles;
  final String? photoUrl;
  final double height;
  final List<OverlayItemDisplay> items;
  final int? selectedIndex;
  final ValueChanged<int?>? onItemTapped;
  final Widget? emptyPlaceholder;
  final Widget? headerLeading;
  final Widget? headerTrailing;
  final Widget? bottomContent;

  const MealPhotoOverlayWidget({
    super.key,
    this.photoFile,
    this.photoFiles = const [],
    this.photoUrl,
    this.height = 318,
    this.items = const [],
    this.selectedIndex,
    this.onItemTapped,
    this.emptyPlaceholder,
    this.headerLeading,
    this.headerTrailing,
    this.bottomContent,
  });

  @override
  State<MealPhotoOverlayWidget> createState() => _MealPhotoOverlayWidgetState();
}

class _MealPhotoOverlayWidgetState extends State<MealPhotoOverlayWidget> {
  late final PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<File> get _allFiles {
    if (widget.photoFiles.isNotEmpty) return widget.photoFiles;
    if (widget.photoFile != null) return [widget.photoFile!];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final files = _allFiles;
    final hasMultiple = files.length > 1;
    final hasValidRegions = widget.items.where((it) => it.regions.isNotEmpty).length >= 2;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(19),
        topRight: Radius.circular(19),
      ),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo Background: Carousel if multiple, single if 1
            if (hasMultiple)
              PageView.builder(
                controller: _pageController,
                itemCount: files.length,
                onPageChanged: (idx) => setState(() => _activePage = idx),
                itemBuilder: (context, idx) {
                  return Image.file(
                    files[idx],
                    fit: BoxFit.cover,
                  );
                },
              )
            else if (files.isNotEmpty && files.first.existsSync())
              Image.file(
                files.first,
                fit: BoxFit.cover,
              )
            else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
              Image.network(
                widget.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderBackground(context),
              )
            else
              _buildPlaceholderBackground(context),

            // Top & Bottom Subtle Gradients for clean contrast and seamless blend
            Positioned.fill(
              child: IgnorePointer(
                child: Column(
                  children: [
                    Container(
                      height: 80,
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
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).scaffoldBackgroundColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Organic Regions & Leader Lines (on primary photo)
            if (hasValidRegions && _activePage == 0)
              LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _OrganicOverlayPainter(
                      items: widget.items,
                      selectedIndex: widget.selectedIndex,
                    ),
                  );
                },
              ),

            // Interactive Floating Label Pills
            if (hasValidRegions && _activePage == 0)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: _buildFloatingLabels(constraints.biggest),
                  );
                },
              ),

            // Carousel Page Indicators (if multiple photos)
            if (hasMultiple)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(files.length, (idx) {
                    final isActive = idx == _activePage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFC9EF00)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // Header Elements (Back button, menu, etc.)
            if (widget.headerLeading != null || widget.headerTrailing != null)
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.headerLeading ?? const SizedBox.shrink(),
                    widget.headerTrailing ?? const SizedBox.shrink(),
                  ],
                ),
              ),

            // Bottom Content overlay (e.g. quick macro pills)
            if (widget.bottomContent != null)
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: widget.bottomContent!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1F1F1E) : const Color(0xFFE8E8E0),
      child: Center(
        child: widget.emptyPlaceholder ??
            Text(
              'KEIN FOTO VORHANDEN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF7E7E74) : const Color(0xFF9A9A90),
              ),
            ),
      ),
    );
  }

  List<Widget> _buildFloatingLabels(Size canvasSize) {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item.regions.isEmpty) continue;

      final isSelected = widget.selectedIndex == i;
      final region = item.regions.first;
      final pillCenter = _resolvePillPosition(region, canvasSize, i, widget.items.length);

      widgets.add(
        Positioned(
          left: pillCenter.dx - 45,
          top: pillCenter.dy - 16,
          child: GestureDetector(
            onTap: () => widget.onItemTapped?.call(isSelected ? null : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? MealOverlayColors.selectedBorder : Colors.white24,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MealOverlayColors.selectedBorder.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.grams}g',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Offset _resolvePillPosition(ItemRegion region, Size size, int index, int total) {
    final cx = (region.x + region.width / 2) * size.width;
    final cy = (region.y + region.height / 2) * size.height;

    final side = index % 2 == 0 ? -1 : 1;
    final offsetX = side * (region.width * size.width * 0.45 + 30);
    final offsetY = (index % 3 - 1) * 20.0;

    final px = (cx + offsetX).clamp(50.0, size.width - 50.0);
    final py = (cy + offsetY).clamp(40.0, size.height - 40.0);

    return Offset(px, py);
  }
}

class _OrganicOverlayPainter extends CustomPainter {
  final List<OverlayItemDisplay> items;
  final int? selectedIndex;

  _OrganicOverlayPainter({
    required this.items,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.regions.isEmpty) continue;

      final isSelected = selectedIndex == i;
      final region = item.regions.first;

      final rect = Rect.fromLTWH(
        region.x * size.width,
        region.y * size.height,
        region.width * size.width,
        region.height * size.height,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(19));

      // 1. Soft semi-transparent organic fill
      final fillPaint = Paint()
        ..color = item.color.withValues(alpha: isSelected ? 0.35 : 0.20)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);

      // 2. Organic contour stroke
      final strokePaint = Paint()
        ..color = isSelected
            ? MealOverlayColors.selectedBorder
            : item.color.withValues(alpha: 0.65)
        ..strokeWidth = isSelected ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, strokePaint);

      // 3. Leader Line to pill anchor
      final side = i % 2 == 0 ? -1 : 1;
      final offsetX = side * (region.width * size.width * 0.45 + 30);
      final offsetY = (i % 3 - 1) * 20.0;

      final p1 = Offset(rect.center.dx, rect.center.dy);
      final p2 = Offset(
        (rect.center.dx + offsetX).clamp(50.0, size.width - 50.0),
        (rect.center.dy + offsetY).clamp(40.0, size.height - 40.0),
      );

      final linePaint = Paint()
        ..color = isSelected ? MealOverlayColors.selectedBorder : Colors.white38
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, linePaint);

      // Small anchor dot at region center
      final dotPaint = Paint()
        ..color = isSelected ? MealOverlayColors.selectedBorder : item.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p1, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicOverlayPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.items != items;
  }
}

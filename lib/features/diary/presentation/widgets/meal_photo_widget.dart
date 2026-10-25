import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../util/design_constants.dart';

/// The photo of a meal — one image, a swipeable carousel when a capture
/// produced several, or a LiDAR depth map.
class MealPhotoWidget extends StatefulWidget {
  final File? photoFile;
  final List<File> photoFiles;
  final String? photoUrl;
  final ui.Image? depthImage;
  final Map<int, ui.Image>? depthImages;
  final Widget? overlayTrailing;
  final double height;

  /// Rounds the top corners. Defaults to false because the photo runs
  /// full-bleed under a transparent app bar.
  final bool roundedTop;

  /// Rounds all four corners when the photo is shown as a standalone card.
  final bool roundedAll;

  /// Whether to smoothly fade out the bottom of the photo into transparency.
  final bool fadeBottom;

  /// Image fitting inside the shared photo frame.
  final BoxFit imageFit;

  /// Parent scroll offset used for the slower-than-content parallax.
  final ValueListenable<double>? scrollOffset;

  /// Uses the smallest source photo as the carousel's common aspect ratio.
  /// Other photos are cropped to that frame while the reference photo remains
  /// fully visible.
  final bool matchSmallestPhotoAspectRatio;

  /// Reports the resolved frame height so the parent can pin content at the
  /// correct scroll position after image dimensions are known.
  final ValueChanged<double>? onHeightChanged;

  final ValueChanged<int>? onPageChanged;

  const MealPhotoWidget({
    super.key,
    this.photoFile,
    this.photoFiles = const [],
    this.photoUrl,
    this.depthImage,
    this.depthImages,
    this.overlayTrailing,
    this.onPageChanged,
    this.height = 280,
    this.roundedTop = false,
    this.roundedAll = false,
    this.fadeBottom = true,
    this.imageFit = BoxFit.cover,
    this.scrollOffset,
    this.matchSmallestPhotoAspectRatio = false,
    this.onHeightChanged,
  });

  @override
  State<MealPhotoWidget> createState() => _MealPhotoWidgetState();
}

class _MealPhotoWidgetState extends State<MealPhotoWidget> {
  late final PageController _pageController;
  int _activePage = 0;
  double? _smallestPhotoAspectRatio;
  double _lastReportedHeight = -1;
  String _loadedPhotoPaths = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPhotoAspectRatio();
  }

  @override
  void didUpdateWidget(covariant MealPhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final paths = _allFiles.map((file) => file.path).join('|');
    if (paths != _loadedPhotoPaths) _loadPhotoAspectRatio();
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

  Future<void> _loadPhotoAspectRatio() async {
    final files = _allFiles.where((file) => file.existsSync()).toList();
    _loadedPhotoPaths = files.map((file) => file.path).join('|');
    if (!widget.matchSmallestPhotoAspectRatio || files.isEmpty) {
      if (_smallestPhotoAspectRatio != null && mounted) {
        setState(() => _smallestPhotoAspectRatio = null);
      }
      return;
    }

    var smallestArea = double.infinity;
    double? smallestAspectRatio;
    for (final file in files) {
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      try {
        buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        final area = descriptor.width * descriptor.height;
        if (area < smallestArea && descriptor.height > 0) {
          smallestArea = area.toDouble();
          smallestAspectRatio = descriptor.width / descriptor.height;
        }
      } catch (_) {
        // A missing or unsupported image should not prevent meal review.
      } finally {
        descriptor?.dispose();
        buffer?.dispose();
      }
    }
    if (mounted && smallestAspectRatio != null) {
      setState(() => _smallestPhotoAspectRatio = smallestAspectRatio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = _allFiles;
    final hasMultiple = files.length > 1;
    final referenceAspectRatio = _smallestPhotoAspectRatio;
    final frameHeight =
        widget.matchSmallestPhotoAspectRatio && referenceAspectRatio != null
            ? MediaQuery.sizeOf(context).width / referenceAspectRatio
            : widget.height;
    final effectiveFit =
        widget.matchSmallestPhotoAspectRatio && referenceAspectRatio != null
            ? BoxFit.cover
            : widget.imageFit;
    if ((frameHeight - _lastReportedHeight).abs() > 0.5) {
      _lastReportedHeight = frameHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHeightChanged?.call(frameHeight);
      });
    }

    Widget imageLayer = Stack(
      fit: StackFit.expand,
      children: [
        if (hasMultiple)
          PageView.builder(
            controller: _pageController,
            itemCount: files.length,
            onPageChanged: (idx) {
              setState(() => _activePage = idx);
              widget.onPageChanged?.call(idx);
            },
            itemBuilder: (context, idx) {
              final depth = widget.depthImages?[idx] ??
                  (idx == 0 ? widget.depthImage : null);
              if (depth != null) {
                return RawImage(
                  image: depth,
                  fit: effectiveFit,
                  width: double.infinity,
                  height: double.infinity,
                );
              }
              return Image.file(files[idx], fit: effectiveFit);
            },
          )
        else if (widget.depthImage != null)
          RawImage(
            image: widget.depthImage,
            fit: effectiveFit,
            width: double.infinity,
            height: double.infinity,
          )
        else if (files.isNotEmpty && files.first.existsSync())
          Image.file(files.first, fit: effectiveFit)
        else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
          Image.network(
            widget.photoUrl!,
            fit: effectiveFit,
            errorBuilder: (_, __, ___) => _buildPlaceholderBackground(context),
          )
        else
          _buildPlaceholderBackground(context),
      ],
    );

    if (widget.fadeBottom) {
      imageLayer = ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black,
              Colors.black87,
              Colors.transparent,
            ],
            stops: [0.0, 0.50, 0.78, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: imageLayer,
      );
    }

    final parallaxLayer = widget.scrollOffset == null
        ? imageLayer
        : ValueListenableBuilder<double>(
            valueListenable: widget.scrollOffset!,
            child: imageLayer,
            builder: (context, offset, child) {
              final fade = (1 - offset / (frameHeight * 1.8)).clamp(0.0, 1.0);
              return Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(0, offset * 0.45),
                  child: SizedBox(
                    height: frameHeight,
                    width: double.infinity,
                    child: child,
                  ),
                ),
              );
            },
          );

    return ClipRRect(
      borderRadius: widget.roundedAll
          ? BorderRadius.circular(24)
          : widget.roundedTop
              ? const BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                )
              : BorderRadius.zero,
      child: SizedBox(
        height: frameHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            parallaxLayer,
            if (widget.overlayTrailing != null)
              Positioned(
                top: 12,
                right: 16,
                child: widget.overlayTrailing!,
              ),
            if (hasMultiple)
              Positioned(
                bottom: 42,
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
                            ? DesignConstants.brandAccentColor
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1A1A18) : const Color(0xFFE8E8E0),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.utensils,
        size: 42,
        color: isDark ? const Color(0xFF7E7E74) : const Color(0xFF9A9A90),
      ),
    );
  }
}

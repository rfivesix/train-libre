import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

  /// Whether to smoothly fade out the bottom of the photo into transparency.
  final bool fadeBottom;

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
    this.fadeBottom = true,
  });

  @override
  State<MealPhotoWidget> createState() => _MealPhotoWidgetState();
}

class _MealPhotoWidgetState extends State<MealPhotoWidget> {
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
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              }
              return Image.file(files[idx], fit: BoxFit.cover);
            },
          )
        else if (widget.depthImage != null)
          RawImage(
            image: widget.depthImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        else if (files.isNotEmpty && files.first.existsSync())
          Image.file(files.first, fit: BoxFit.cover)
        else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
          Image.network(
            widget.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildPlaceholderBackground(context),
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

    return ClipRRect(
      borderRadius: widget.roundedTop
          ? const BorderRadius.only(
              topLeft: Radius.circular(19),
              topRight: Radius.circular(19),
            )
          : BorderRadius.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageLayer,

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
                            ? const Color(0xFFC9EF00)
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
        Icons.restaurant,
        size: 42,
        color: isDark ? const Color(0xFF7E7E74) : const Color(0xFF9A9A90),
      ),
    );
  }
}

// lib/features/diary/presentation/widgets/meal_photo_widget.dart

import 'dart:io';

import 'package:flutter/material.dart';

/// The photo of a meal — one image, or a swipeable carousel when a capture
/// produced several.
///
/// This used to also annotate the individual foods: coloured regions first,
/// then numbered pins. Both were dropped. The coordinates a vision model
/// returns for the parts of a meal are not dependable enough to draw on a
/// photo, and an annotation that is confidently in the wrong place is worse
/// than none at all. The photo now simply shows what was eaten.
class MealPhotoWidget extends StatefulWidget {
  final File? photoFile;
  final List<File> photoFiles;
  final String? photoUrl;
  final double height;

  /// Rounds the top corners. Off when the photo runs full-bleed under a
  /// transparent app bar, where rounded corners would cut into the status bar.
  final bool roundedTop;

  const MealPhotoWidget({
    super.key,
    this.photoFile,
    this.photoFiles = const [],
    this.photoUrl,
    this.height = 318,
    this.roundedTop = true,
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
            if (hasMultiple)
              PageView.builder(
                controller: _pageController,
                itemCount: files.length,
                onPageChanged: (idx) => setState(() => _activePage = idx),
                itemBuilder: (context, idx) =>
                    Image.file(files[idx], fit: BoxFit.cover),
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

            // Top and bottom gradients so an app bar above and the content
            // below both stay legible over any photo.
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
                          colors: [Color(0xCC000000), Colors.transparent],
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

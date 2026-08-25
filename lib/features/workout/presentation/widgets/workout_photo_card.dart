import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../data/sources/workout_local_data_source.dart';
import '../../data/workout_photo_store.dart';

/// A 1:1 aspect ratio card displaying workout photos in a carousel,
/// with support for adding up to 4 photos via direct camera capture or gallery picker,
/// deleting existing photos, and displaying a dashed empty state when no photos are present.
class WorkoutPhotoCard extends StatefulWidget {
  final int? workoutLogId;
  final List<String> photoPaths;
  final bool isEditable;
  final ValueChanged<List<String>>? onPhotosChanged;

  const WorkoutPhotoCard({
    super.key,
    this.workoutLogId,
    required this.photoPaths,
    this.isEditable = true,
    this.onPhotosChanged,
  });

  @override
  State<WorkoutPhotoCard> createState() => _WorkoutPhotoCardState();
}

class _WorkoutPhotoCardState extends State<WorkoutPhotoCard> {
  late final PageController _pageController;
  int _activePage = 0;
  bool _isProcessing = false;

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

  List<File> _resolveFiles() {
    final files = <File>[];
    for (final path in widget.photoPaths) {
      final file = WorkoutPhotoStore.instance.resolveSync(path);
      if (file != null && file.existsSync()) {
        files.add(file);
        continue;
      }
      final thumb = WorkoutPhotoStore.instance
          .resolveSync(WorkoutPhotoStore.thumbPathFor(path));
      if (thumb != null && thumb.existsSync()) {
        files.add(thumb);
      }
    }
    return files;
  }

  Future<void> _takePhoto() async {
    if (_isProcessing ||
        widget.photoPaths.length >= WorkoutPhotoStore.maxPhotos) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (photo == null || !mounted) return;

      final file = File(photo.path);
      final stored = await WorkoutPhotoStore.instance.save(file);
      if (stored == null || !mounted) return;

      final updated = List<String>.from(widget.photoPaths)
        ..add(stored.photoPath);
      if (widget.workoutLogId != null) {
        await WorkoutLocalDataSource.instance.updateWorkoutLogPhotos(
          widget.workoutLogId!,
          updated,
        );
      }
      widget.onPhotosChanged?.call(updated);
      if (updated.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              updated.length - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = WorkoutPhotoStore.maxPhotos - widget.photoPaths.length;
    if (_isProcessing || remaining <= 0) return;

    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (picked.isEmpty || !mounted) return;

      final toSave = picked.take(remaining);
      final newPaths = <String>[];
      for (final xFile in toSave) {
        final file = File(xFile.path);
        final stored = await WorkoutPhotoStore.instance.save(file);
        if (stored != null) {
          newPaths.add(stored.photoPath);
        }
      }
      if (newPaths.isEmpty || !mounted) return;

      final updated = List<String>.from(widget.photoPaths)..addAll(newPaths);
      if (widget.workoutLogId != null) {
        await WorkoutLocalDataSource.instance.updateWorkoutLogPhotos(
          widget.workoutLogId!,
          updated,
        );
      }
      widget.onPhotosChanged?.call(updated);
      if (updated.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              updated.length - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDeletePhoto(int index) async {
    if (index < 0 || index >= widget.photoPaths.length) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutPhotoRemove),
        content: Text(l10n.workoutPhotoRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final pathToDelete = widget.photoPaths[index];
    final updated = List<String>.from(widget.photoPaths)..removeAt(index);

    await WorkoutPhotoStore.instance.delete(
      photoPath: pathToDelete,
      thumbPath: WorkoutPhotoStore.thumbPathFor(pathToDelete),
    );

    if (widget.workoutLogId != null) {
      await WorkoutLocalDataSource.instance.updateWorkoutLogPhotos(
        widget.workoutLogId!,
        updated,
      );
    }

    if (_activePage >= updated.length && updated.isNotEmpty) {
      setState(() => _activePage = updated.length - 1);
    }

    widget.onPhotosChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final files = _resolveFiles();

    if (widget.photoPaths.isEmpty) {
      if (!widget.isEditable) {
        return const SizedBox.shrink();
      }
      return _buildEmptyState(context, l10n, theme);
    }

    final hasMultiple = files.length > 1;
    final canAddMore = widget.isEditable &&
        widget.photoPaths.length < WorkoutPhotoStore.maxPhotos;

    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Carousel or single image
            if (hasMultiple)
              PageView.builder(
                controller: _pageController,
                itemCount: files.length,
                onPageChanged: (idx) => setState(() => _activePage = idx),
                itemBuilder: (context, idx) {
                  return Image.file(
                    files[idx],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              )
            else if (files.isNotEmpty)
              Image.file(
                files.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.image,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            // Top right: Delete button
            if (widget.isEditable && files.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: _buildActionButton(
                  icon: LucideIcons.trash_2,
                  tooltip: l10n.workoutPhotoRemove,
                  onTap: () => _confirmDeletePhoto(_activePage),
                  isDestructive: true,
                ),
              ),

            // Bottom center: Dots indicator
            if (hasMultiple)
              Positioned(
                bottom: 14,
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

            // Bottom right: Add photos buttons (Camera + Gallery)
            if (canAddMore)
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.camera,
                      tooltip: l10n.workoutPhotoTake,
                      onTap: _takePhoto,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: LucideIcons.image,
                      tooltip: l10n.workoutPhotoFromLibrary,
                      onTap: _pickFromGallery,
                    ),
                  ],
                ),
              ),

            // Progress indicator overlay
            if (_isProcessing)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.2);
    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          strokeWidth: 1.5,
          radius: DesignConstants.borderRadiusM,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          child: Material(
            color: cardBg,
            child: InkWell(
              onTap: _takePhoto,
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const CircularProgressIndicator()
                    else ...[
                      Icon(
                        LucideIcons.camera,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      Text(
                        l10n.workoutPhotoTake,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignConstants.spacingM),
                      FilledButton.tonalIcon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(LucideIcons.image, size: 18),
                        label: Text(l10n.workoutPhotoFromLibrary),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.spacingM,
                            vertical: DesignConstants.spacingS,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(
            icon,
            size: 20,
            color: isDestructive ? const Color(0xFFFF6B6B) : Colors.white,
          ),
          tooltip: tooltip,
          onPressed: _isProcessing ? null : onTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dash = 6.0;
  static const double _gap = 4.0;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(_dash, metric.length - distance);
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}

import 'dart:io';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../data/sources/workout_local_data_source.dart';
import '../../data/workout_photo_store.dart';

/// A card displaying workout photos:
/// - In edit mode: inside a [SummaryCard] with header, actions, and delete button.
/// - In view mode: clean full-width squircle photo carousel without outer card borders or redundant headers.
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

    final confirm = await showDeleteConfirmation(
      context,
      title: l10n.workoutPhotoRemove,
      content: l10n.workoutPhotoRemoveConfirm,
      confirmLabel: l10n.delete,
    );

    if (!confirm || !mounted) return;

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

    if (files.isEmpty) {
      if (!widget.isEditable) {
        return const SizedBox.shrink();
      }
      return SummaryCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        child: Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                icon: LucideIcons.camera,
                label: l10n.workoutPhotoTake,
                tooltip: l10n.workoutPhotoTake,
                size: AppButtonSize.medium,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : _takePhoto,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(
              child: AppButton.secondary(
                icon: LucideIcons.image,
                label: l10n.workoutPhotoFromLibrary,
                tooltip: l10n.workoutPhotoFromLibrary,
                size: AppButtonSize.medium,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : _pickFromGallery,
              ),
            ),
          ],
        ),
      );
    }

    final hasMultiple = files.length > 1;
    final canAddMore = widget.isEditable &&
        widget.photoPaths.length < WorkoutPhotoStore.maxPhotos;
    final isDark = theme.brightness == Brightness.dark;

    final squircleRadius = SmoothBorderRadius(
      cornerRadius: DesignConstants.borderRadiusL,
      cornerSmoothing: 0.6,
    );
    final squircle = SmoothRectangleBorder(borderRadius: squircleRadius);
    final clipper = ShapeBorderClipper(shape: squircle);

    final photoWidget = AspectRatio(
      aspectRatio: 1.0,
      child: ClipPath(
        clipper: clipper,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: ClipPath(
            clipper: clipper,
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                else
                  Image.file(
                    files.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),

                // Top badge: counter inside the image (top-left in all modes)
                if (hasMultiple)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        l10n.workoutPhotoPagination(
                          _activePage + 1,
                          files.length,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Top right: Delete button inside the image (in edit mode)
                if (widget.isEditable)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.trash,
                            size: 16,
                            color: Color(0xFFFF6B6B),
                          ),
                          tooltip: l10n.workoutPhotoRemove,
                          onPressed: _isProcessing
                              ? null
                              : () => _confirmDeletePhoto(_activePage),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Dot indicators at bottom center
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
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

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
        ),
      ),
    );

    if (!canAddMore) {
      return photoWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        photoWidget,
        const SizedBox(height: DesignConstants.spacingS),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                icon: LucideIcons.camera,
                label: l10n.workoutPhotoTake,
                tooltip: l10n.workoutPhotoTake,
                size: AppButtonSize.medium,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : _takePhoto,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(
              child: AppButton.secondary(
                icon: LucideIcons.image,
                label: l10n.workoutPhotoFromLibrary,
                tooltip: l10n.workoutPhotoFromLibrary,
                size: AppButtonSize.medium,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : _pickFromGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

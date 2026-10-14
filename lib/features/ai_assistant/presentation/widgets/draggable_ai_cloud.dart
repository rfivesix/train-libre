import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../util/design_constants.dart';
import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

/// The existing animated AI cloud, made draggable for the overlay demo.
///
/// Its horizontal and vertical position is interactive and resets when the
/// demo screen is opened again.
class DraggableAiCloud extends StatefulWidget {
  final String semanticLabel;
  final String semanticHint;
  final double liveliness;
  final ValueChanged<bool>? onFullscreenChanged;
  final bool showResizeHandles;

  const DraggableAiCloud({
    super.key,
    required this.semanticLabel,
    required this.semanticHint,
    required this.liveliness,
    this.onFullscreenChanged,
    this.showResizeHandles = true,
  });

  @override
  State<DraggableAiCloud> createState() => _DraggableAiCloudState();
}

class _DraggableAiCloudState extends State<DraggableAiCloud>
    with TickerProviderStateMixin {
  static const _horizontalInset = DesignConstants.spacingL;
  static const _cloudSize = 160.0;
  static const _visibleEdge = 64.0;
  static const _topGap = 2.0;
  static const _topVisualInset = 28.0;
  // Release within this many logical pixels of a card edge docks the cloud.
  static const _snapThreshold = 48.0;
  static const _demoWords = <String>[
    'Lorem',
    'ipsum',
    'dolor',
    'sit',
    'amet,',
    'consectetur',
    'adipiscing',
    'elit,',
    'sed',
    'do',
    'eiusmod',
    'tempor',
    'incididunt',
    'ut',
    'labore',
    'et',
    'dolore',
    'magna',
    'aliqua.',
  ];

  double? _horizontalPosition;
  double? _verticalPosition;
  double _rotationRadians = 0;
  double _scale = 1;
  bool _isDragging = false;
  bool _isExpanded = false;
  bool _showChatPreview = false;
  bool _isFullscreen = false;
  double _headerDragDistance = 0;
  double _headerDragStartProgress = 1;
  final _chatInputController = TextEditingController();
  final _chatFocusNode = FocusNode();
  final _chatScrollController = ScrollController();
  final List<_DemoChatTurn> _chatTurns = [];
  Timer? _responseTimer;
  bool _isGenerating = false;
  bool _followChatTail = true;
  int _demoWordIndex = 0;
  double _safeLeft = 0.14;
  double _safeTop = 0.10;
  double _safeRight = 0.86;
  double _safeBottom = 0.90;
  AnimationController? _morphController;
  AnimationController? _fullscreenController;

  AnimationController get _morphAnimation =>
      _morphController ??= AnimationController(
          vsync: this, duration: const Duration(milliseconds: 760));

  AnimationController get _fullscreenAnimation =>
      _fullscreenController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      )..addListener(_onFullscreenAnimationTick);

  @override
  void initState() {
    super.initState();
    _chatScrollController.addListener(_handleChatScroll);
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _chatInputController.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    _morphController?.dispose();
    _fullscreenController?.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final expanding = !_isExpanded;
    final wasFullscreen = _isFullscreen;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isExpanded = expanding;
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
      _isFullscreen = false;
      _showChatPreview = expanding;
      if (!expanding) {
        _responseTimer?.cancel();
        _responseTimer = null;
        _isGenerating = false;
      }
    });
    if (expanding) {
      widget.onFullscreenChanged?.call(false);
      _morphAnimation.forward();
      if (_chatTurns.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isExpanded && _showChatPreview) {
            _chatFocusNode.requestFocus();
          }
        });
      }
    } else {
      _morphAnimation.reverse().whenComplete(() {
        if (mounted) widget.onFullscreenChanged?.call(false);
      });
    }
    if (wasFullscreen) {
      _fullscreenAnimation.reverse();
    }
  }

  void _onFullscreenAnimationTick() {
    if (mounted) setState(() {});
  }

  void _toggleFullscreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    final expand = !_isFullscreen;
    setState(() {
      _isFullscreen = expand;
      if (expand) {
        _isExpanded = true;
        _showChatPreview = true;
      }
    });
    if (expand) {
      widget.onFullscreenChanged?.call(true);
      _morphAnimation.forward();
      _fullscreenAnimation.forward(from: _fullscreenAnimation.value);
    } else {
      _fullscreenAnimation.reverse().whenComplete(() {
        if (mounted) widget.onFullscreenChanged?.call(false);
      });
    }
  }

  void _handleHeaderDragStart(DragStartDetails details) {
    _headerDragDistance = 0;
    _headerDragStartProgress = _morphAnimation.value;
    _morphAnimation.stop();
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    _headerDragDistance += details.delta.dy;
    _morphAnimation.value =
        (_headerDragStartProgress - _headerDragDistance / 250).clamp(0.0, 1.0);
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    final shouldCollapse = _morphAnimation.value < 0.55 ||
        details.velocity.pixelsPerSecond.dy > 900;
    if (shouldCollapse) {
      _toggleExpanded();
    } else {
      _morphAnimation.forward();
    }
    _headerDragDistance = 0;
  }

  void _resizeSafeSpace(
    _SafeSpaceCorner corner,
    DragUpdateDetails details,
    Size size,
  ) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    const minWidth = 0.34;
    const minHeight = 0.42;
    const edgeInset = 0.04;

    setState(() {
      switch (corner) {
        case _SafeSpaceCorner.topLeft:
          _safeLeft = (_safeLeft + dx)
              .clamp(edgeInset, _safeRight - minWidth)
              .toDouble();
          _safeTop = (_safeTop + dy)
              .clamp(edgeInset, _safeBottom - minHeight)
              .toDouble();
        case _SafeSpaceCorner.topRight:
          _safeRight = (_safeRight + dx)
              .clamp(_safeLeft + minWidth, 1 - edgeInset)
              .toDouble();
          _safeTop = (_safeTop + dy)
              .clamp(edgeInset, _safeBottom - minHeight)
              .toDouble();
        case _SafeSpaceCorner.bottomLeft:
          _safeLeft = (_safeLeft + dx)
              .clamp(edgeInset, _safeRight - minWidth)
              .toDouble();
          _safeBottom = (_safeBottom + dy)
              .clamp(_safeTop + minHeight, 1 - edgeInset)
              .toDouble();
        case _SafeSpaceCorner.bottomRight:
          _safeRight = (_safeRight + dx)
              .clamp(_safeLeft + minWidth, 1 - edgeInset)
              .toDouble();
          _safeBottom = (_safeBottom + dy)
              .clamp(_safeTop + minHeight, 1 - edgeInset)
              .toDouble();
      }
    });
  }

  void _handleDragStart({
    required double initialHorizontalPosition,
    required double initialVerticalPosition,
  }) {
    setState(() {
      _horizontalPosition ??= initialHorizontalPosition;
      _verticalPosition ??= initialVerticalPosition;
      _isDragging = true;
      _rotationRadians = 0;
      _scale = 1.035;
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details, {
    required double horizontalTravelDistance,
    required double verticalTravelDistance,
  }) {
    if (horizontalTravelDistance <= 0 && verticalTravelDistance <= 0) return;

    setState(() {
      if (horizontalTravelDistance > 0) {
        _horizontalPosition = ((_horizontalPosition ?? 0) +
                details.delta.dx / horizontalTravelDistance)
            .clamp(0.0, 1.0)
            .toDouble();
      }
      if (verticalTravelDistance > 0) {
        _verticalPosition = ((_verticalPosition ?? 1) -
                details.delta.dy / verticalTravelDistance)
            .clamp(0.0, 1.0)
            .toDouble();
      }
      _rotationRadians = (_rotationRadians +
              (details.delta.dx + details.delta.dy * 0.35) * 0.0024)
          .clamp(-0.16, 0.16)
          .toDouble();
      final movement = math.max(
        details.delta.dx.abs(),
        details.delta.dy.abs(),
      );
      _scale = 1.035 + math.min(movement / 1000, 0.025).toDouble();
    });
  }

  void _handleDragEnd({required double minLeft, required double maxLeft}) {
    if (_isExpanded) return;

    setState(() {
      final position = _horizontalPosition;
      if (position != null) {
        final currentLeft = minLeft + position * (maxLeft - minLeft);
        if (currentLeft - minLeft <= _snapThreshold) {
          _horizontalPosition = 0;
        } else if (maxLeft - currentLeft <= _snapThreshold) {
          _horizontalPosition = 1;
        }
      }
      _isDragging = false;
      _rotationRadians = 0;
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom + DesignConstants.spacingL;
    final topBoundary = mediaQuery.padding.top + kToolbarHeight + _topGap;
    final panelTop =
        mediaQuery.padding.top + kToolbarHeight + DesignConstants.spacingS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(0.0, constraints.maxWidth).toDouble();
        final visibleEdge = math.min(_visibleEdge, width / 2).toDouble();
        final minLeft = visibleEdge - _cloudSize;
        final maxLeft = math.max(minLeft, width - visibleEdge).toDouble();
        final travelDistance = math.max(0.0, maxLeft - minLeft).toDouble();

        // Start with the full cloud visible and align its resting position
        // with the cards. At either stop, a small part remains on screen.
        final defaultLeft = (width - _horizontalInset - _cloudSize)
            .clamp(minLeft, maxLeft)
            .toDouble();
        final defaultPosition = travelDistance == 0
            ? 0.0
            : ((defaultLeft - minLeft) / travelDistance)
                .clamp(0.0, 1.0)
                .toDouble();
        final position = _horizontalPosition ?? defaultPosition;
        final left = minLeft + position * travelDistance;
        final minTop = math
            .min(topBoundary - _topVisualInset, constraints.maxHeight)
            .toDouble();
        final maxTop = math
            .max(minTop, constraints.maxHeight - bottomInset - _cloudSize)
            .toDouble();
        final verticalTravelDistance =
            math.max(0.0, maxTop - minTop).toDouble();
        final verticalPosition =
            (_verticalPosition ?? 1.0).clamp(0.0, 1.0).toDouble();
        final top = maxTop - verticalPosition * verticalTravelDistance;
        final viewportSize = Size(width, constraints.maxHeight);
        final panelRect = Rect.fromLTRB(
          DesignConstants.spacingS,
          panelTop,
          width - DesignConstants.spacingS,
          constraints.maxHeight -
              mediaQuery.padding.bottom -
              DesignConstants.spacingS,
        );
        final safeRect = Rect.fromLTRB(
          panelRect.left + panelRect.width * _safeLeft,
          panelRect.top + panelRect.height * _safeTop,
          panelRect.left + panelRect.width * _safeRight,
          panelRect.top + panelRect.height * _safeBottom,
        );
        final fullscreenRect = Rect.fromLTRB(
          0,
          0,
          width,
          constraints.maxHeight,
        );
        final fullscreenProgress = Curves.easeInOutCubic.transform(
          _fullscreenAnimation.value,
        );
        final activeSafeRect =
            Rect.lerp(safeRect, fullscreenRect, fullscreenProgress)!;
        const handleOutset = 44.0;
        final cloudCenter = Offset(left + _cloudSize / 2, top + _cloudSize / 2);
        final morphAnimation = _morphAnimation;
        final theme = Theme.of(context);
        Offset handlePosition(Offset corner, Offset direction) => Offset(
              (corner.dx + direction.dx * handleOutset)
                  .clamp(28.0, width - 28.0)
                  .toDouble(),
              (corner.dy + direction.dy * handleOutset)
                  .clamp(
                    mediaQuery.padding.top + 28.0,
                    constraints.maxHeight - mediaQuery.padding.bottom - 28.0,
                  )
                  .toDouble(),
            );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildExpandedBackdrop(theme),
            Positioned.fill(
              child: IgnorePointer(
                child: AiNeuralCloudOrbWidget(
                  size: _cloudSize * _scale,
                  rotation: _rotationRadians,
                  canvasSize: viewportSize,
                  cloudCenter: cloudCenter,
                  frameRect: activeSafeRect,
                  frameMorphAnimation: morphAnimation,
                  showDetachedSatellite: false,
                  flowSpeed: _isDragging
                      ? 1.55
                      : _isExpanded
                          ? 2.0 * widget.liveliness.clamp(0.0, 1.0)
                          : 0.24,
                  enableInteraction: false,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              child: AnimatedBuilder(
                animation: morphAnimation,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: morphAnimation.value > 0.001,
                    child: Semantics(
                      label: widget.semanticLabel,
                      hint: widget.semanticHint,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: morphAnimation.value > 0.001
                            ? null
                            : _toggleExpanded,
                        onPanStart: morphAnimation.value > 0.001
                            ? null
                            : (_) => _handleDragStart(
                                  initialHorizontalPosition: defaultPosition,
                                  initialVerticalPosition: verticalPosition,
                                ),
                        onPanUpdate: morphAnimation.value > 0.001
                            ? null
                            : (details) => _handleDragUpdate(
                                  details,
                                  horizontalTravelDistance: travelDistance,
                                  verticalTravelDistance:
                                      verticalTravelDistance,
                                ),
                        onPanEnd: morphAnimation.value > 0.001
                            ? null
                            : (_) => _handleDragEnd(
                                  minLeft: minLeft,
                                  maxLeft: maxLeft,
                                ),
                        onPanCancel: morphAnimation.value > 0.001
                            ? null
                            : () => _handleDragEnd(
                                  minLeft: minLeft,
                                  maxLeft: maxLeft,
                                ),
                        child: const SizedBox(
                          width: _cloudSize,
                          height: _cloudSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showResizeHandles &&
                _fullscreenAnimation.value < 0.02) ...[
              _buildResizeHandle(
                _SafeSpaceCorner.topLeft,
                handlePosition(activeSafeRect.topLeft, const Offset(-1, -1)),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.topRight,
                handlePosition(activeSafeRect.topRight, const Offset(1, -1)),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.bottomLeft,
                handlePosition(
                  activeSafeRect.bottomLeft,
                  const Offset(-1, 1),
                ),
                panelRect.size,
                theme,
              ),
              _buildResizeHandle(
                _SafeSpaceCorner.bottomRight,
                handlePosition(
                  activeSafeRect.bottomRight,
                  const Offset(1, 1),
                ),
                panelRect.size,
                theme,
              ),
            ],
            AnimatedBuilder(
              animation: morphAnimation,
              builder: (context, _) {
                final revealProgress = Curves.easeInOutCubic.transform(
                  morphAnimation.value.clamp(0.0, 1.0),
                );
                final collapsedBounds = Rect.fromCenter(
                  center: cloudCenter,
                  width: 120,
                  height: 120,
                );
                final contentRevealBounds = Rect.lerp(
                  collapsedBounds,
                  activeSafeRect.inflate(64),
                  revealProgress,
                )!;
                return Positioned.fill(
                  child: ClipRect(
                    clipper: _CloudControlsClipper(contentRevealBounds),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildExpandedToolbar(
                          activeSafeRect,
                          theme,
                          fullscreenProgress: fullscreenProgress,
                        ),
                        _buildChatPreview(
                          activeSafeRect,
                          theme,
                          constraints.maxHeight,
                          fullscreenProgress: fullscreenProgress,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedBackdrop(ThemeData theme) {
    final scrimColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _morphAnimation,
        builder: (context, _) {
          final progress = _morphAnimation.value;
          return IgnorePointer(
            ignoring: progress <= 0.001,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: scrimColor.withValues(alpha: 0.30 * progress),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleExpanded,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedToolbar(
    Rect safeRect,
    ThemeData theme, {
    required double fullscreenProgress,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final contrastColor = isDark ? Colors.black : Colors.white;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final safeSpaceOutset = 44.0 * (1 - fullscreenProgress);
    final fullscreenInset = 12.0 * fullscreenProgress;
    final expandedToolbarTop = safeRect.top - 62;
    final fullscreenToolbarTop = MediaQuery.paddingOf(context).top + 10;
    final toolbarTop = expandedToolbarTop +
        (fullscreenToolbarTop - expandedToolbarTop) * fullscreenProgress;

    return Positioned(
      left: safeRect.left - safeSpaceOutset + fullscreenInset,
      right: viewportWidth - safeRect.right - safeSpaceOutset + fullscreenInset,
      top: toolbarTop,
      height: 52,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: FadeTransition(
          opacity: _morphAnimation,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildHeaderGlassButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Schließen',
                  isDark: isDark,
                  onPressed: _toggleExpanded,
                ),
              ),
              if (!_isFullscreen)
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: _handleHeaderDragStart,
                      onVerticalDragUpdate: _handleHeaderDragUpdate,
                      onVerticalDragEnd: _handleHeaderDragEnd,
                      child: SizedBox(
                        width: 72,
                        height: 56,
                        child: Center(
                          child: Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: contrastColor.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isFullscreen) const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildHeaderGlassButton(
                  icon: _isFullscreen
                      ? Icons.close_fullscreen_rounded
                      : Icons.open_in_full_rounded,
                  tooltip: _isFullscreen ? 'Vollbild verlassen' : 'Vollbild',
                  isDark: isDark,
                  onPressed: _toggleFullscreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderGlassButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    final foreground = isDark ? Colors.black : Colors.white;
    final cloudIsDark = !isDark;
    // The cloud's surface is inverted from the app theme: white in dark mode
    // and black in light mode. Tune the glass against that actual backdrop.
    final settings = DesignConstants.liquidGlassSettings(!isDark).copyWith(
      thickness: 18,
      blur: 1.5,
    );
    final rimColor = foreground.withValues(alpha: 0.14);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: DesignConstants.glassShadow(cloudIsDark),
            ),
            child: InheritedLiquidGlass(
              settings: settings,
              isBlurProvidedByAncestor: true,
              child: AdaptiveGlass(
                settings: settings,
                allowElevation: false,
                shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                child: GlassGlow(
                  glowColor: foreground.withValues(alpha: 0.12),
                  glowRadius: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignConstants.glassNeutralTint(cloudIsDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: rimColor, width: 0.5),
                    ),
                    child: Center(
                      child: Icon(icon, size: 20, color: foreground),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPreview(
    Rect safeRect,
    ThemeData theme,
    double viewportHeight, {
    required double fullscreenProgress,
  }) {
    final contrastColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    final softColor = contrastColor.withValues(alpha: 0.08);
    const contentInset = 8.0;
    final chatBounds = Rect.lerp(
      safeRect.inflate(44),
      safeRect.deflate(12),
      fullscreenProgress,
    )!;
    final contentLeft = chatBounds.left + contentInset;
    final contentRight =
        MediaQuery.sizeOf(context).width - chatBounds.right + contentInset;
    final composerLeft = chatBounds.left;
    final composerRight = MediaQuery.sizeOf(context).width - chatBounds.right;
    final chatTop = safeRect.top + 16 + 48 * fullscreenProgress;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isExpanded || !_showChatPreview,
        child: FadeTransition(
          opacity: _morphAnimation,
          child: AnimatedOpacity(
            opacity: _showChatPreview ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Stack(
              children: [
                Positioned(
                  left: contentLeft,
                  right: contentRight,
                  top: chatTop,
                  bottom: viewportHeight - chatBounds.bottom + 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _chatTurns.isEmpty
                            ? Center(
                                child: Text(
                                  'Schreib eine Nachricht …',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: contrastColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _chatScrollController,
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 20,
                                ),
                                itemCount: _chatTurns.length,
                                itemBuilder: (context, index) => _buildChatTurn(
                                  _chatTurns[index],
                                  theme: theme,
                                  contrastColor: contrastColor,
                                  softColor: softColor,
                                  isStreaming: _isGenerating &&
                                      index == _chatTurns.length - 1,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: composerLeft,
                  right: composerRight,
                  bottom: viewportHeight - chatBounds.bottom + contentInset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: contrastColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatInputController,
                              focusNode: _chatFocusNode,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (!_isGenerating) _sendDemoPrompt();
                              },
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: contrastColor,
                              ),
                              cursorColor: theme.colorScheme.primary,
                              decoration: InputDecoration(
                                hintText: 'Nachricht schreiben …',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: contrastColor.withValues(alpha: 0.52),
                                ),
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: _isGenerating ? 'Stopp' : 'Senden',
                            child: Material(
                              color: contrastColor,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _isGenerating
                                    ? _stopDemoGeneration
                                    : _sendDemoPrompt,
                                child: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    _isGenerating
                                        ? Icons.stop_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: _isGenerating ? 21 : 20,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildChatTurn(
    _DemoChatTurn turn, {
    required ThemeData theme,
    required Color contrastColor,
    required Color softColor,
    required bool isStreaming,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                turn.prompt,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: contrastColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16),
            child: Text(
              turn.response,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: contrastColor,
                height: 1.5,
              ),
            ),
          ),
          if (isStreaming && turn.response.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 14),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contrastColor.withValues(alpha: 0.58),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sendDemoPrompt() {
    if (_isGenerating) return;
    final prompt = _chatInputController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _chatTurns.add(_DemoChatTurn(prompt));
      _isGenerating = true;
      _followChatTail = true;
      _demoWordIndex = 0;
      _chatInputController.clear();
    });
    _scrollChatToBottom(force: true);

    _responseTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final turn = _chatTurns.last;
        turn.response += '${_demoWords[_demoWordIndex]} ';
        _demoWordIndex = (_demoWordIndex + 1) % _demoWords.length;
        if (_demoWordIndex == 0) turn.response += '\n\n';
      });
      _scrollChatToBottom();
    });
  }

  void _stopDemoGeneration() {
    if (!_isGenerating) return;
    _responseTimer?.cancel();
    _responseTimer = null;
    setState(() => _isGenerating = false);
  }

  void _handleChatScroll() {
    if (!_chatScrollController.hasClients) return;
    final position = _chatScrollController.position;
    _followChatTail = position.maxScrollExtent - position.pixels < 80;
  }

  void _scrollChatToBottom({bool force = false}) {
    if (force) _followChatTail = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients || !_followChatTail) {
        return;
      }
      _chatScrollController.jumpTo(
        _chatScrollController.position.maxScrollExtent,
      );
    });
  }

  Widget _buildResizeHandle(
    _SafeSpaceCorner corner,
    Offset position,
    Size size,
    ThemeData theme,
  ) {
    const hitTargetSize = 40.0;
    final handleColor = theme.colorScheme.primary;

    return Positioned(
      left: position.dx - hitTargetSize / 2,
      top: position.dy - hitTargetSize / 2,
      width: hitTargetSize,
      height: hitTargetSize,
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: FadeTransition(
          opacity: _morphAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onPanUpdate: (details) => _resizeSafeSpace(corner, details, size),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: handleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.open_in_full,
                  size: 10,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoChatTurn {
  _DemoChatTurn(this.prompt);

  final String prompt;
  String response = '';
}

class _CloudControlsClipper extends CustomClipper<Rect> {
  const _CloudControlsClipper(this.revealBounds);

  final Rect revealBounds;

  @override
  Rect getClip(Size size) => revealBounds.intersect(Offset.zero & size);

  @override
  bool shouldReclip(covariant _CloudControlsClipper oldClipper) =>
      oldClipper.revealBounds != revealBounds;
}

enum _SafeSpaceCorner { topLeft, topRight, bottomLeft, bottomRight }

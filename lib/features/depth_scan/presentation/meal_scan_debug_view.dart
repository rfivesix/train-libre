// lib/features/depth_scan/presentation/meal_scan_debug_view.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/depth_map_renderer.dart';
import '../domain/models/depth_scale_facts.dart';
import '../platform/depth_scan_channel.dart';

/// Developer and debug inspector view for LiDAR depth buffers,
/// scale calculations, AI prompts, and raw bounding regions.
class MealScanDebugView extends StatefulWidget {
  final DepthCaptureResult? captureResult;
  final DepthScaleFacts? scaleFacts;
  final String? sentPrompt;
  final String? rawResponse;

  const MealScanDebugView({
    super.key,
    this.captureResult,
    this.scaleFacts,
    this.sentPrompt,
    this.rawResponse,
  });

  @override
  State<MealScanDebugView> createState() => _MealScanDebugViewState();
}

class _MealScanDebugViewState extends State<MealScanDebugView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ui.Image? _depthUiImage;
  DepthBandRender? _depthRender;
  bool _useViridis = true;
  double? _inspectedPixelDistanceCm;
  Offset? _inspectedNormalizedOffset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _renderDepthImage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _renderDepthImage() async {
    final buffer = widget.captureResult?.depthBuffer;
    final w = widget.captureResult?.depthWidth ?? 0;
    final h = widget.captureResult?.depthHeight ?? 0;

    if (buffer != null && w > 0 && h > 0) {
      final result = await DepthMapRenderer.createUiImage(
        depthBuffer: buffer,
        width: w,
        height: h,
        useViridis: _useViridis,
      );
      if (mounted) {
        setState(() {
          _depthUiImage = result.image;
          _depthRender = result.render;
        });
      }
    }
  }

  void _inspectPixel(Offset localOffset, Size renderSize) {
    final buffer = widget.captureResult?.depthBuffer;
    final w = widget.captureResult?.depthWidth ?? 0;
    final h = widget.captureResult?.depthHeight ?? 0;

    if (buffer == null ||
        w <= 0 ||
        h <= 0 ||
        renderSize.width <= 0 ||
        renderSize.height <= 0) {
      return;
    }

    final normX = (localOffset.dx / renderSize.width).clamp(0.0, 1.0);
    final normY = (localOffset.dy / renderSize.height).clamp(0.0, 1.0);

    final pixelX = (normX * (w - 1)).round();
    final pixelY = (normY * (h - 1)).round();
    final index = pixelY * w + pixelX;

    if (index >= 0 && index < buffer.length) {
      final meters = buffer[index];
      setState(() {
        _inspectedNormalizedOffset = Offset(normX, normY);
        _inspectedPixelDistanceCm = meters.isFinite ? meters * 100.0 : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF12120F) : const Color(0xFFF7F7F4);
    final cardBg = isDark ? const Color(0xFF1E1E1B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final lime = const Color(0xFFC9EF00);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        title: const Text(
          'Developer Insights (LiDAR & AI)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: lime,
          labelColor: lime,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tiefenkarte (8 Bänder)'),
            Tab(text: 'Maßstab & Intrinsics'),
            Tab(text: 'Prompt & Payload'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepthMapTab(isDark, cardBg, titleColor),
          _buildScaleFactsTab(isDark, cardBg, titleColor),
          _buildPromptTab(isDark, cardBg, titleColor),
        ],
      ),
    );
  }

  Widget _buildDepthMapTab(bool isDark, Color cardBg, Color titleColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Palette switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                'Farbrampe: ${_useViridis ? "Viridis (8 Bänder)" : "Graustufen"}',
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: titleColor)),
            Switch(
              value: _useViridis,
              activeThumbColor: const Color(0xFFC9EF00),
              onChanged: (val) {
                setState(() => _useViridis = val);
                _renderDepthImage();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Depth Heatmap with interactive Tap-to-Measure
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white24),
          ),
          clipBehavior: Clip.antiAlias,
          child: _depthUiImage != null
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) => _inspectPixel(
                          details.localPosition, constraints.biggest),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RawImage(
                            image: _depthUiImage,
                            fit: BoxFit.fill,
                          ),
                          if (_inspectedNormalizedOffset != null)
                            Positioned(
                              left: _inspectedNormalizedOffset!.dx *
                                      constraints.maxWidth -
                                  10,
                              top: _inspectedNormalizedOffset!.dy *
                                      constraints.maxHeight -
                                  10,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFC9EF00), width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text(
                    'Kein Tiefenpuffer vorhanden (Gerät ohne LiDAR)',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
        ),
        const SizedBox(height: 8),

        // Inspection readout
        if (_inspectedPixelDistanceCm != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC9EF00).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Gemessene Punktdistanz: ${_inspectedPixelDistanceCm!.toStringAsFixed(1)} cm',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF5B6B00)),
            ),
          ),
        const SizedBox(height: 16),

        // 8 Discrete Bands Legend
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  _depthRender?.adaptive == true
                      ? 'Diskrete 8 Bänder (automatisch gedehnt)'
                      : 'Diskrete 8 Bänder (Relativ zur Tischebene)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: titleColor)),
              if (_depthRender != null) ...[
                const SizedBox(height: 4),
                Text(
                  _depthRender!.adaptive
                      ? 'Referenzfläche ${_depthRender!.referenceCm.toStringAsFixed(0)} cm · '
                          'Motiv ragt ${_depthRender!.peakElevationCm.toStringAsFixed(0)} cm heraus — '
                          'die feste Tischskala wäre komplett gesättigt, daher gedehnt.'
                      : 'Referenzfläche ${_depthRender!.referenceCm.toStringAsFixed(0)} cm · '
                          'Motiv ragt ${_depthRender!.peakElevationCm.toStringAsFixed(1)} cm heraus.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: titleColor.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ...DepthMapRenderer.bandPaletteRgb.asMap().entries.map((e) {
                final idx = e.key;
                final rgb = e.value;
                final bands =
                    _depthRender?.bandsCm ?? DepthMapRenderer.defaultBandsCm;
                final desc = idx == 0
                    ? 'Band 1: Referenzfläche oder darunter'
                    : 'Band ${idx + 1}: ${bands[idx]} cm+ Erhebung';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1.0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(desc,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: titleColor)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScaleFactsTab(bool isDark, Color cardBg, Color titleColor) {
    final facts = widget.scaleFacts ?? widget.captureResult?.scaleFacts;
    final intrinsics = widget.captureResult?.intrinsics;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (facts != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LiDAR Scale Facts',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: titleColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: facts.isValid
                            ? const Color(0x2934C759)
                            : const Color(0x24FF453A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        facts.isValid
                            ? 'QUALITY GATE: PASS'
                            : 'QUALITY GATE: REJECT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: facts.isValid
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF453A),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildStatRow('Zieldistanz (Median Bildmitte)',
                    '${facts.subjectDistanceCm} cm', titleColor),
                _buildStatRow('Sichtbare Frame-Breite',
                    '${facts.frameWidthCm} cm', titleColor),
                _buildStatRow('Sichtbare Frame-Höhe',
                    '${facts.frameHeightCm} cm', titleColor),
                _buildStatRow('Nahgrenze (5. Perzentil)', '${facts.nearCm} cm',
                    titleColor),
                _buildStatRow('Ferngrenze (95. Perzentil)', '${facts.farCm} cm',
                    titleColor),
                _buildStatRow(
                    'Gültige Messpunkte-Quote',
                    '${(facts.validSampleRatio * 100).toStringAsFixed(0)}%',
                    titleColor),
                _buildStatRow(
                    'Sensor-Genauigkeitsmodus', facts.accuracy, titleColor),
              ],
            ),
          )
        else
          const Center(child: Text('Keine Maßstab-Fakten berechnet')),
        const SizedBox(height: 16),
        if (intrinsics != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kamera-Intrinsics',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor)),
                const Divider(height: 20),
                _buildStatRow(
                    'Brennweite (fx, fy)',
                    '${intrinsics.fx.toStringAsFixed(1)}, ${intrinsics.fy.toStringAsFixed(1)}',
                    titleColor),
                _buildStatRow(
                    'Hauptpunkt (cx, cy)',
                    '${intrinsics.cx.toStringAsFixed(1)}, ${intrinsics.cy.toStringAsFixed(1)}',
                    titleColor),
                _buildStatRow(
                    'Referenz-Auflösung',
                    '${intrinsics.refWidth} x ${intrinsics.refHeight} px',
                    titleColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPromptTab(bool isDark, Color cardBg, Color titleColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gesendeter System- & Maßstab-Prompt',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: titleColor)),
              const SizedBox(height: 8),
              SelectableText(
                widget.sentPrompt ?? 'Kein Prompt erfasst.',
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rohe Modell-Antwort (JSON)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: titleColor)),
              const SizedBox(height: 8),
              SelectableText(
                widget.rawResponse ?? 'Keine Roh-Antwort erfasst.',
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: titleColor.withValues(alpha: 0.8))),
          Text(value,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: titleColor)),
        ],
      ),
    );
  }
}

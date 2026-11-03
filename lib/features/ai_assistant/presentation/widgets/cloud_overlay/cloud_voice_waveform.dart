import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A single sample in the voice level waveform.
class VoiceWaveSample {
  const VoiceWaveSample({required this.position, required this.level});

  final double position;
  final double level;
}

/// Custom painter for voice input audio level waveforms.
class VoiceWaveformPainter extends CustomPainter {
  const VoiceWaveformPainter({
    required this.samples,
    required this.color,
    required this.scrollOffset,
  }) : super(repaint: scrollOffset);

  final List<VoiceWaveSample> samples;
  final Color color;
  final ValueListenable<double> scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    const rightInset = 3.5;
    const fadeWidth = 30.0;
    final centerY = size.height / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final currentPosition = scrollOffset.value;

    // A single moving waveform; no stationary baseline remains behind it.
    for (final sample in samples) {
      final age = currentPosition - sample.position;
      if (age < 0 || age > size.width) continue;
      final x = size.width - rightInset - age;
      if (x < 2) continue;
      final halfHeight = 2.0 + sample.level * (size.height * 0.42);
      final leftFade = ((x - 2) / fadeWidth).clamp(0.0, 1.0);
      final rightFade = ((size.width - x) / fadeWidth).clamp(0.0, 1.0);
      paint.color = color.withValues(
        alpha: color.a * math.min(leftFade, rightFade),
      );
      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) =>
      oldDelegate.color != color ||
      !listEquals(oldDelegate.samples, samples) ||
      oldDelegate.scrollOffset != scrollOffset;
}

/// Widget displaying voice recording progress or dynamic waveform.
class CloudVoiceRecordingContent extends StatelessWidget {
  const CloudVoiceRecordingContent({
    super.key,
    required this.voiceStarting,
    required this.voiceStopping,
    required this.voiceLevelHistory,
    required this.voiceWaveOffset,
    required this.foregroundColor,
  });

  final bool voiceStarting;
  final bool voiceStopping;
  final List<VoiceWaveSample> voiceLevelHistory;
  final ValueListenable<double> voiceWaveOffset;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (voiceStarting || voiceStopping) {
      return Center(
        child: SizedBox(
          width: 96,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: foregroundColor.withValues(alpha: 0.72),
            backgroundColor: foregroundColor.withValues(alpha: 0.16),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      width: double.infinity,
      child: CustomPaint(
        painter: VoiceWaveformPainter(
          samples: List<VoiceWaveSample>.of(voiceLevelHistory),
          color: foregroundColor.withValues(alpha: 0.82),
          scrollOffset: voiceWaveOffset,
        ),
        willChange: true,
      ),
    );
  }
}

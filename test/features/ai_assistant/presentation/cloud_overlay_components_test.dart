import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_chat_turn_view.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_overlay_access_audit_modal.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_overlay_geometry.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_overlay_markdown.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_voice_waveform.dart';

void main() {
  group('Streaming Markdown Normalization', () {
    test('does not modify non-streaming text', () {
      expect(
        normalizeStreamingMarkdown('Hello **world', isStreaming: false),
        equals('Hello **world'),
      );
    });

    test('auto-closes unclosed bold spans during streaming', () {
      expect(
        normalizeStreamingMarkdown('Here is **bold', isStreaming: true),
        equals('Here is **bold**'),
      );
    });

    test('strips trailing double asterisk before text arrives', () {
      expect(
        normalizeStreamingMarkdown('Ready **', isStreaming: true),
        equals('Ready '),
      );
    });

    test('auto-closes unclosed inline code during streaming', () {
      expect(
        normalizeStreamingMarkdown('Run `flutter test', isStreaming: true),
        equals('Run `flutter test`'),
      );
    });
  });

  group('Generation Duration Formatting', () {
    test('formats durations under 10 seconds with 1 decimal and comma', () {
      expect(
        formatGenerationDuration(const Duration(milliseconds: 1500)),
        equals('1,5 s'),
      );
      expect(
        formatGenerationDuration(const Duration(milliseconds: 400)),
        equals('0,4 s'),
      );
    });

    test('formats durations of 10s and above as rounded integer seconds', () {
      expect(
        formatGenerationDuration(
          const Duration(seconds: 12, milliseconds: 300),
        ),
        equals('12 s'),
      );
    });
  });

  group('Access Status and Model Name Localization', () {
    test('localizes German and English access status', () {
      expect(localizeAccessStatus('denied', isDe: true), equals('Abgelehnt'));
      expect(
        localizeAccessStatus('approved', isDe: true),
        equals('Freigegeben'),
      );
      expect(localizeAccessStatus('denied', isDe: false), equals('denied'));
      expect(
        localizeAccessStatus('not_shared', isDe: true),
        equals('Keine Datensätze übertragen'),
      );
      expect(
        localizeAccessStatus('not_shared', isDe: false),
        equals('No records shared'),
      );
    });

    test('formats model display name with apple foundation fallback', () {
      expect(
        formatModelDisplayName('appleFoundation', null),
        equals('Apple Intelligence'),
      );
      expect(
        formatModelDisplayName(null, 'apple-foundation-system'),
        equals('Apple Intelligence'),
      );
      expect(formatModelDisplayName('openai', 'gpt-4o'), equals('gpt-4o'));
    });
  });

  group('Cloud Overlay Geometry & Palette', () {
    test('openingAppearanceProgress transitions smoothly over range 0.5', () {
      expect(openingAppearanceProgress(0.0), equals(0.0));
      expect(openingAppearanceProgress(0.5), equals(1.0));
      expect(openingAppearanceProgress(0.8), equals(1.0));
    });

    test('overlay colors interpolate properly with light and dark themes', () {
      final lightTheme = ThemeData(brightness: Brightness.light);
      final darkTheme = ThemeData(brightness: Brightness.dark);

      expect(overlaySurfaceColor(lightTheme, 0.0), equals(Colors.black));
      expect(overlaySurfaceColor(darkTheme, 0.0), equals(Colors.white));

      expect(overlayForegroundColor(lightTheme, 0.0), equals(Colors.white));
      expect(overlayForegroundColor(darkTheme, 0.0), equals(Colors.black));
    });
  });

  group('Voice Waveform Custom Painter', () {
    test('painter executes without error', () {
      final painter = VoiceWaveformPainter(
        samples: const [
          VoiceWaveSample(position: 10, level: 0.5),
          VoiceWaveSample(position: 20, level: 0.8),
        ],
        color: Colors.white,
        scrollOffset: ValueNotifier<double>(25),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 44));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}

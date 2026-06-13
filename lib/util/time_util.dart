// lib/util/time_util.dart

import 'package:flutter/services.dart';

/// Formats a [Duration] into a string like "HH:MM:SS" or "MM:SS".
String formatDuration(Duration d) {
  // .abs() ensures we do not show negative values
  // if small time inconsistencies occur.
  d = d.abs();

  var seconds = d.inSeconds;
  final hours = seconds ~/ Duration.secondsPerHour;
  seconds -= hours * Duration.secondsPerHour;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  seconds -= minutes * Duration.secondsPerMinute;

  final hoursString = hours > 0 ? '${hours.toString()}:' : '';
  final minutesString = minutes.toString().padLeft(2, '0');
  final secondsString = seconds.toString().padLeft(2, '0');

  return '$hoursString$minutesString:$secondsString';
}

/// Formats seconds into a string like "MM:SS" or empty if null/zero.
String formatPauseDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// Parses a string like "MM:SS" or "S" into seconds.
int? parsePauseDuration(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains(':')) {
    final parts = trimmed.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return (m * 60) + s;
    }
  }
  return int.tryParse(trimmed);
}

/// A text input formatter that formats digits as a timer input (MM:SS).
class TimerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse digits to check for all zeros
    final intValue = int.tryParse(digits) ?? 0;
    if (intValue == 0) {
      // If it's all zeros (e.g. 0000), show empty to allow clearing
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Limit to 4 digits (MM:SS)
    final String cleanDigits = digits.length > 4
        ? digits.substring(digits.length - 4)
        : digits;

    // Pad to 4 characters with leading zeros
    final padded = cleanDigits.padLeft(4, '0');
    final minutes = padded.substring(0, 2);
    final seconds = padded.substring(2, 4);

    final formatted = '$minutes:$seconds';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

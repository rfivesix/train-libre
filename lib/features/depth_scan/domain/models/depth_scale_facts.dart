// lib/features/depth_scan/domain/models/depth_scale_facts.dart

import 'dart:convert';

/// Physical scale facts derived from LiDAR depth buffer and camera intrinsics.
///
/// Trust these measured numbers over visual estimation in multimodal AI prompts.
class DepthScaleFacts {
  /// Estimated median distance from camera to the subject (center third) in cm.
  final double subjectDistanceCm;

  /// Visible width of the frame at [subjectDistanceCm] in cm.
  final double frameWidthCm;

  /// Visible height of the frame at [subjectDistanceCm] in cm.
  final double frameHeightCm;

  /// 5th percentile distance in cm (nearest surface).
  final double nearCm;

  /// 95th percentile distance in cm (farthest surface).
  final double farCm;

  /// Ratio of valid, non-null depth samples across the frame (0.0 to 1.0).
  final double validSampleRatio;

  /// Accuracy mode from sensor: 'absolute' (metric LiDAR) or 'relative'.
  final String accuracy;

  /// Whether the measurement passed quality gates (15-120cm, ratio >= 0.5, absolute).
  final bool isValid;

  const DepthScaleFacts({
    required this.subjectDistanceCm,
    required this.frameWidthCm,
    required this.frameHeightCm,
    required this.nearCm,
    required this.farCm,
    required this.validSampleRatio,
    this.accuracy = 'absolute',
    required this.isValid,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject_distance_cm': subjectDistanceCm,
      'frame_width_cm': frameWidthCm,
      'frame_height_cm': frameHeightCm,
      'near_cm': nearCm,
      'far_cm': farCm,
      'valid_sample_ratio': validSampleRatio,
      'accuracy': accuracy,
      'is_valid': isValid,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory DepthScaleFacts.fromMap(Map<String, dynamic> map) {
    return DepthScaleFacts(
      subjectDistanceCm: (map['subject_distance_cm'] as num).toDouble(),
      frameWidthCm: (map['frame_width_cm'] as num).toDouble(),
      frameHeightCm: (map['frame_height_cm'] as num).toDouble(),
      nearCm: (map['near_cm'] as num).toDouble(),
      farCm: (map['far_cm'] as num).toDouble(),
      validSampleRatio: (map['valid_sample_ratio'] as num).toDouble(),
      accuracy: map['accuracy'] as String? ?? 'absolute',
      isValid: map['is_valid'] as bool? ?? true,
    );
  }

  factory DepthScaleFacts.fromJson(String jsonStr) =>
      DepthScaleFacts.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
}

import 'package:flutter/services.dart';

class HealthHeartRateSampleDto {
  const HealthHeartRateSampleDto({
    required this.sampledAtUtc,
    required this.bpm,
    this.sourceId,
    this.nativeId,
  });

  final DateTime sampledAtUtc;
  final double bpm;
  final String? sourceId;
  final String? nativeId;

  factory HealthHeartRateSampleDto.fromMap(Map<dynamic, dynamic> map) {
    return HealthHeartRateSampleDto(
      sampledAtUtc: DateTime.parse(map['sampledAtUtcIso'] as String).toUtc(),
      bpm: (map['bpm'] as num).toDouble(),
      sourceId: map['sourceId'] as String?,
      nativeId: map['nativeId'] as String?,
    );
  }
}

abstract class HealthHeartRateDataSource {
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
}

abstract class HealthRestingHeartRateDataSource {
  Future<List<HealthHeartRateSampleDto>> readRestingHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
}

class HealthPlatformHeartRate
    implements HealthHeartRateDataSource, HealthRestingHeartRateDataSource {
  static const MethodChannel _channel = MethodChannel(
    'trainlibre.health/steps',
  );

  const HealthPlatformHeartRate();

  Future<String?> checkPermissions() =>
      _channel.invokeMethod<String>('checkHeartRatePermissions');

  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestHeartRatePermissions',
      );
      return granted == true;
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') return false;
      if (e.code == 'not_available') return false;
      rethrow;
    }
  }

  @override
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) => _readSamples('readHeartRateSamples', fromUtc, toUtc);

  @override
  Future<List<HealthHeartRateSampleDto>> readRestingHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) => _readSamples('readRestingHeartRateSamples', fromUtc, toUtc);

  Future<List<HealthHeartRateSampleDto>> _readSamples(
    String method,
    DateTime fromUtc,
    DateTime toUtc,
  ) async {
    final response = await _channel.invokeMethod<List<dynamic>>(
      method,
      <String, dynamic>{
        'fromUtcIso': fromUtc.toUtc().toIso8601String(),
        'toUtcIso': toUtc.toUtc().toIso8601String(),
      },
    );

    final rows = response ?? const <dynamic>[];
    return rows
        .map(
          (row) =>
              HealthHeartRateSampleDto.fromMap(row as Map<dynamic, dynamic>),
        )
        .where((sample) => sample.bpm.isFinite && sample.bpm > 0)
        .toList(growable: false);
  }
}

import '../../../services/health/health_platform_heart_rate.dart';
import '../../sleep/platform/permissions/sleep_permission_models.dart';
import '../../sleep/platform/permissions/sleep_permissions_service.dart';

class HealthConnectPulsePermissionsService implements SleepPermissionsService {
  const HealthConnectPulsePermissionsService();

  static const _platform = HealthPlatformHeartRate();

  @override
  Future<SleepPermissionOutcome> checkStatus() async {
    try {
      final status = await _platform.checkPermissions();
      return switch (status) {
        'ready' => const SleepPermissionOutcome.ready(),
        'partial' => const SleepPermissionOutcome.state(
          SleepPermissionState.partial,
        ),
        'denied' => const SleepPermissionOutcome.state(
          SleepPermissionState.denied,
        ),
        'unavailable' => const SleepPermissionOutcome.state(
          SleepPermissionState.unavailable,
        ),
        'not_installed' => const SleepPermissionOutcome.state(
          SleepPermissionState.notInstalled,
        ),
        _ => const SleepPermissionOutcome.error(
          SleepPlatformServiceError.unknown,
        ),
      };
    } catch (_) {
      return const SleepPermissionOutcome.error(
        SleepPlatformServiceError.unknown,
      );
    }
  }

  @override
  Future<SleepPermissionOutcome> requestAccess() async {
    try {
      await _platform.requestPermissions();
    } catch (_) {
      return const SleepPermissionOutcome.error(
        SleepPlatformServiceError.unknown,
      );
    }
    return checkStatus();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../data/drift_database.dart';
import 'adapters/apple_health/apple_health_export_adapter.dart';
import 'adapters/health_connect/health_connect_export_adapter.dart';
import 'export_service.dart';
import 'models/export_models.dart';

/// Coalesces database mutations into foreground export runs.  It deliberately
/// has no background-worker dependency: the user chose foreground lifecycle
/// synchronization only.
class HealthExportCoordinator {
  HealthExportCoordinator(
      {required AppDatabase database,
      HealthExportService? service,
      Duration debounceDuration = const Duration(seconds: 2)})
      : _database = database,
        _debounceDuration = debounceDuration,
        _service = service ??
            HealthExportService(adapters: [
              AppleHealthExportAdapter(),
              HealthConnectExportAdapter(),
            ]);

  final AppDatabase _database;
  final HealthExportService _service;
  final Duration _debounceDuration;
  StreamSubscription<Set<TableUpdate>>? _subscription;
  Timer? _debounce;
  bool _running = false;
  bool _rerunRequested = false;

  void start() {
    if (_subscription != null) return;
    const watchedTables = {
      'measurements',
      'nutrition_logs',
      'fluid_logs',
      'workout_logs',
      'set_logs',
    };
    _subscription = _database.tableUpdates().listen((updates) {
      if (updates.any((update) => watchedTables.contains(update.table))) {
        schedule();
      }
    });
    schedule();
  }

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, syncNow);
  }

  Future<void> syncNow() async {
    if (_running) {
      _rerunRequested = true;
      return;
    }
    _running = true;
    try {
      for (final platform in HealthExportPlatform.values) {
        if (await _service.isPlatformEnabled(platform)) {
          await _service.exportNow(platform);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Automatic health export failed: $error\n$stackTrace');
    } finally {
      _running = false;
      if (_rerunRequested) {
        _rerunRequested = false;
        schedule();
      }
    }
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }
}

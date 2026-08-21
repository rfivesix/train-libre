// lib/features/supplements/presentation/supplements_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/repositories/supplement_repository.dart';
import '../data/supplement_repository_impl.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/models/tracked_supplement.dart';
import '../data/sources/supplement_local_data_source.dart';

class SupplementsViewModel extends ChangeNotifier {
  final SupplementRepository _repository;

  SupplementRepository get repository => _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  final Map<int, Supplement> _supplementsById = {};
  Map<int, Supplement> get supplementsById => _supplementsById;

  List<TrackedSupplement> _tracked = const [];
  List<TrackedSupplement> get tracked => _tracked;

  List<SupplementLog> _todaysLogs = const [];
  List<SupplementLog> get todaysLogs => _todaysLogs;

  StreamSubscription<List<Supplement>>? _supplementsForDateSubscription;
  StreamSubscription<List<SupplementLog>>? _logsSubscription;
  StreamSubscription<List<Supplement>>? _allSupplementsSubscription;

  List<Supplement> _supplementsForDateList = const [];
  List<SupplementLog> _logsList = const [];
  List<Supplement> _allSupplementsList = const [];

  bool _hasReceivedSupplements = false;
  bool _hasReceivedLogs = false;
  bool _hasReceivedAll = false;

  SupplementsViewModel({SupplementRepository? repository})
      : _repository = repository ??
            SupplementRepositoryImpl(
              localDataSource: SupplementLocalDataSource.instance,
            ) {
    _listenToStreams();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _listenToStreams();
  }

  void navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;
    _selectedDate = newDay;
    _listenToStreams();
  }

  void _listenToStreams() {
    _cancelSubscriptions();

    _isLoading = true;
    _hasReceivedSupplements = false;
    _hasReceivedLogs = false;
    _hasReceivedAll = false;
    notifyListeners();

    final date = _selectedDate;

    _supplementsForDateSubscription =
        _repository.watchSupplementsForDate(date).listen(
      (data) {
        _supplementsForDateList = data;
        _hasReceivedSupplements = true;
        _updateCalculatedState();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint("Error watching supplements for date: $e");
        notifyListeners();
      },
    );

    _logsSubscription = _repository.watchSupplementLogsForDate(date).listen(
      (data) {
        _logsList = data;
        _hasReceivedLogs = true;
        _updateCalculatedState();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint("Error watching supplement logs: $e");
        notifyListeners();
      },
    );

    _allSupplementsSubscription = _repository.watchAllSupplements().listen(
      (data) {
        _allSupplementsList = data;
        _hasReceivedAll = true;
        _updateCalculatedState();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint("Error watching all supplements: $e");
        notifyListeners();
      },
    );
  }

  void _updateCalculatedState() {
    final byId = <int, Supplement>{
      for (final s in _supplementsForDateList)
        if (s.id != null) s.id!: s,
    };

    for (final s in _allSupplementsList) {
      if (s.id != null && byId[s.id!] == null) {
        byId[s.id!] = s;
      }
    }

    // BOLT OPTIMIZATION: Avoid closure allocations, redundant Map hash lookups, and O(N^2) `.any()` iterations.
    final doses = <int, double>{};
    for (final log in _logsList) {
      final currentDose = doses[log.supplementId];
      if (currentDose != null) {
        doses[log.supplementId] = currentDose + log.dose;
      } else {
        doses[log.supplementId] = log.dose;
      }
    }

    final List<TrackedSupplement> tracked = [];
    final Set<int> trackedIds = {};
    for (final s in _supplementsForDateList) {
      final double? dose = doses[s.id];
      if (s.isTracked || dose != null) {
        tracked.add(
          TrackedSupplement(supplement: s, totalDosedToday: dose ?? 0.0),
        );
        if (s.id != null) {
          trackedIds.add(s.id!);
        }
      }
    }

    for (final id in doses.keys) {
      if (!trackedIds.contains(id)) {
        final supplement = byId[id];
        if (supplement != null) {
          tracked.add(
            TrackedSupplement(
              supplement: supplement,
              totalDosedToday: doses[id]!,
            ),
          );
        }
      }
    }

    _supplementsById.clear();
    _supplementsById.addAll(byId);
    _tracked = tracked;
    _todaysLogs = _logsList;

    if (_hasReceivedSupplements && _hasReceivedLogs && _hasReceivedAll) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadData() async {
    _listenToStreams();
  }

  Future<List<Supplement>> getAllSupplementsDirect() {
    // ignore: deprecated_member_use_from_same_package
    return _repository.getAllSupplements();
  }

  Future<void> addSupplement(Supplement supplement) async {
    await _repository.insertSupplement(supplement);
  }

  Future<void> updateSupplement(Supplement supplement) async {
    await _repository.updateSupplement(supplement);
  }

  Future<void> deleteSupplement(int id) async {
    await _repository.deleteSupplement(id);
  }

  Future<void> logSupplementDose(
      Supplement supplement, double dose, DateTime timestamp) async {
    final log = SupplementLog(
      supplementId: supplement.id!,
      dose: dose,
      unit: supplement.unit,
      timestamp: timestamp,
    );
    await _repository.insertSupplementLog(log);
  }

  Future<void> updateSupplementLog(SupplementLog log) async {
    await _repository.updateSupplementLog(log);
  }

  Future<void> deleteSupplementLog(int id) async {
    await _repository.deleteSupplementLog(id);
  }

  Future<void> insertSupplementLogRaw(SupplementLog log) async {
    await _repository.insertSupplementLog(log);
  }

  void _cancelSubscriptions() {
    _supplementsForDateSubscription?.cancel();
    _logsSubscription?.cancel();
    _allSupplementsSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

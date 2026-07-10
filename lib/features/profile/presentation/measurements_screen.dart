// lib/features/profile/presentation/measurements_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/profile_repository.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/measurement.dart';
import '../domain/models/measurement_session.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import 'widgets/measurement_chart_widget.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../util/l10n_ext.dart';
import '../../../widgets/common/swipe_action_background.dart';
import '../../../services/unit_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../../util/date_util.dart';
import '../../../features/statistics/domain/timeframe_block.dart';
import '../../../util/timeframe_label_formatter.dart';

/// A screen for viewing and analyzing body measurement history.
class MeasurementsScreen extends StatefulWidget {
  final IProfileRepository? repository;

  const MeasurementsScreen({super.key, this.repository});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  late final IProfileRepository _repository =
      widget.repository ?? context.read<IProfileRepository>();

  bool _isLoading = true;
  List<MeasurementSession> _sessions = [];
  String? _selectedChartType;
  List<String> _availableMeasurementTypes = [];

  // --- Unified TimeframeBlock state (same logic as Statistics Hub) ---
  static const _blocks = [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.maxBlock,
  ];
  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();
  bool _isRolling = true;

  List<String> _timeRangeLabels(AppLocalizations l10n) => [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filterMax,
      ];

  DateTimeRange get _activeDateRange {
    if (_isRolling) return _activeBlock.getRollingBounds();
    return _activeBlock.getBounds(_anchorDate, DateTime(2020));
  }

  String? _rangeDisplayLabel(AppLocalizations l10n) {
    if (_activeBlock == TimeframeBlock.maxBlock) return l10n.filterMax;
    if (_isRolling) {
      return TimeframeLabelFormatter.formatRolling(_activeBlock, l10n);
    }
    return TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n);
  }

  void _shiftTimeframe(bool backwards) {
    setState(() {
      if (_activeBlock == TimeframeBlock.maxBlock) return;

      final now = DateTime.now();
      final currentBounds = _activeBlock.getBounds(now, DateTime(2020));
      final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
      final isOngoing =
          !_isRolling && myBounds.start.isAtSameMomentAs(currentBounds.start);

      if (backwards) {
        if (isOngoing && _activeBlock != TimeframeBlock.day) {
          _isRolling = true;
        } else if (_isRolling) {
          _isRolling = false;
          _anchorDate = _activeBlock.shift(now, -1);
        } else {
          _anchorDate = _activeBlock.shift(_anchorDate, -1);
        }
      } else {
        if (_isRolling) {
          _isRolling = false;
          _anchorDate = now;
        } else {
          final previousAnchor = _activeBlock.shift(now, -1);
          final previousBounds =
              _activeBlock.getBounds(previousAnchor, DateTime(2020));
          final isPreviousToOngoing = !_isRolling &&
              myBounds.start.isAtSameMomentAs(previousBounds.start);

          if (isPreviousToOngoing && _activeBlock != TimeframeBlock.day) {
            _isRolling = true;
          } else {
            _anchorDate = _activeBlock.shift(_anchorDate, 1);
          }
        }
      }
    });
  }

  bool get _nextEnabled {
    if (_activeBlock == TimeframeBlock.maxBlock) return false;
    if (_isRolling) return false;
    final now = DateTime.now();
    final currentBounds = _activeBlock.getBounds(now, DateTime(2020));
    final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
    return !myBounds.start.isAtSameMomentAs(currentBounds.start);
  }

  List<MeasurementSession> get _filteredSessions {
    final range = _activeDateRange;
    return _sessions
        .where((s) =>
            s.timestamp.isAfter(range.start) &&
            s.timestamp.isBefore(range.end.add(const Duration(seconds: 1))))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _repository.getMeasurementSessions();
      final Set<String> types = {};
      for (final session in sessions) {
        for (final measurement in session.measurements) {
          types.add(measurement.type);
        }
      }
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _availableMeasurementTypes = types.toList()..sort();
          if (_selectedChartType == null &&
              _availableMeasurementTypes.isNotEmpty) {
            _selectedChartType = _availableMeasurementTypes.contains('weight')
                ? 'weight'
                : _availableMeasurementTypes.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading measurements: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeasurementSession(MeasurementSession session) async {
    final sessionId = session.id;
    if (sessionId == null) {
      await _loadMeasurements();
      return;
    }
    try {
      await _repository.deleteMeasurementSession(sessionId);
    } finally {
      if (mounted) await _loadMeasurements();
    }
  }

  void _showMeasurementBottomMenu({MeasurementSession? existingSession}) {
    final l10n = AppLocalizations.of(context)!;
    showGlassBottomMenu<bool?>(
      context: context,
      title: existingSession != null
          ? l10n.addMeasurementDialogTitle
          : l10n.addMeasurement,
      contentBuilder: (ctx, close) {
        return MeasurementFormSheet(
          repository: _repository,
          existingSession: existingSession,
          onSaved: () {
            close();
            _loadMeasurements();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.measurementsScreenTitle),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: _sessions.isEmpty,
        extendBodyBehindAppBar: true,
        fallback: _buildEmptyState(l10n, context),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: topPadding + DesignConstants.spacingM,
                left: 0,
                right: 0,
                bottom: 0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Unified time range filter (identical to Statistics Hub) ──
                  TimeRangeFilter(
                    ranges: _timeRangeLabels(l10n),
                    selectedIndex: _blocks.indexOf(_activeBlock),
                    onSelected: (index) {
                      setState(() {
                        _activeBlock = _blocks[index];
                        _isRolling = _activeBlock != TimeframeBlock.maxBlock;
                        _anchorDate = DateTime.now();
                      });
                    },
                    onPrevious: _activeBlock == TimeframeBlock.maxBlock
                        ? null
                        : () => _shiftTimeframe(true),
                    onNext: _nextEnabled ? () => _shiftTimeframe(false) : null,
                    displayDate: _rangeDisplayLabel(l10n),
                    onTapDateDisplay: _activeBlock == TimeframeBlock.maxBlock
                        ? null
                        : () async {
                            final selected = await adaptive_pickers
                                .showAdaptiveTimeframePicker(
                              context: context,
                              activeBlock: _activeBlock,
                              initialAnchor: _anchorDate,
                              initialIsRolling: _isRolling,
                              earliestAvailableDay: DateTime(2020),
                            );
                            if (selected != null) {
                              setState(() {
                                _anchorDate = selected.anchorDate;
                                _isRolling = selected.isRolling;
                              });
                            }
                          },
                    nextEnabled: _nextEnabled,
                    showDateNavigation: _activeBlock != TimeframeBlock.maxBlock,
                  ),
                  const SizedBox(height: DesignConstants.spacingL),

                  // ── Chart (follows same date range) ──
                  if (_availableMeasurementTypes.isNotEmpty) ...[
                    _buildChartSection(l10n, colorScheme, textTheme),
                    const SizedBox(height: DesignConstants.spacingXL),
                  ],

                  // ── Session list header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: AppSectionHeader(title: l10n.all_measurements),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),

                  // ── Filtered sessions ──
                  ..._filteredSessions.map(
                    (session) => _buildSessionCard(
                        l10n, colorScheme, textTheme, session),
                  ),
                  if (_filteredSessions.isEmpty)
                    Padding(
                      padding: DesignConstants.cardPadding,
                      child: Center(
                        child: Text(
                          l10n.measurementsEmptyState,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const BottomContentSpacer(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GlassFab(
        label: l10n.addMeasurement,
        onPressed: () => _showMeasurementBottomMenu(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.measurementsEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: () => _showMeasurementBottomMenu(),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.addMeasurement),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final unitService = context.watch<UnitService>();
    if (_selectedChartType == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.screenPaddingHorizontal,
          ),
          child: PlatformAdaptiveDropdownFormField<String>(
            value: _selectedChartType,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedChartType = newValue);
              }
            },
            items: _availableMeasurementTypes
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(l10n.getLocalizedMeasurementName(value)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        MeasurementChartWidget(
          chartType: _selectedChartType!,
          dateRange: _activeDateRange,
          unit: _getMeasurementUnit(_selectedChartType!, unitService),
          repository: _repository,
          edgeToEdge: true,
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    MeasurementSession session,
  ) {
    final unitService = context.watch<UnitService>();
    final locale = Localizations.localeOf(context).toString();
    final sortedMeasurements = session.measurements.toList()
      ..sort((a, b) => a.type.compareTo(b.type));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.screenPaddingHorizontal,
      ),
      child: Dismissible(
        key: Key(
            'session_${session.id}_${session.timestamp.millisecondsSinceEpoch}'),
        direction: DismissDirection.horizontal,
        background: const SwipeActionBackground(
          color: Colors.blueAccent,
          icon: LucideIcons.pencil,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: const SwipeActionBackground(
          color: Colors.redAccent,
          icon: LucideIcons.trash_2,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _showMeasurementBottomMenu(existingSession: session);
            return false;
          }
          return await showDeleteConfirmation(context);
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            setState(() {
              _sessions.removeWhere((s) =>
                  (s.id != null && s.id == session.id) ||
                  (s.id == null && s.timestamp == session.timestamp));
            });
            _deleteMeasurementSession(session);
          }
        },
        child: SummaryCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMEEEEd(locale)
                      .add_Hm()
                      .format(session.timestamp),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...sortedMeasurements.map((m) {
                  final value =
                      _displayMeasurementValue(m.type, m.value, unitService)
                          .toStringAsFixed(1);
                  final unit = _getMeasurementUnit(m.type, unitService);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          _getMeasurementIconData(m.type),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.getLocalizedMeasurementName(m.type),
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '$value $unit'.trim(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _displayMeasurementValue(
      String type, double value, UnitService unitService) {
    switch (type) {
      case 'weight':
        return unitService.convertDisplayValue(value, UnitDimension.weight);
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'abdomen':
      case 'waist':
      case 'hips':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return unitService.convertDisplayValue(value, UnitDimension.height);
      default:
        return value;
    }
  }

  String _getMeasurementUnit(String type, UnitService unitService) {
    switch (type) {
      case 'weight':
        return unitService.suffixFor(UnitDimension.weight);
      case 'fat_percent':
        return '%';
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'abdomen':
      case 'waist':
      case 'hips':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return unitService.suffixFor(UnitDimension.height);
      default:
        return '';
    }
  }

  IconData _getMeasurementIconData(String type) {
    switch (type) {
      case 'weight':
        return LucideIcons.scale;
      case 'fat_percent':
        return LucideIcons.dumbbell;
      default:
        return LucideIcons.ruler;
    }
  }
}

/// Public measurement form sheet — used inside the bottom menu (add + edit)
/// Also used from main_screen.dart for the global add action.
class MeasurementFormSheet extends StatefulWidget {
  final IProfileRepository? repository;
  final MeasurementSession? existingSession;
  final DateTime? initialDate;
  final VoidCallback onSaved;

  const MeasurementFormSheet({
    super.key,
    this.repository,
    this.existingSession,
    this.initialDate,
    required this.onSaved,
  });

  @override
  State<MeasurementFormSheet> createState() => _MeasurementFormSheetState();
}

class _MeasurementFormSheetState extends State<MeasurementFormSheet> {
  late final IProfileRepository _repository;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late DateTime _selectedDateTime;

  final Map<String, String> _measurementTypes = {
    'weight': 'kg',
    'fat_percent': '%',
    'waist': 'cm',
    'abdomen': 'cm',
    'hips': 'cm',
    'neck': 'cm',
    'shoulder': 'cm',
    'chest': 'cm',
    'left_bicep': 'cm',
    'right_bicep': 'cm',
    'left_forearm': 'cm',
    'right_forearm': 'cm',
    'left_thigh': 'cm',
    'right_thigh': 'cm',
    'left_calf': 'cm',
    'right_calf': 'cm',
  };

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<IProfileRepository>();
    _selectedDateTime = (widget.existingSession?.timestamp ??
            widget.initialDate ??
            DateTime.now())
        .withCurrentTime;
    for (var key in _measurementTypes.keys) {
      _controllers[key] = TextEditingController();
    }
    if (widget.existingSession != null) {
      _selectedDateTime = widget.existingSession!.timestamp;
      final unitService = context.read<UnitService>();
      for (final m in widget.existingSession!.measurements) {
        final dimension = _measurementDimension(m.type);
        final displayValue = dimension == null
            ? m.value
            : unitService.convertDisplayValue(m.value, dimension);
        final text = displayValue % 1 == 0
            ? displayValue.toInt().toString()
            : displayValue.toStringAsFixed(1);
        _controllers[m.type]?.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  UnitDimension? _measurementDimension(String key) {
    switch (key) {
      case 'weight':
        return UnitDimension.weight;
      case 'waist':
      case 'abdomen':
      case 'hips':
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return UnitDimension.height;
      default:
        return null;
    }
  }

  String _displayUnit(String key, UnitService unitService) {
    final dimension = _measurementDimension(key);
    if (dimension == null) return _measurementTypes[key] ?? '';
    return unitService.suffixFor(dimension);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await adaptive_pickers.showAdaptiveDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(picked.year, picked.month, picked.day,
            _selectedDateTime.hour, _selectedDateTime.minute);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await adaptive_pickers.showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
            picked.hour,
            picked.minute);
      });
    }
  }

  void _saveSession() async {
    final unitService = context.read<UnitService>();
    final List<Measurement> measurements = [];
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        final value = double.tryParse(controller.text.replaceAll(',', '.'));
        if (value != null) {
          final dimension = _measurementDimension(key);
          final metricValue = dimension == null
              ? value
              : unitService.convertToMetric(value, dimension);
          measurements.add(Measurement(
            sessionId: widget.existingSession?.id ?? 0,
            type: key,
            value: metricValue,
            unit: _measurementTypes[key]!,
          ));
        }
      }
    });

    if (widget.existingSession?.id != null) {
      await _repository.deleteMeasurementSession(widget.existingSession!.id!);
    }
    if (measurements.isNotEmpty) {
      await _repository.insertMeasurementSession(
        MeasurementSession(
            timestamp: _selectedDateTime, measurements: measurements),
      );
    }
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(LucideIcons.calendar, size: 20),
                label: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _selectDate,
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.clock, size: 20),
                label: Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _selectTime,
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: DesignConstants.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ..._measurementTypes.keys.map((key) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingM,
                          ),
                          child: TextFormField(
                            controller: _controllers[key],
                            decoration: InputDecoration(
                              labelText: l10n.getLocalizedMeasurementName(key),
                              suffixText: _displayUnit(key, unitService),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value.replaceAll(',', '.')) ==
                                      null) {
                                return l10n.validatorPleaseEnterNumber;
                              }
                              return null;
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          FilledButton(onPressed: _saveSession, child: Text(l10n.save)),
        ],
      ),
    );
  }
}

import re

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "r") as f:
    content = f.read()

# 1. Update Enum
content = content.replace(
    "enum ExerciseMetric { maxWeight, volume, est1rm }",
    "enum ExerciseMetric { maxWeight, volume, est1rm, distance, duration, pace }"
)

# 2. Update initstate metric selection
init_metric_search = "ExerciseMetric _selectedMetric = ExerciseMetric.maxWeight;"
init_metric_replace = "late ExerciseMetric _selectedMetric = widget.exercise.isCardio ? ExerciseMetric.distance : ExerciseMetric.maxWeight;"
content = content.replace(init_metric_search, init_metric_replace)

# 3. Update data fetch
data_fetch_search = """    final prs = await _repository.getExercisePRs(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final timeSeries = await _repository.getExerciseTimeSeriesData(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );"""
data_fetch_replace = """    final prs = await _repository.getExercisePRs(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );

    final timeSeries = await _repository.getExerciseTimeSeriesData(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );"""
content = content.replace(data_fetch_search, data_fetch_replace)

# 4. Hide Body Map
body_map_search = """            AppSectionHeader(title: l10n.involvedMuscles),
            RepaintBoundary(
              child: _ExerciseMuscleBodyView(exercise: _currentExercise),
            ),
            const SizedBox(height: DesignConstants.spacingXL),"""
body_map_replace = """            if (!_currentExercise.isCardio) ...[
              AppSectionHeader(title: l10n.involvedMuscles),
              RepaintBoundary(
                child: _ExerciseMuscleBodyView(exercise: _currentExercise),
              ),
              const SizedBox(height: DesignConstants.spacingXL),
            ],"""
content = content.replace(body_map_search, body_map_replace)

# 5. Build PR Summary Section
pr_summary_search = """    final items = _prMap.entries.map((entry) {
      final bracket = entry.key;
      final prSet = entry.value;

      String value;
      String subtitle;
      Color? valueColor;

      if (prSet != null) {
        if (bracket == 'Est. 1RM') {
          value = '${context.read<UnitService>().convertDisplayValue(prSet.weightKg! * (36 / (37 - prSet.reps!)), UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
        } else {
          value = '${context.read<UnitService>().convertDisplayValue(prSet.weightKg ?? 0.0, UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
        }
        subtitle = l10n.repsCount(prSet.reps!);
        valueColor = theme.colorScheme.primary;
      } else {
        value = '-';
        subtitle = l10n.noData;
        valueColor = theme.colorScheme.onSurfaceVariant;
      }

      return ValueSummaryCard(
        label: bracket,
        value: value,
        subtitle: subtitle,
        valueColor: valueColor,
      );
    }).toList();"""

pr_summary_replace = """    final items = _prMap.entries.map((entry) {
      final bracket = entry.key;
      final prSet = entry.value;

      String value;
      String subtitle;
      Color? valueColor;

      if (prSet != null) {
        if (_currentExercise.isCardio) {
          if (bracket == 'Best Distance') {
            value = '${prSet.distanceKm?.toStringAsFixed(2) ?? '0.0'} km';
            subtitle = _formatDuration(prSet.durationSeconds ?? 0);
          } else if (bracket == 'Longest Duration') {
            value = _formatDuration(prSet.durationSeconds ?? 0);
            subtitle = '${prSet.distanceKm?.toStringAsFixed(2) ?? '0.0'} km';
          } else if (bracket == 'Fastest Pace') {
            final dur = prSet.durationSeconds ?? 0;
            final dist = prSet.distanceKm ?? 0.0;
            if (dist > 0) {
              final paceSec = dur / dist;
              value = '${_formatDuration(paceSec.round())} / km';
            } else {
              value = '-';
            }
            subtitle = '';
          } else {
            value = '-';
            subtitle = '-';
          }
        } else {
          if (bracket == 'Est. 1RM') {
            value = '${context.read<UnitService>().convertDisplayValue(prSet.weightKg! * (36 / (37 - prSet.reps!)), UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
          } else {
            value = '${context.read<UnitService>().convertDisplayValue(prSet.weightKg ?? 0.0, UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}';
          }
          subtitle = l10n.repsCount(prSet.reps!);
        }
        valueColor = theme.colorScheme.primary;
      } else {
        value = '-';
        subtitle = l10n.noData;
        valueColor = theme.colorScheme.onSurfaceVariant;
      }

      return ValueSummaryCard(
        label: bracket,
        value: value,
        subtitle: subtitle,
        valueColor: valueColor,
      );
    }).toList();"""
content = content.replace(pr_summary_search, pr_summary_replace)

format_duration_helper = """
  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPRSummarySection"""
content = content.replace("  Widget _buildPRSummarySection", format_duration_helper)


# 6. Chart data parsing
chart_data_search = """      switch (_selectedMetric) {
        case ExerciseMetric.maxWeight:
          y = (e['maxWeight'] as num).toDouble();
          break;
        case ExerciseMetric.volume:
          y = (e['totalVolume'] as num).toDouble();
          break;
        case ExerciseMetric.est1rm:
          y = (e['maxEst1rm'] as num).toDouble();
          break;
      }"""
chart_data_replace = """      switch (_selectedMetric) {
        case ExerciseMetric.maxWeight:
          y = (e['maxWeight'] as num).toDouble();
          break;
        case ExerciseMetric.volume:
          y = (e['totalVolume'] as num).toDouble();
          break;
        case ExerciseMetric.est1rm:
          y = (e['maxEst1rm'] as num).toDouble();
          break;
        case ExerciseMetric.distance:
          y = (e['maxDistance'] as num).toDouble();
          break;
        case ExerciseMetric.duration:
          y = (e['totalDuration'] as num).toDouble(); // Display in seconds or minutes? Let's keep seconds and format label, or minutes
          y = y / 60.0; // Minutes
          break;
        case ExerciseMetric.pace:
          y = (e['maxPace'] as num).toDouble() / 60.0; // Minutes per km
          break;
      }"""
content = content.replace(chart_data_search, chart_data_replace)

chart_unit_search = "unit: unitService.suffixFor(UnitDimension.weight),"
chart_unit_replace = """unit: _selectedMetric == ExerciseMetric.distance ? 'km' : (_selectedMetric == ExerciseMetric.duration ? 'min' : (_selectedMetric == ExerciseMetric.pace ? 'min/km' : unitService.suffixFor(UnitDimension.weight))),"""
content = content.replace(chart_unit_search, chart_unit_replace)

# 7. Chart Header
chart_header_search = """            items: [
              DropdownMenuItem(
                value: ExerciseMetric.maxWeight,
                child: Text(l10n.exerciseMetricMaxWeight),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.volume,
                child: Text(l10n.exerciseMetricVolume),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.est1rm,
                child: Text(l10n.exerciseMetricEst1RM),
              ),
            ],"""
chart_header_replace = """            items: _currentExercise.isCardio ? [
              DropdownMenuItem(
                value: ExerciseMetric.distance,
                child: Text('Distance'),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.duration,
                child: Text('Duration'),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.pace,
                child: Text('Pace'),
              ),
            ] : [
              DropdownMenuItem(
                value: ExerciseMetric.maxWeight,
                child: Text(l10n.exerciseMetricMaxWeight),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.volume,
                child: Text(l10n.exerciseMetricVolume),
              ),
              DropdownMenuItem(
                value: ExerciseMetric.est1rm,
                child: Text(l10n.exerciseMetricEst1RM),
              ),
            ],"""
content = content.replace(chart_header_search, chart_header_replace)

# 8. Localize muscle chips
chip_row_search = """                return Text(
                  m,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );"""
chip_row_replace = """                return Text(
                  BodySlugMapper.localize(context, m),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );"""
content = content.replace(chip_row_search, chip_row_replace)

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "w") as f:
    f.write(content)


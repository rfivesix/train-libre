import re

file = "lib/features/analytics/presentation/statistics_hub_view_model.dart"
with open(file, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update HubRangeContext definition
content = re.sub(
    r'class HubRangeContext \{\s*final TimeframeBlock selectedBlockType;\s*final int daysBack;\s*const HubRangeContext\(\{\s*required this\.selectedBlockType,\s*required this\.daysBack,\s*\}\);\s*\}',
    r'class HubRangeContext {\n  final TimeframeBlock selectedBlockType;\n  final int daysBack;\n  final DateTime endDate;\n\n  const HubRangeContext({\n    required this.selectedBlockType,\n    required this.daysBack,\n    required this.endDate,\n  });\n}',
    content
)

# 2. Update _resolveHubRangeContext
resolve_old = r'''  Future<HubRangeContext> _resolveHubRangeContext\(\{
    required TimeframeBlock selectedBlockType,
  \}\) async \{
    final earliest = await PerfDebugTimer\.time\(
      area: 'statistics',
      label: 'stepsEarliest',
      action: _stepsRepository\.getEarliestAvailableDate,
    \);
    final resolvedRange = _rangePolicy\.resolve\(
      metricId: StatisticsMetricId\.bodyNutritionTrend,
      selectedBlockType: selectedBlockType,
      now: _anchorDate,
      earliestAvailableDay: earliest,
    \);
    return HubRangeContext\(
      selectedBlockType: selectedBlockType,
      daysBack: resolvedRange\.effectiveDays \?\? 30,
    \);
  \}'''

resolve_new = r'''  Future<HubRangeContext> _resolveHubRangeContext({
    required TimeframeBlock selectedBlockType,
  }) async {
    final earliest = await PerfDebugTimer.time(
      area: 'statistics',
      label: 'stepsEarliest',
      action: _stepsRepository.getEarliestAvailableDate,
    );
    DateTimeRange dateRange;
    if (_isRolling) {
      dateRange = selectedBlockType.getRollingBounds();
    } else {
      final resolvedRange = _rangePolicy.resolve(
        metricId: StatisticsMetricId.bodyNutritionTrend,
        selectedBlockType: selectedBlockType,
        now: _anchorDate,
        earliestAvailableDay: earliest,
      );
      dateRange = resolvedRange.dateRange ?? DateTimeRange(start: _anchorDate, end: _anchorDate);
    }
    return HubRangeContext(
      selectedBlockType: selectedBlockType,
      daysBack: dateRange.end.difference(dateRange.start).inDays + 1,
      endDate: dateRange.end,
    );
  }'''

content = re.sub(resolve_old, resolve_new, content)

# 3. Update _loadStepsSection
content = re.sub(
    r'final endDate = DateTime\.now\(\);',
    r'final endDate = rangeContext.endDate;',
    content
)

# 4. Update _loadSleepSection
content = re.sub(
    r'final summary = await _sleepSummaryRepository\.fetchSummary\(\s*endDate: DateTime\.now\(\),\s*daysBack: rangeContext\.daysBack,\s*\);',
    r'final summary = await _sleepSummaryRepository.fetchSummary(\n        endDate: rangeContext.endDate,\n        daysBack: rangeContext.daysBack,\n      );',
    content
)

with open(file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated statistics_hub_view_model.dart")

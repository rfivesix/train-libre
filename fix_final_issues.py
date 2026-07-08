import re

# 1. sleep_period_scope_layout.dart nextEnabled fix
file_layout = "lib/features/sleep/presentation/widgets/sleep_period_scope_layout.dart"
with open(file_layout, 'r', encoding='utf-8') as f:
    content = f.read()
content = re.sub(
    r'nextEnabled: !isRolling,',
    r'nextEnabled: isRolling ? false : selectedScope.block.getBounds(anchorDate, DateTime(2020)).end.isBefore(DateTime.now()),',
    content
)
with open(file_layout, 'w', encoding='utf-8') as f:
    f.write(content)

# 2. statistics_hub_screen.dart nextEnabled and shiftTimeframe call fix
file_hub = "lib/features/analytics/presentation/statistics_hub_screen.dart"
with open(file_hub, 'r', encoding='utf-8') as f:
    content = f.read()

# fix nextEnabled
content = re.sub(
    r'nextEnabled: viewModel\.activeBlockType != TimeframeBlock\.maxBlock && viewModel\.anchorDate\.isBefore\(DateTime\.now\(\)\),',
    r'nextEnabled: viewModel.activeBlockType != TimeframeBlock.maxBlock && !viewModel.isRolling,',
    content
)

# fix shiftTimeframe call (previous should be true, next should be false)
content = re.sub(
    r'onPrevious: viewModel\.activeBlockType == TimeframeBlock\.maxBlock \? null : \(\) => viewModel\.shiftTimeframe\(true\),',
    r'onPrevious: viewModel.activeBlockType == TimeframeBlock.maxBlock ? null : () => viewModel.shiftTimeframe(true),',
    content
)
content = re.sub(
    r'onNext: viewModel\.activeBlockType == TimeframeBlock\.maxBlock \? null : \(\) => viewModel\.shiftTimeframe\(false\),',
    r'onNext: viewModel.activeBlockType == TimeframeBlock.maxBlock ? null : () => viewModel.shiftTimeframe(false),',
    content
)
with open(file_hub, 'w', encoding='utf-8') as f:
    f.write(content)

# 3. statistics_hub_view_model.dart shiftTimeframe fix to support traversal order
file_vm = "lib/features/analytics/presentation/statistics_hub_view_model.dart"
with open(file_vm, 'r', encoding='utf-8') as f:
    content = f.read()

shift_vm_rep = r'''  void shiftTimeframe(bool backwards) {
    if (_activeBlockType == TimeframeBlock.maxBlock) return;
    
    if (backwards) {
      if (!_isRolling) {
        final currentBounds = _activeBlockType.getBounds(DateTime.now(), DateTime(2020));
        final myBounds = _activeBlockType.getBounds(_anchorDate, DateTime(2020));
        if (myBounds.start.isAtSameMomentAs(currentBounds.start) || myBounds.start.isAfter(currentBounds.start)) {
          _isRolling = true;
        } else {
          _anchorDate = _activeBlockType.shift(_anchorDate, -1);
        }
      } else {
        _isRolling = false;
        _anchorDate = _activeBlockType.shift(DateTime.now(), -1);
      }
    } else {
      if (_isRolling) {
        _isRolling = false;
        _anchorDate = DateTime.now();
      } else {
        final currentBounds = _activeBlockType.getBounds(DateTime.now(), DateTime(2020));
        final myBounds = _activeBlockType.getBounds(_anchorDate, DateTime(2020));
        final nextAnchor = _activeBlockType.shift(_anchorDate, 1);
        final nextBounds = _activeBlockType.getBounds(nextAnchor, DateTime(2020));
        if (nextBounds.start.isAtSameMomentAs(currentBounds.start) || nextBounds.start.isAfter(currentBounds.start)) {
          _isRolling = true;
        } else {
          _anchorDate = nextAnchor;
        }
      }
    }
    loadHubAnalytics();
  }'''

content = re.sub(
    r'  void shiftTimeframe\(bool forward\) \{[^\}]+loadHubAnalytics\(\);\s*\}',
    shift_vm_rep,
    content
)
with open(file_vm, 'w', encoding='utf-8') as f:
    f.write(content)


# 4. Traversal fixes in remaining screens
screens = [
    "lib/features/analytics/presentation/consistency_tracker_screen.dart",
    "lib/features/analytics/presentation/body_nutrition_correlation_screen.dart",
    "lib/features/analytics/presentation/muscle_group_analytics_screen.dart",
    "lib/features/analytics/presentation/pr_dashboard_screen.dart"
]

for filepath in screens:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Load command
    load_cmd = "_load();" if "body_nutrition" in filepath else "_loadData();"

    # Match onPrevious (it could be prefixed with _activeBlock == TimeframeBlock.maxBlock ? null : )
    # Let's match the function body inside onPrevious:
    content = re.sub(
        r'onPrevious: (?:_activeBlock == TimeframeBlock\.maxBlock \? null : )?\(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) \{\s*_isRolling = false;\s*_anchorDate = DateTime\.now\(\);\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, -1\);\s*\}\s*\}\);\s*(?:_load\(\)|_loadData\(\));\s*\},',
        f'''onPrevious: _activeBlock == TimeframeBlock.maxBlock ? null : () {{
                setState(() {{
                  if (!_isRolling) {{
                    final currentBounds = _activeBlock.getBounds(DateTime.now(), DateTime(2020));
                    final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
                    if (myBounds.start.isAtSameMomentAs(currentBounds.start) || myBounds.start.isAfter(currentBounds.start)) {{
                      _isRolling = true;
                    }} else {{
                      _anchorDate = _activeBlock.shift(_anchorDate, -1);
                    }}
                  }} else {{
                    _isRolling = false;
                    _anchorDate = _activeBlock.shift(DateTime.now(), -1);
                  }}
                }});
                {load_cmd}
              }},''',
        content
    )

    # Match onNext
    content = re.sub(
        r'onNext: (?:_activeBlock == TimeframeBlock\.maxBlock \? null : )?\(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) return;\s*final currentBounds = _activeBlock\.getBounds\(DateTime\.now\(\), DateTime\(2020\)\);\s*final myBounds = _activeBlock\.getBounds\(_anchorDate, DateTime\(2020\)\);\s*if \(myBounds\.start\.isAtSameMomentAs\(currentBounds\.start\) \|\| myBounds\.start\.isAfter\(currentBounds\.start\)\) \{\s*_isRolling = true;\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, 1\);\s*\}\s*\}\);\s*(?:_load\(\)|_loadData\(\));\s*\},',
        f'''onNext: _activeBlock == TimeframeBlock.maxBlock ? null : () {{
                setState(() {{
                  if (_isRolling) {{
                    _isRolling = false;
                    _anchorDate = DateTime.now();
                  }} else {{
                    final currentBounds = _activeBlock.getBounds(DateTime.now(), DateTime(2020));
                    final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
                    final nextAnchor = _activeBlock.shift(_anchorDate, 1);
                    final nextBounds = _activeBlock.getBounds(nextAnchor, DateTime(2020));
                    if (nextBounds.start.isAtSameMomentAs(currentBounds.start) || nextBounds.start.isAfter(currentBounds.start)) {{
                      _isRolling = true;
                    }} else {{
                      _anchorDate = nextAnchor;
                    }}
                  }}
                }});
                {load_cmd}
              }},''',
        content
    )

    # nextEnabled
    # It could be: nextEnabled: !_isRolling, OR nextEnabled: _activeBlock != TimeframeBlock.maxBlock && _anchorDate.isBefore(DateTime.now()),
    content = re.sub(
        r'nextEnabled: !_isRolling,',
        r'nextEnabled: _isRolling ? true : !_activeBlock.getBounds(_anchorDate, DateTime(2020)).start.isAtSameMomentAs(_activeBlock.getBounds(DateTime.now(), DateTime(2020)).start),',
        content
    )
    content = re.sub(
        r'nextEnabled: _activeBlock != TimeframeBlock\.maxBlock && _anchorDate\.isBefore\(DateTime\.now\(\)\),',
        r'nextEnabled: _isRolling ? true : !_activeBlock.getBounds(_anchorDate, DateTime(2020)).start.isAtSameMomentAs(_activeBlock.getBounds(DateTime.now(), DateTime(2020)).start),',
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Traversal fixed in {filepath}")

# 5. TimeRangeFilter: disable scrolling on didUpdateWidget
file_tr = "lib/widgets/common/time_range_filter.dart"
with open(file_tr, 'r', encoding='utf-8') as f:
    content = f.read()
# Remove didUpdateWidget method completely
content = re.sub(
    r'  @override\s*void didUpdateWidget\(TimeRangeFilter oldWidget\) \{[^\}]+\}[^\}]+\}\s*\}',
    '',
    content
)
with open(file_tr, 'w', encoding='utf-8') as f:
    f.write(content)
print("Disabled didUpdateWidget scroll in TimeRangeFilter")


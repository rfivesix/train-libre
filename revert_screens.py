import re

# 1. sleep_period_scope_layout.dart
file1 = "lib/features/sleep/presentation/widgets/sleep_period_scope_layout.dart"
with open(file1, 'r', encoding='utf-8') as f: content = f.read()
# Add supportRolling: false
content = re.sub(r'earliestAvailableDay: DateTime\(2020\),', 'earliestAvailableDay: DateTime(2020),\n                supportRolling: false,', content)
with open(file1, 'w', encoding='utf-8') as f: f.write(content)

# 2. steps_module_screen.dart
file2 = "lib/features/steps/presentation/steps_module_screen.dart"
with open(file2, 'r', encoding='utf-8') as f: content = f.read()

# Force _isRolling = false initially
content = re.sub(r'bool _isRolling = true;', 'bool _isRolling = false;', content)

# update onSelected
content = re.sub(r'onSelected: \(index\) \{\s*setState\(\(\) \{\s*_activeBlock = _validBlocks\[index\];\s*_isRolling = true;\s*\}\);',
                 r'onSelected: (index) {\n                setState(() {\n                  _activeBlock = _validBlocks[index];\n                  _isRolling = false;\n                });', content)

# update onPrevious and onNext to be strictly static
content = re.sub(r'onPrevious: \(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) \{\s*_isRolling = false;\s*_anchorDate = DateTime\.now\(\);\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, -1\);\s*\}\s*\}\);\s*_loadScopeData\(\);\s*\},',
                 r'onPrevious: () {\n                setState(() {\n                  _isRolling = false;\n                  _anchorDate = _activeBlock.shift(_anchorDate, -1);\n                });\n                _loadScopeData();\n              },', content)

content = re.sub(r'onNext: \(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) return;\s*final currentBounds = _activeBlock\.getBounds\(DateTime\.now\(\), DateTime\(2020\)\);\s*final myBounds = _activeBlock\.getBounds\(_anchorDate, DateTime\(2020\)\);\s*if \(myBounds\.start\.isAtSameMomentAs\(currentBounds\.start\) \|\| myBounds\.start\.isAfter\(currentBounds\.start\)\) \{\s*_isRolling = true;\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, 1\);\s*\}\s*\}\);\s*_loadScopeData\(\);\s*\},',
                 r'onNext: () {\n                setState(() {\n                  _isRolling = false;\n                  _anchorDate = _activeBlock.shift(_anchorDate, 1);\n                });\n                _loadScopeData();\n              },', content)

content = re.sub(r'nextEnabled: !_isRolling,', r'nextEnabled: _activeBlock.getBounds(_anchorDate, DateTime(2020)).end.isBefore(DateTime.now()),', content)

# update displayDate to always use format (not formatRolling)
content = re.sub(r'displayDate: _isRolling \? TimeframeLabelFormatter\.formatRolling\(_activeBlock, AppLocalizations\.of\(context\)!\) : TimeframeLabelFormatter\.format\(_activeBlock, _anchorDate, AppLocalizations\.of\(context\)!\),',
                 r'displayDate: TimeframeLabelFormatter.format(_activeBlock, _anchorDate, AppLocalizations.of(context)!),', content)

# update onTapDateDisplay
content = re.sub(r'initialIsRolling: _isRolling,', r'initialIsRolling: false,\n                  supportRolling: false,', content)

with open(file2, 'w', encoding='utf-8') as f: f.write(content)


# 3. sleep_month_overview_page.dart
file3 = "lib/features/sleep/presentation/month/sleep_month_overview_page.dart"
with open(file3, 'r', encoding='utf-8') as f: content = f.read()

content = re.sub(r'bool _isRolling = true;', 'bool _isRolling = false;', content)
# onAnchorChanged: Force _isRolling = false
content = re.sub(r'_isRolling = selection\.isRolling;', '_isRolling = false;', content)
# _shiftPeriod: Revert to strictly static
shift_rep = r'''void _shiftPeriod(int direction) {
    setState(() {
      _anchorDay = DateTime(_anchorDay.year, _anchorDay.month + direction, 1);
    });
    _loadMonth();
  }'''
content = re.sub(r'void _shiftPeriod\(int direction\) \{[^\}]+_loadMonth\(\);\s*\}', shift_rep, content)
# _loadMonth: Strictly static
load_rep = r'''final monthStart = DateTime(_anchorDay.year, _anchorDay.month, 1);
      final monthEnd = DateTime(_anchorDay.year, _anchorDay.month + 1, 0);'''
content = re.sub(r'final monthStart = _isRolling \? DateTime\.now\(\)\.subtract\(const Duration\(days: 30\)\) : DateTime\(_anchorDay\.year, _anchorDay\.month, 1\);\s*final monthEnd = _isRolling \? DateTime\.now\(\) : DateTime\(_anchorDay\.year, _anchorDay\.month \+ 1, 0\);',
                 load_rep, content)
with open(file3, 'w', encoding='utf-8') as f: f.write(content)


# 4. sleep_week_overview_page.dart
file4 = "lib/features/sleep/presentation/week/sleep_week_overview_page.dart"
with open(file4, 'r', encoding='utf-8') as f: content = f.read()

content = re.sub(r'bool _isRolling = true;', 'bool _isRolling = false;', content)
content = re.sub(r'_isRolling = selection\.isRolling;', '_isRolling = false;', content)
shift_rep_week = r'''void _shiftPeriod(int direction) {
    setState(() {
      _anchorDate = _anchorDate.add(Duration(days: direction * 7));
    });
    _loadWeek();
  }'''
content = re.sub(r'void _shiftPeriod\(int direction\) \{[^\}]+_loadWeek\(\);\s*\}', shift_rep_week, content)
load_rep_week = r'''final startOfWeek = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));'''
content = re.sub(r'final startOfWeek = _isRolling \? DateTime\.now\(\)\.subtract\(const Duration\(days: 7\)\) : _anchorDate\.subtract\(Duration\(days: _anchorDate\.weekday - 1\)\);\s*final endOfWeek = _isRolling \? DateTime\.now\(\) : startOfWeek\.add\(const Duration\(days: 6\)\);',
                 load_rep_week, content)
with open(file4, 'w', encoding='utf-8') as f: f.write(content)


# 5. pulse_analysis_screen.dart
file5 = "lib/features/pulse/presentation/pulse_analysis_screen.dart"
with open(file5, 'r', encoding='utf-8') as f: content = f.read()

content = re.sub(r'bool _isRolling = true;', 'bool _isRolling = false;', content)

# update onSelected
content = re.sub(r'onSelected: \(index\) \{\s*setState\(\(\) \{\s*_activeBlock = _validBlocks\[index\];\s*_isRolling = true;\s*\}\);',
                 r'onSelected: (index) {\n                setState(() {\n                  _activeBlock = _validBlocks[index];\n                  _isRolling = false;\n                });', content)

# update onPrevious and onNext to be strictly static
content = re.sub(r'onPrevious: \(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) \{\s*_isRolling = false;\s*_anchorDate = DateTime\.now\(\);\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, -1\);\s*\}\s*\}\);\s*_loadAnalysis\(\);\s*\},',
                 r'onPrevious: () {\n                setState(() {\n                  _isRolling = false;\n                  _anchorDate = _activeBlock.shift(_anchorDate, -1);\n                });\n                _loadAnalysis();\n              },', content)

content = re.sub(r'onNext: \(\) \{\s*setState\(\(\) \{\s*if \(_isRolling\) return;\s*final currentBounds = _activeBlock\.getBounds\(DateTime\.now\(\), DateTime\(2020\)\);\s*final myBounds = _activeBlock\.getBounds\(_anchorDate, DateTime\(2020\)\);\s*if \(myBounds\.start\.isAtSameMomentAs\(currentBounds\.start\) \|\| myBounds\.start\.isAfter\(currentBounds\.start\)\) \{\s*_isRolling = true;\s*\} else \{\s*_anchorDate = _activeBlock\.shift\(_anchorDate, 1\);\s*\}\s*\}\);\s*_loadAnalysis\(\);\s*\},',
                 r'onNext: () {\n                setState(() {\n                  _isRolling = false;\n                  _anchorDate = _activeBlock.shift(_anchorDate, 1);\n                });\n                _loadAnalysis();\n              },', content)

content = re.sub(r'nextEnabled: !_isRolling,', r'nextEnabled: _activeBlock.getBounds(_anchorDate, DateTime(2020)).end.isBefore(DateTime.now()),', content)

# update displayDate to always use format (not formatRolling)
content = re.sub(r'displayDate: _isRolling \? TimeframeLabelFormatter\.formatRolling\(_activeBlock, AppLocalizations\.of\(context\)!\) : TimeframeLabelFormatter\.format\(_activeBlock, _anchorDate, AppLocalizations\.of\(context\)!\),',
                 r'displayDate: TimeframeLabelFormatter.format(_activeBlock, _anchorDate, AppLocalizations.of(context)!),', content)

# update onTapDateDisplay
content = re.sub(r'initialIsRolling: _isRolling,', r'initialIsRolling: false,\n                  supportRolling: false,', content)

with open(file5, 'w', encoding='utf-8') as f: f.write(content)

print("Reverted 5 screens")


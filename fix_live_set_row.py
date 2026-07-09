import re

with open("lib/features/workout/presentation/widgets/live_workout_set_row.dart", "r") as f:
    content = f.read()

import_statement = "import '../../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;"
if import_statement not in content:
    content = content.replace("import 'package:flutter/services.dart';", "import 'package:flutter/services.dart';\n" + import_statement)

search = """        // 4. INPUT 2: REPS / TIME
        Expanded(
          flex: isCardio ? 4 : 2,
          child: TextFormField(
            controller: manager.repsControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: isCardio ? [TimerInputFormatter()] : null,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: repHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
            onChanged: (text) {
              if (isCardio) {
                final seconds = parsePauseDuration(text);
                final clearDuration = seconds == null && text.isEmpty;
                if (seconds != manager.setLogs[templateId]?.durationSeconds ||
                    clearDuration) {
                  manager.updateSet(templateId,
                      duration: seconds, clearDuration: clearDuration);
                }
              } else {
                final int? val;
                if (text.contains('-')) {
                  final parts = text.split('-');
                  if (parts.length == 2) {
                    val = int.tryParse(parts[1]);
                  } else {
                    val = null;
                  }
                } else {
                  val = int.tryParse(text);
                }
                final clearValue = val == null && text.isEmpty;

                if (val != manager.setLogs[templateId]?.reps || clearValue) {
                  manager.updateSet(templateId,
                      reps: val, clearReps: clearValue);
                }
              }
            },
          ),
        ),"""

replace = """        // 4. INPUT 2: REPS / TIME
        Expanded(
          flex: isCardio ? 4 : 2,
          child: TextFormField(
            controller: manager.repsControllers[templateId],
            readOnly: isCardio,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: isCardio ? [TimerInputFormatter()] : null,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: repHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
            onTap: isCardio && !isCompleted ? () async {
              final currentSeconds = manager.setLogs[templateId]?.durationSeconds ?? 0;
              final newDuration = await adaptive_pickers.showAdaptiveDurationPicker(
                context: context,
                initialDuration: Duration(seconds: currentSeconds),
              );
              if (newDuration != null) {
                final seconds = newDuration.inSeconds;
                final clearDuration = seconds == 0;
                if (seconds != manager.setLogs[templateId]?.durationSeconds || clearDuration) {
                  manager.updateSet(templateId, duration: seconds, clearDuration: clearDuration);
                }
              }
            } : null,
            onChanged: (text) {
              if (isCardio) {
                // handled by onTap
              } else {
                final int? val;
                if (text.contains('-')) {
                  final parts = text.split('-');
                  if (parts.length == 2) {
                    val = int.tryParse(parts[1]);
                  } else {
                    val = null;
                  }
                } else {
                  val = int.tryParse(text);
                }
                final clearValue = val == null && text.isEmpty;

                if (val != manager.setLogs[templateId]?.reps || clearValue) {
                  manager.updateSet(templateId,
                      reps: val, clearReps: clearValue);
                }
              }
            },
          ),
        ),"""

content = content.replace(search, replace)

with open("lib/features/workout/presentation/widgets/live_workout_set_row.dart", "w") as f:
    f.write(content)

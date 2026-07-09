import re

with open("lib/features/workout/presentation/widgets/live_workout_set_row.dart", "r") as f:
    content = f.read()

# First, remove the bad onTap logic from everything
bad_ontap = """            onTap: isCardio && !isCompleted ? () async {
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
            } : null,"""

content = content.replace(bad_ontap, "")

# Remove readOnly: isCardio
content = content.replace("            readOnly: isCardio,\n", "")

# Now specifically add it to the reps/time controller block

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
            onChanged: (text) {"""

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
            onTap: (isCardio && !isCompleted) ? () async {
              final currentSeconds = manager.setLogs[templateId]?.durationSeconds ?? 0;
              final newDuration = await adaptive_pickers.showAdaptiveDurationPicker(
                context: context,
                initialDuration: Duration(seconds: currentSeconds),
              );
              if (newDuration != null) {
                final seconds = newDuration.inSeconds;
                final clearDuration = seconds == 0;
                if (seconds != manager.setLogs[templateId]?.durationSeconds || clearDuration) {
                  manager.repsControllers[templateId]?.text = formatPauseDuration(seconds);
                  manager.updateSet(templateId, duration: seconds, clearDuration: clearDuration);
                }
              }
            } : null,
            onChanged: (text) {"""

content = content.replace(search, replace)

with open("lib/features/workout/presentation/widgets/live_workout_set_row.dart", "w") as f:
    f.write(content)

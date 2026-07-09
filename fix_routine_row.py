import re

with open("lib/features/workout/presentation/widgets/routine_set_row_widget.dart", "r") as f:
    content = f.read()

import_stmt = "import '../../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;"
if import_stmt not in content:
    content = content.replace("import '../../../../util/time_util.dart';", "import '../../../../util/time_util.dart';\n" + import_stmt)

search = """              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: repsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: isCardio ? [TimerInputFormatter()] : null,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "00:00",
                  ),
                ),
              ),"""

replace = """              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: repsController,
                  readOnly: isCardio,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: isCardio ? [TimerInputFormatter()] : null,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "00:00",
                  ),
                  onTap: isCardio ? () async {
                    final currentSeconds = parsePauseDuration(repsController.text) ?? 0;
                    final newDuration = await adaptive_pickers.showAdaptiveDurationPicker(
                      context: context,
                      initialDuration: Duration(seconds: currentSeconds),
                    );
                    if (newDuration != null) {
                      final seconds = newDuration.inSeconds;
                      repsController.text = seconds > 0 ? formatPauseDuration(seconds) : "";
                    }
                  } : null,
                ),
              ),"""

content = content.replace(search, replace)

with open("lib/features/workout/presentation/widgets/routine_set_row_widget.dart", "w") as f:
    f.write(content)

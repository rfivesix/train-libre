import re

with open("lib/features/exercise_catalog/domain/body_slug_mapper.dart", "r") as f:
    content = f.read()

# Add imports if missing
if "import 'package:flutter/material.dart';" not in content:
    content = "import 'package:flutter/material.dart';\n" + content
if "import '../../../../generated/app_localizations.dart';" not in content:
    content = "import '../../../../generated/app_localizations.dart';\n" + content

localize_method = """  static String localize(BuildContext context, String rawName) {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = rawName.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

    final canonical = RecoveryDomainService.majorMuscleGroupFor(cleaned) ?? cleaned;

    switch (canonical) {
      case 'chest': return l10n.muscleChest;
      case 'back': return l10n.muscleBack;
      case 'shoulders': return l10n.muscleShoulders;
      case 'biceps': return l10n.muscleBiceps;
      case 'triceps': return l10n.muscleTriceps;
      case 'quads': return l10n.muscleQuads;
      case 'hamstrings': return l10n.muscleHamstrings;
      case 'glutes': return l10n.muscleGlutes;
      case 'calves': return l10n.muscleCalves;
      case 'lower back': return l10n.muscleLowerBack;
      case 'abs': return l10n.muscleAbs;
      case 'adductors': return l10n.muscleAdductors;
      case 'forearms': return l10n.muscleForearms;
      case 'traps':
      case 'trapezius':
      case 'neck': return l10n.muscleTraps;
      case 'obliques': return l10n.muscleObliques;
      default:
        if (rawName.isEmpty) return '';
        return rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
    }
  }
}"""

content = re.sub(r'\}\s*$', localize_method, content)

with open("lib/features/exercise_catalog/domain/body_slug_mapper.dart", "w") as f:
    f.write(content)

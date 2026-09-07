enum AutonomyLevel {
  off,
  suggest,
  automatic,
}

enum PrescriptionOrigin {
  none,
  routine,
  engine,
}

enum ProgressionOutcome {
  raise,
  hold,
  noSuggestion,
}

enum LoadMode {
  external,
  bodyweight,
  assisted,
  variable;

  static LoadMode fromString(String? value) {
    if (value == null) return LoadMode.external;
    switch (value.toLowerCase().trim()) {
      case 'bodyweight':
      case 'bodyweight_reps':
        return LoadMode.bodyweight;
      case 'assisted':
      case 'assisted_reps':
        return LoadMode.assisted;
      case 'variable':
        return LoadMode.variable;
      case 'external':
      case 'weight_reps':
      default:
        return LoadMode.external;
    }
  }
}

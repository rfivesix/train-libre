import Foundation

#if canImport(ActivityKit)
  import ActivityKit
#endif

/// Shared identifiers between the app and the Live Activity extension.
///
/// The App Group is the only channel through which the extension and the
/// intents running in their own process can exchange state with the Flutter
/// app. It must be registered for both bundle identifiers in the developer
/// portal before the extension can be built.
public enum TrainLibreLiveActivity {
  public static let appGroupId = "group.com.rfivesix.trainlibre"

  /// Key under which the App Group holds the queue of commands produced by
  /// Live Activity buttons while the Flutter app was not running.
  public static let pendingCommandsKey = "live_activity_pending_commands"

  /// Key under which the extension mirrors the rest timer end date, so the
  /// app can reconcile after a `-15s` / `+15s` / `Skip` that happened while it
  /// was suspended.
  public static let restEndsAtKey = "live_activity_rest_ends_at"
}

#if canImport(ActivityKit)

  /// The five states from `documentation/features/live_activity_workout.md`.
  ///
  /// `restOverdue` is never pushed by the app — it is derived in the view from
  /// `context.isStale` once `staleDate` passes, because the app is typically
  /// suspended at the moment the rest timer runs out.
  public enum WorkoutActivityPhase: String, Codable, Hashable {
    case setPending
    case resting
    case noSetsLeft
    case empty
  }

  /// Colors are resolved on the Dart side so the extension never needs to know
  /// what a set type means.
  public struct WorkoutSetBadge: Codable, Hashable {
    /// `W`, `F`, `D`, `S`, `O`, or the set number for normal sets.
    /// Empty for cardio, where the metrics line starts at the leading edge.
    public let text: String
    /// `#RRGGBB`, mirroring `SetTypeChip`.
    public let colorHex: String

    public init(text: String, colorHex: String) {
      self.text = text
      self.colorHex = colorHex
    }
  }

  public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
      public let phase: WorkoutActivityPhase

      /// End of the running rest period. Drives both the countdown and, via
      /// `staleDate`, the transition into the overdue state. `nil` outside
      /// `.resting`.
      public let restEndsAt: Date?
      /// Start of the running rest period — only needed for the progress bar.
      public let restStartedAt: Date?

      public let exerciseName: String
      public let setPosition: String
      public let badge: WorkoutSetBadge

      /// Pre-formatted by Dart: `72,5 kg` / `20:00`.
      public let metricPrimary: String
      /// `8 Wdh` / `5,00 km`. Empty when the set carries no such value.
      public let metricSecondary: String
      /// `RIR 2` / `RPE 7`. Empty when unset.
      public let metricTertiary: String
      /// `×` for strength, `·` for cardio.
      public let metricSeparator: String

      /// Compact/minimal presentations cannot fit the full metrics line.
      public let compactPrimary: String
      public let compactSecondary: String

      /// False when weight or reps (duration/distance for cardio) are missing.
      /// The checkmark must never invent values, so it goes grey and only
      /// opens the app.
      public let canCompleteSet: Bool

      public init(
        phase: WorkoutActivityPhase,
        restEndsAt: Date?,
        restStartedAt: Date?,
        exerciseName: String,
        setPosition: String,
        badge: WorkoutSetBadge,
        metricPrimary: String,
        metricSecondary: String,
        metricTertiary: String,
        metricSeparator: String,
        compactPrimary: String,
        compactSecondary: String,
        canCompleteSet: Bool
      ) {
        self.phase = phase
        self.restEndsAt = restEndsAt
        self.restStartedAt = restStartedAt
        self.exerciseName = exerciseName
        self.setPosition = setPosition
        self.badge = badge
        self.metricPrimary = metricPrimary
        self.metricSecondary = metricSecondary
        self.metricTertiary = metricTertiary
        self.metricSeparator = metricSeparator
        self.compactPrimary = compactPrimary
        self.compactSecondary = compactSecondary
        self.canCompleteSet = canCompleteSet
      }
    }

    // Static for the lifetime of the activity.
    public let workoutTitle: String
    public let workoutStartedAt: Date
    public let deepLink: String
    /// Identifies the set the checkmark would complete, so a command enqueued
    /// while the app was gone can be applied idempotently.
    public let workoutLogId: Int

    /// Localized labels — the extension holds no string catalog of its own.
    public let labelAddExercise: String
    public let labelOpenApp: String
    public let labelSkip: String
    public let labelOverdue: String

    public init(
      workoutTitle: String,
      workoutStartedAt: Date,
      deepLink: String,
      workoutLogId: Int,
      labelAddExercise: String,
      labelOpenApp: String,
      labelSkip: String,
      labelOverdue: String
    ) {
      self.workoutTitle = workoutTitle
      self.workoutStartedAt = workoutStartedAt
      self.deepLink = deepLink
      self.workoutLogId = workoutLogId
      self.labelAddExercise = labelAddExercise
      self.labelOpenApp = labelOpenApp
      self.labelSkip = labelSkip
      self.labelOverdue = labelOverdue
    }
  }

#endif

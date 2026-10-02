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

  public struct WorkoutActivitySetSnapshot: Codable, Hashable {
    public let exerciseName: String
    public let setPosition: String
    public let badgeText: String
    public let badgeColorHex: String
    public let metricPrimary: String
    public let metricSecondary: String
    public let metricTertiary: String
    public let metricSeparator: String
    public let compactPrimary: String
    public let compactSecondary: String
    public let setTimerTemplateId: Int?
    public let canCompleteSet: Bool

    public init(dictionary: [String: Any]) {
      exerciseName = dictionary["exerciseName"] as? String ?? ""
      setPosition = dictionary["setPosition"] as? String ?? ""
      badgeText = dictionary["badgeText"] as? String ?? ""
      badgeColorHex = dictionary["badgeColorHex"] as? String ?? "#8E8E93"
      metricPrimary = dictionary["metricPrimary"] as? String ?? ""
      metricSecondary = dictionary["metricSecondary"] as? String ?? ""
      metricTertiary = dictionary["metricTertiary"] as? String ?? ""
      metricSeparator = dictionary["metricSeparator"] as? String ?? "×"
      compactPrimary = dictionary["compactPrimary"] as? String ?? ""
      compactSecondary = dictionary["compactSecondary"] as? String ?? ""
      setTimerTemplateId = (dictionary["setTimerTemplateId"] as? NSNumber)?.intValue
      canCompleteSet = dictionary["canCompleteSet"] as? Bool ?? false
    }

    private enum CodingKeys: String, CodingKey {
      case exerciseName
      case setPosition
      case badgeText
      case badgeColorHex
      case metricPrimary
      case metricSecondary
      case metricTertiary
      case metricSeparator
      case compactPrimary
      case compactSecondary
      case setTimerTemplateId
      case canCompleteSet
    }

    /// Decode object snapshots written by earlier builds, then encode the
    /// stable field order as an array. ActivityKit's content-state limit is
    /// small; repeating twelve JSON property names for each future set made a
    /// normal workout exceed it before the Live Activity could start.
    public init(from decoder: Decoder) throws {
      if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
        exerciseName = try keyed.decode(String.self, forKey: .exerciseName)
        setPosition = try keyed.decode(String.self, forKey: .setPosition)
        badgeText = try keyed.decode(String.self, forKey: .badgeText)
        badgeColorHex = try keyed.decode(String.self, forKey: .badgeColorHex)
        metricPrimary = try keyed.decode(String.self, forKey: .metricPrimary)
        metricSecondary = try keyed.decode(String.self, forKey: .metricSecondary)
        metricTertiary = try keyed.decode(String.self, forKey: .metricTertiary)
        metricSeparator = try keyed.decode(String.self, forKey: .metricSeparator)
        compactPrimary = try keyed.decode(String.self, forKey: .compactPrimary)
        compactSecondary = try keyed.decode(String.self, forKey: .compactSecondary)
        setTimerTemplateId = try keyed.decodeIfPresent(Int.self, forKey: .setTimerTemplateId)
        canCompleteSet = try keyed.decode(Bool.self, forKey: .canCompleteSet)
        return
      }

      var unkeyed = try decoder.unkeyedContainer()
      exerciseName = try unkeyed.decode(String.self)
      setPosition = try unkeyed.decode(String.self)
      badgeText = try unkeyed.decode(String.self)
      badgeColorHex = try unkeyed.decode(String.self)
      metricPrimary = try unkeyed.decode(String.self)
      metricSecondary = try unkeyed.decode(String.self)
      metricTertiary = try unkeyed.decode(String.self)
      metricSeparator = try unkeyed.decode(String.self)
      compactPrimary = try unkeyed.decode(String.self)
      compactSecondary = try unkeyed.decode(String.self)
      setTimerTemplateId = try unkeyed.decodeIfPresent(Int.self)
      canCompleteSet = try unkeyed.decode(Bool.self)
    }

    public func encode(to encoder: Encoder) throws {
      var unkeyed = encoder.unkeyedContainer()
      try unkeyed.encode(exerciseName)
      try unkeyed.encode(setPosition)
      try unkeyed.encode(badgeText)
      try unkeyed.encode(badgeColorHex)
      try unkeyed.encode(metricPrimary)
      try unkeyed.encode(metricSecondary)
      try unkeyed.encode(metricTertiary)
      try unkeyed.encode(metricSeparator)
      try unkeyed.encode(compactPrimary)
      try unkeyed.encode(compactSecondary)
      try unkeyed.encode(setTimerTemplateId)
      try unkeyed.encode(canCompleteSet)
    }
  }

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
      public let setTimerStartedAt: Date?
      public let setTimerDeadline: Date?
      public let setTimerTemplateId: Int?
      public let setTimerElapsedSeconds: Int?
      public let labelStartTimer: String?
      public let labelStopTimer: String?
      public let labelTimerRunning: String?

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
      public let upcomingSets: [WorkoutActivitySetSnapshot]

      public init(
        phase: WorkoutActivityPhase,
        restEndsAt: Date?,
        restStartedAt: Date?,
        setTimerStartedAt: Date? = nil,
        setTimerDeadline: Date? = nil,
        setTimerTemplateId: Int? = nil,
        setTimerElapsedSeconds: Int? = nil,
        labelStartTimer: String? = nil,
        labelStopTimer: String? = nil,
        labelTimerRunning: String? = nil,
        exerciseName: String,
        setPosition: String,
        badge: WorkoutSetBadge,
        metricPrimary: String,
        metricSecondary: String,
        metricTertiary: String,
        metricSeparator: String,
        compactPrimary: String,
        compactSecondary: String,
        canCompleteSet: Bool,
        upcomingSets: [WorkoutActivitySetSnapshot] = []
      ) {
        self.phase = phase
        self.restEndsAt = restEndsAt
        self.restStartedAt = restStartedAt
        self.setTimerStartedAt = setTimerStartedAt
        self.setTimerDeadline = setTimerDeadline
        self.setTimerTemplateId = setTimerTemplateId
        self.setTimerElapsedSeconds = setTimerElapsedSeconds
        self.labelStartTimer = labelStartTimer
        self.labelStopTimer = labelStopTimer
        self.labelTimerRunning = labelTimerRunning
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
        self.upcomingSets = upcomingSets
      }

      public func replacingUpcomingSets(
        _ sets: [WorkoutActivitySetSnapshot]
      ) -> ContentState {
        ContentState(
          phase: phase,
          restEndsAt: restEndsAt,
          restStartedAt: restStartedAt,
          setTimerStartedAt: setTimerStartedAt,
          setTimerDeadline: setTimerDeadline,
          setTimerTemplateId: setTimerTemplateId,
          setTimerElapsedSeconds: setTimerElapsedSeconds,
          labelStartTimer: labelStartTimer,
          labelStopTimer: labelStopTimer,
          labelTimerRunning: labelTimerRunning,
          exerciseName: exerciseName,
          setPosition: setPosition,
          badge: badge,
          metricPrimary: metricPrimary,
          metricSecondary: metricSecondary,
          metricTertiary: metricTertiary,
          metricSeparator: metricSeparator,
          compactPrimary: compactPrimary,
          compactSecondary: compactSecondary,
          canCompleteSet: canCompleteSet,
          upcomingSets: sets
        )
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

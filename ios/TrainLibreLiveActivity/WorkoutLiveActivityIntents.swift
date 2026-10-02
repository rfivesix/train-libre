import Foundation

#if canImport(ActivityKit) && canImport(AppIntents)
  import ActivityKit
  import AppIntents

  /// Commands produced by Live Activity buttons while the Flutter app may be
  /// suspended or terminated. They are appended to the App Group queue and
  /// applied by the app on its next run.
  ///
  /// Each entry is idempotent: the app drops a command whose `id` it has
  /// already applied.
  @available(iOS 17.0, *)
  enum LiveActivityCommandStore {
    private static var defaults: UserDefaults? {
      UserDefaults(suiteName: TrainLibreLiveActivity.appGroupId)
    }

    static func enqueue(_ kind: String, payload: [String: Any] = [:]) {
      guard let defaults else { return }
      var queue = defaults.array(forKey: TrainLibreLiveActivity.pendingCommandsKey) ?? []
      var entry: [String: Any] = payload
      entry["id"] = UUID().uuidString
      entry["kind"] = kind
      entry["createdAt"] = Date().timeIntervalSince1970
      queue.append(entry)
      defaults.set(queue, forKey: TrainLibreLiveActivity.pendingCommandsKey)
    }

    /// Mirrors the rest end date so the app can reconcile a ±15s or Skip that
    /// happened while it was not running.
    static func writeRestEndsAt(_ date: Date?) {
      guard let defaults else { return }
      if let date {
        defaults.set(date.timeIntervalSince1970, forKey: TrainLibreLiveActivity.restEndsAtKey)
      } else {
        defaults.removeObject(forKey: TrainLibreLiveActivity.restEndsAtKey)
      }
    }
  }

  @available(iOS 17.0, *)
  enum LiveActivityUpdater {
    static var current: Activity<WorkoutActivityAttributes>? {
      Activity<WorkoutActivityAttributes>.activities.first
    }

    /// Pushes a new content state and re-arms `staleDate` on the rest end, so
    /// the overdue layout appears even with the app suspended.
    static func push(
      _ activity: Activity<WorkoutActivityAttributes>,
      _ state: WorkoutActivityAttributes.ContentState
    ) async {
      await activity.update(
        ActivityContent(state: state, staleDate: state.restEndsAt)
      )
    }
  }

  /// −15s / +15s. Touches only timer state — never the database.
  @available(iOS 17.0, *)
  struct AdjustRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust rest"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Delta")
    var deltaSeconds: Int

    init() {}

    init(deltaSeconds: Int) {
      self.deltaSeconds = deltaSeconds
    }

    func perform() async throws -> some IntentResult {
      guard
        let activity = LiveActivityUpdater.current,
        let currentEnd = activity.content.state.restEndsAt
      else {
        return .result()
      }

      let newEnd = currentEnd.addingTimeInterval(TimeInterval(deltaSeconds))
      // Shortening below "now" ends the pause rather than going negative.
      guard newEnd > Date() else {
        try await SkipRestIntent().perform()
        return .result()
      }

      let old = activity.content.state
      let next = WorkoutActivityAttributes.ContentState(
        phase: .resting,
        restEndsAt: newEnd,
        restStartedAt: old.restStartedAt,
        setTimerStartedAt: old.setTimerStartedAt,
        setTimerDeadline: old.setTimerDeadline,
        setTimerTemplateId: old.setTimerTemplateId,
        setTimerElapsedSeconds: old.setTimerElapsedSeconds,
        labelStartTimer: old.labelStartTimer,
        labelStopTimer: old.labelStopTimer,
        labelTimerRunning: old.labelTimerRunning,
        exerciseName: old.exerciseName,
        setPosition: old.setPosition,
        badge: old.badge,
        metricPrimary: old.metricPrimary,
        metricSecondary: old.metricSecondary,
        metricTertiary: old.metricTertiary,
        metricSeparator: old.metricSeparator,
        compactPrimary: old.compactPrimary,
        compactSecondary: old.compactSecondary,
        canCompleteSet: old.canCompleteSet || old.setTimerStartedAt != nil ||
          (old.setTimerElapsedSeconds ?? 0) > 0,
        upcomingSets: old.upcomingSets
      )

      LiveActivityCommandStore.writeRestEndsAt(newEnd)
      // Without this the pre-scheduled sound stays on the old time.
      RestSoundScheduler.schedule(at: newEnd)
      LiveActivityCommandStore.enqueue(
        "adjustRest",
        payload: ["deltaSeconds": deltaSeconds]
      )
      await LiveActivityUpdater.push(activity, next)
      return .result()
    }
  }

  /// Skip — ends the pause immediately, S2 → S1.
  @available(iOS 17.0, *)
  struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip rest"
    static var isDiscoverable: Bool = false

    init() {}

    @discardableResult
    func perform() async throws -> some IntentResult {
      guard let activity = LiveActivityUpdater.current else { return .result() }

      let old = activity.content.state
      let next = WorkoutActivityAttributes.ContentState(
        phase: .setPending,
        restEndsAt: nil,
        restStartedAt: nil,
        setTimerStartedAt: old.setTimerStartedAt,
        setTimerDeadline: old.setTimerDeadline,
        setTimerTemplateId: old.setTimerTemplateId,
        setTimerElapsedSeconds: old.setTimerElapsedSeconds,
        labelStartTimer: old.labelStartTimer,
        labelStopTimer: old.labelStopTimer,
        labelTimerRunning: old.labelTimerRunning,
        exerciseName: old.exerciseName,
        setPosition: old.setPosition,
        badge: old.badge,
        metricPrimary: old.metricPrimary,
        metricSecondary: old.metricSecondary,
        metricTertiary: old.metricTertiary,
        metricSeparator: old.metricSeparator,
        compactPrimary: old.compactPrimary,
        compactSecondary: old.compactSecondary,
        canCompleteSet: old.canCompleteSet || old.setTimerStartedAt != nil ||
          (old.setTimerElapsedSeconds ?? 0) > 0,
        upcomingSets: old.upcomingSets
      )

      LiveActivityCommandStore.writeRestEndsAt(nil)
      RestSoundScheduler.cancel()
      LiveActivityCommandStore.enqueue("skipRest")
      await LiveActivityUpdater.push(activity, next)
      return .result()
    }
  }

  @available(iOS 17.0, *)
  struct StartSetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start set timer"
    static var isDiscoverable: Bool = false
    init() {}

    func perform() async throws -> some IntentResult {
      guard let activity = LiveActivityUpdater.current else { return .result() }
      let old = activity.content.state
      guard let templateId = old.setTimerTemplateId else { return .result() }
      let startedAt = Date()
      let elapsed = old.setTimerElapsedSeconds ?? 0
      let next = WorkoutActivityAttributes.ContentState(
        phase: old.phase, restEndsAt: old.restEndsAt, restStartedAt: old.restStartedAt,
        setTimerStartedAt: startedAt.addingTimeInterval(-TimeInterval(elapsed)),
        setTimerDeadline: nil,
        setTimerTemplateId: templateId, setTimerElapsedSeconds: elapsed,
        labelStartTimer: old.labelStartTimer, labelStopTimer: old.labelStopTimer,
        labelTimerRunning: old.labelTimerRunning,
        exerciseName: old.exerciseName, setPosition: old.setPosition, badge: old.badge,
        metricPrimary: old.metricPrimary, metricSecondary: old.metricSecondary,
        metricTertiary: old.metricTertiary, metricSeparator: old.metricSeparator,
        compactPrimary: old.compactPrimary, compactSecondary: old.compactSecondary,
        canCompleteSet: true,
        upcomingSets: old.upcomingSets
      )
      LiveActivityCommandStore.enqueue("startSetTimer", payload: [
        "templateId": templateId,
        "startedAtEpochMs": Int64(startedAt.timeIntervalSince1970 * 1000),
        "elapsedSeconds": elapsed,
      ])
      await LiveActivityUpdater.push(activity, next)
      return .result()
    }
  }

  @available(iOS 17.0, *)
  struct StopSetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop set timer"
    static var isDiscoverable: Bool = false
    init() {}

    func perform() async throws -> some IntentResult {
      guard let activity = LiveActivityUpdater.current else { return .result() }
      let old = activity.content.state
      guard let templateId = old.setTimerTemplateId,
            let startedAt = old.setTimerStartedAt else { return .result() }
      let elapsed = max(0, Int(Date().timeIntervalSince(startedAt)))
      let next = WorkoutActivityAttributes.ContentState(
        phase: old.phase, restEndsAt: old.restEndsAt, restStartedAt: old.restStartedAt,
        setTimerTemplateId: templateId, setTimerElapsedSeconds: elapsed,
        labelStartTimer: old.labelStartTimer, labelStopTimer: old.labelStopTimer,
        labelTimerRunning: old.labelTimerRunning,
        exerciseName: old.exerciseName, setPosition: old.setPosition, badge: old.badge,
        metricPrimary: old.metricPrimary, metricSecondary: old.metricSecondary,
        metricTertiary: old.metricTertiary, metricSeparator: old.metricSeparator,
        compactPrimary: old.compactPrimary, compactSecondary: old.compactSecondary,
        canCompleteSet: old.canCompleteSet || elapsed > 0,
        upcomingSets: old.upcomingSets
      )
      LiveActivityCommandStore.enqueue("stopSetTimer", payload: [
        "templateId": templateId,
        "elapsedSeconds": elapsed,
      ])
      await LiveActivityUpdater.push(activity, next)
      return .result()
    }
  }

  /// The checkmark. Queue the database write and update the activity without
  /// foregrounding the app. The app applies queued changes when it next runs.
  @available(iOS 17.0, *)
  struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete set"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Workout")
    var workoutLogId: Int

    init() {}

    init(workoutLogId: Int) {
      self.workoutLogId = workoutLogId
    }

    func perform() async throws -> some IntentResult {
      guard let activity = LiveActivityUpdater.current else { return .result() }
      let old = activity.content.state
      var command: [String: Any] = ["workoutLogId": workoutLogId]
      if let templateId = old.setTimerTemplateId,
         old.setTimerStartedAt != nil || (old.setTimerElapsedSeconds ?? 0) > 0 {
        let elapsed: Int
        if let startedAt = old.setTimerStartedAt {
          elapsed = max(0, Int(Date().timeIntervalSince(startedAt)))
        } else {
          elapsed = old.setTimerElapsedSeconds ?? 0
        }
        command["timerTemplateId"] = templateId
        command["elapsedSeconds"] = elapsed
      }
      LiveActivityCommandStore.enqueue("completeSet", payload: command)
      RestSoundScheduler.cancel()

      var upcoming = old.upcomingSets
      let nextState: WorkoutActivityAttributes.ContentState
      if !upcoming.isEmpty {
        let next = upcoming.removeFirst()
        nextState = WorkoutActivityAttributes.ContentState(
          phase: .setPending,
          restEndsAt: nil,
          restStartedAt: nil,
          setTimerTemplateId: next.setTimerTemplateId,
          setTimerElapsedSeconds: 0,
          labelStartTimer: old.labelStartTimer,
          labelStopTimer: old.labelStopTimer,
          labelTimerRunning: old.labelTimerRunning,
          exerciseName: next.exerciseName,
          setPosition: next.setPosition,
          badge: WorkoutSetBadge(text: next.badgeText, colorHex: next.badgeColorHex),
          metricPrimary: next.metricPrimary,
          metricSecondary: next.metricSecondary,
          metricTertiary: next.metricTertiary,
          metricSeparator: next.metricSeparator,
          compactPrimary: next.compactPrimary,
          compactSecondary: next.compactSecondary,
          canCompleteSet: next.canCompleteSet,
          upcomingSets: upcoming
        )
      } else {
        nextState = WorkoutActivityAttributes.ContentState(
          phase: .noSetsLeft,
          restEndsAt: nil,
          restStartedAt: nil,
          labelStartTimer: old.labelStartTimer,
          labelStopTimer: old.labelStopTimer,
          labelTimerRunning: old.labelTimerRunning,
          exerciseName: old.exerciseName,
          setPosition: old.setPosition,
          badge: old.badge,
          metricPrimary: old.metricPrimary,
          metricSecondary: old.metricSecondary,
          metricTertiary: old.metricTertiary,
          metricSeparator: old.metricSeparator,
          compactPrimary: old.compactPrimary,
          compactSecondary: old.compactSecondary,
          canCompleteSet: false
        )
      }
      await LiveActivityUpdater.push(activity, nextState)
      return .result()
    }
  }

#endif

import Flutter
import Foundation

#if canImport(ActivityKit)
  import ActivityKit
#endif

/// MethodChannel between the Flutter app and ActivityKit.
///
/// Everything arriving here is already formatted for display — the Swift side
/// never formats a number, a unit or a localized word.
final class WorkoutLiveActivityBridge {
  static let channelName = "trainlibre.workout/live_activity"

  private var currentActivityId: String?

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(isSupported())
    case "start":
      start(args: call.arguments as? [String: Any], result: result)
    case "update":
      update(args: call.arguments as? [String: Any], result: result)
    case "end":
      end(result: result)
    case "consumePendingCommands":
      result(consumePendingCommands())
    case "scheduleRestSound":
      scheduleRestSound(args: call.arguments as? [String: Any], result: result)
    case "cancelRestSound":
      RestSoundScheduler.cancel()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Schedules the rest-over sound natively so the Live Activity's intents can
  /// move it when the pause is extended or skipped.
  private func scheduleRestSound(args: [String: Any]?, result: @escaping FlutterResult) {
    guard
      let args,
      let endMs = args["endsAtEpochMs"] as? NSNumber
    else {
      result(false)
      return
    }
    RestSoundScheduler.rememberTexts(
      title: args["title"] as? String ?? "",
      body: args["body"] as? String ?? ""
    )
    RestSoundScheduler.schedule(at: Date(timeIntervalSince1970: endMs.doubleValue / 1000))
    result(true)
  }

  private func isSupported() -> Bool {
    #if canImport(ActivityKit)
      if #available(iOS 16.2, *) {
        return ActivityAuthorizationInfo().areActivitiesEnabled
      }
    #endif
    return false
  }

  // MARK: - Lifecycle

  private func start(args: [String: Any]?, result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      guard
        ActivityAuthorizationInfo().areActivitiesEnabled,
        let args,
        let attributes = Self.attributes(from: args),
        let state = Self.contentState(from: args)
      else {
        result(false)
        return
      }

      Task {
        // A workout that was never ended (crash, force quit) would otherwise
        // leave a stale activity behind. This has to complete *before* the new
        // request, or it would tear down the activity we just created.
        await Self.endAll()

        do {
          let activity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: state.restEndsAt),
            pushType: nil
          )
          await MainActor.run {
            self.currentActivityId = activity.id
            result(true)
          }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "activity_start_failed",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      }
    #else
      result(false)
    #endif
  }

  private func update(args: [String: Any]?, result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      guard
        let args,
        let state = Self.contentState(from: args),
        let activity = Self.activity(withId: currentActivityId)
      else {
        result(false)
        return
      }

      Task {
        // staleDate is what makes the overdue state (S3) appear while the app
        // is suspended — it must be re-armed on every push.
        await activity.update(
          ActivityContent(state: state, staleDate: state.restEndsAt)
        )
        // FlutterResult must be invoked on the platform thread.
        await MainActor.run { result(true) }
      }
    #else
      result(false)
    #endif
  }

  private func end(result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      Task {
        await Self.endAll()
        await MainActor.run {
          self.currentActivityId = nil
          Self.defaults?.removeObject(forKey: TrainLibreLiveActivity.pendingCommandsKey)
          Self.defaults?.removeObject(forKey: TrainLibreLiveActivity.restEndsAtKey)
          RestSoundScheduler.cancel()
          result(true)
        }
      }
    #else
      result(false)
    #endif
  }

  #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private static func activity(withId id: String?) -> Activity<WorkoutActivityAttributes>? {
      let activities = Activity<WorkoutActivityAttributes>.activities
      if let id, let match = activities.first(where: { $0.id == id }) {
        return match
      }
      return activities.first
    }

    @available(iOS 16.2, *)
    private static func endAll() async {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  #endif

  // MARK: - Pending commands

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: TrainLibreLiveActivity.appGroupId)
  }

  /// Returns and clears the commands that Live Activity buttons produced while
  /// the app was not running. The app applies them and is then the single
  /// source of truth again.
  private func consumePendingCommands() -> [[String: Any]] {
    guard let defaults = Self.defaults else { return [] }
    let queue = defaults.array(forKey: TrainLibreLiveActivity.pendingCommandsKey) as? [[String: Any]]
    defaults.removeObject(forKey: TrainLibreLiveActivity.pendingCommandsKey)
    return queue ?? []
  }

  // MARK: - Decoding

  #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private static func attributes(from args: [String: Any]) -> WorkoutActivityAttributes? {
      guard
        let title = args["workoutTitle"] as? String,
        let startedAt = args["workoutStartedAtEpochMs"] as? NSNumber,
        let deepLink = args["deepLink"] as? String,
        let workoutLogId = args["workoutLogId"] as? NSNumber
      else { return nil }

      return WorkoutActivityAttributes(
        workoutTitle: title,
        workoutStartedAt: Date(timeIntervalSince1970: startedAt.doubleValue / 1000),
        deepLink: deepLink,
        workoutLogId: workoutLogId.intValue,
        labelAddExercise: args["labelAddExercise"] as? String ?? "",
        labelOpenApp: args["labelOpenApp"] as? String ?? "",
        labelSkip: args["labelSkip"] as? String ?? "",
        labelOverdue: args["labelOverdue"] as? String ?? ""
      )
    }

    @available(iOS 16.2, *)
    private static func contentState(
      from args: [String: Any]
    ) -> WorkoutActivityAttributes.ContentState? {
      guard
        let phaseRaw = args["phase"] as? String,
        let phase = WorkoutActivityPhase(rawValue: phaseRaw)
      else { return nil }

      func date(_ key: String) -> Date? {
        guard let ms = args[key] as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: ms.doubleValue / 1000)
      }

      return WorkoutActivityAttributes.ContentState(
        phase: phase,
        restEndsAt: date("restEndsAtEpochMs"),
        restStartedAt: date("restStartedAtEpochMs"),
        exerciseName: args["exerciseName"] as? String ?? "",
        setPosition: args["setPosition"] as? String ?? "",
        badge: WorkoutSetBadge(
          text: args["badgeText"] as? String ?? "",
          colorHex: args["badgeColorHex"] as? String ?? "#8E8E93"
        ),
        metricPrimary: args["metricPrimary"] as? String ?? "",
        metricSecondary: args["metricSecondary"] as? String ?? "",
        metricTertiary: args["metricTertiary"] as? String ?? "",
        metricSeparator: args["metricSeparator"] as? String ?? "×",
        compactPrimary: args["compactPrimary"] as? String ?? "",
        compactSecondary: args["compactSecondary"] as? String ?? "",
        minimalText: args["minimalText"] as? String ?? "",
        canCompleteSet: args["canCompleteSet"] as? Bool ?? false
      )
    }
  #endif
}

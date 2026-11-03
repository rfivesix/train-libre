import Foundation
import UserNotifications

/// Schedules the "rest is over" sound natively, so that both the app and the
/// Live Activity's App Intents can reschedule it.
///
/// Why not `flutter_local_notifications`: `AdjustRestIntent` and
/// `SkipRestIntent` run in the widget extension's process, which has no Flutter
/// engine. Without a native scheduler they can move the rest end date while
/// the app is suspended and leave the notification behind on the old time —
/// so `+15s` would beep 15 seconds early and `Skip` would beep at all.
///
/// The system delivers the sound while the app is suspended. When the user
/// hides the banner, schedule sound-only content instead of a visible alert.
public enum RestSoundScheduler {
  public static let requestIdentifier = "trainlibre.rest_timer_done"

  private static let titleKey = "rest_sound_title"
  private static let bodyKey = "rest_sound_body"
  private static let enabledKey = "rest_sound_notifications_enabled"
  private static let revisionKey = "rest_sound_revision"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: TrainLibreLiveActivity.appGroupId)
  }

  /// Remembers the localized text so the intents can reschedule without
  /// knowing anything about the app's string catalog.
  public static func rememberTexts(title: String, body: String) {
    defaults?.set(title, forKey: titleKey)
    defaults?.set(body, forKey: bodyKey)
  }

  public static func setNotificationsEnabled(_ enabled: Bool, refreshPending: Bool = true) {
    defaults?.set(enabled, forKey: enabledKey)
    guard refreshPending else { return }
    let revision = defaults?.integer(forKey: revisionKey) ?? 0
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      guard (defaults?.integer(forKey: revisionKey) ?? 0) == revision,
            let request = requests.first(where: { $0.identifier == requestIdentifier }),
            let trigger = request.trigger as? UNTimeIntervalNotificationTrigger,
            let date = trigger.nextTriggerDate() else { return }
      schedule(at: date)
    }
  }

  public static func schedule(at date: Date) {
    cancel()

    let interval = date.timeIntervalSinceNow
    // Anything already due is pointless to schedule — the moment has passed.
    guard interval > 0.5 else { return }

    let content = UNMutableNotificationContent()
    let showAlert = defaults?.object(forKey: enabledKey) as? Bool != false
    if showAlert {
      content.title = defaults?.string(forKey: titleKey) ?? ""
      content.body = defaults?.string(forKey: bodyKey) ?? ""
    }
    // Custom notification sounds must be present in the app bundle root and
    // use a supported short format. Convert the actual Flutter timer_done.mp3
    // to CAF; a Flutter asset path is not visible to UserNotifications.
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "timer_done.caf"))
    // The Runner target still deploys to iOS 14; the extension is 16.2+.
    if #available(iOS 15.0, *) {
      // Time-sensitive so the beep still lands while a Focus mode is on —
      // being late for the next set is exactly what this is for.
      content.interruptionLevel = .timeSensitive
    }

    let request = UNNotificationRequest(
      identifier: requestIdentifier,
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(
        timeInterval: interval,
        repeats: false
      )
    )
    UNUserNotificationCenter.current().add(request)
  }

  public static func cancel() {
    defaults?.set((defaults?.integer(forKey: revisionKey) ?? 0) + 1, forKey: revisionKey)
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
  }
}

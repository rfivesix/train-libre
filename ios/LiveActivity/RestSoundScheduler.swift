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
/// The sound is the point of this notification. A banner-less delivery
/// (`interruptionLevel: .passive`) plays no sound at all, so on the lock screen
/// the banner comes along with it — that is unavoidable, see §7a of the spec.
public enum RestSoundScheduler {
  public static let requestIdentifier = "trainlibre.rest_timer_done"

  private static let titleKey = "rest_sound_title"
  private static let bodyKey = "rest_sound_body"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: TrainLibreLiveActivity.appGroupId)
  }

  /// Remembers the localized text so the intents can reschedule without
  /// knowing anything about the app's string catalog.
  public static func rememberTexts(title: String, body: String) {
    defaults?.set(title, forKey: titleKey)
    defaults?.set(body, forKey: bodyKey)
  }

  public static func schedule(at date: Date) {
    cancel()

    let interval = date.timeIntervalSinceNow
    // Anything already due is pointless to schedule — the moment has passed.
    guard interval > 0.5 else { return }

    let content = UNMutableNotificationContent()
    content.title = defaults?.string(forKey: titleKey) ?? ""
    content.body = defaults?.string(forKey: bodyKey) ?? ""
    content.sound = .default
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
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
  }
}

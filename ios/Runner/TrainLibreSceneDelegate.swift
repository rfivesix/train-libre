import UIKit

/// Receives the callbacks UIKit only ever sends to a scene delegate.
///
/// The app runs on the UIScene lifecycle, so Home Screen quick actions are
/// delivered to `windowScene(_:performActionFor:)` — `UIApplicationDelegate`'s
/// equivalent is never called. Without a scene delegate the action was simply
/// dropped and the app just launched normally.
///
/// Everything else stays where it already worked: the window is still owned by
/// `AppDelegate`, and incoming URLs are handed straight back to it, so the
/// widget and App Intent deep links keep using the exact same path as before.
class TrainLibreSceneDelegate: NSObject, UIWindowSceneDelegate {
  private var appDelegate: AppDelegate? {
    return UIApplication.shared.delegate as? AppDelegate
  }

  var window: UIWindow? {
    get { return appDelegate?.window }
    set { appDelegate?.window = newValue }
  }

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let shortcutItem = connectionOptions.shortcutItem {
      // Cold launch: the engine is not up yet, so park the link and let
      // AppDelegate replay it once the app is on screen.
      appDelegate?.enqueueShortcut(shortcutItem)
    }
    for context in connectionOptions.urlContexts {
      handle(urlContext: context)
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      handle(urlContext: context)
    }
  }

  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(appDelegate?.performShortcut(shortcutItem) ?? false)
  }

  private func handle(urlContext: UIOpenURLContext) {
    guard let appDelegate else { return }
    var options: [UIApplication.OpenURLOptionsKey: Any] = [
      .openInPlace: urlContext.options.openInPlace
    ]
    if let sourceApplication = urlContext.options.sourceApplication {
      options[.sourceApplication] = sourceApplication
    }
    if let annotation = urlContext.options.annotation {
      options[.annotation] = annotation
    }
    _ = appDelegate.application(UIApplication.shared, open: urlContext.url, options: options)
  }
}

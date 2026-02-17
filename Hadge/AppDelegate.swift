import UIKit
import SwiftUI
import UserNotifications

private struct RootContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let workoutsViewController = WorkoutsViewController(style: .plain)
        workoutsViewController.title = "Workouts"

        let navigationController = EntireNavigationController(rootViewController: workoutsViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GitHub.shared().prepare()

        if Constants.debug {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge], completionHandler: { _, _ in })
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        BackgroundTaskHelper.shared().registerBackgroundTask()
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) {
            BackgroundTaskHelper.shared().registerBackgroundDelivery()
        }

        let rootView = RootContainerView()
        let hostingController = UIHostingController(rootView: rootView)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GitHub.shared().process(url: url) { _ in }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundTaskHelper.shared().scheduleBackgroundFetchTask()
    }
}

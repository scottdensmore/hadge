import Foundation

class Constants {
    static let debug = false
}

class UserDefaultKeys {
    static let interfaceStyle = "interfaceStyle"
    static let lastActivitySyncDate = "lastActivitySyncDate"
    static let lastWorkout = "lastWorkout"
    static let lastSyncDate = "lastSyncDate"
    static let setupFinished = "setupFinished"
    static let workoutFilter = "workoutFilter"
    static let workoutYear = "workoutYear"
}

class AppIdentifiers {
    private static let fallbackBundleIdentifier = "com.example.hadge"

    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? fallbackBundleIdentifier
    }

    static var backgroundFetchTask: String {
        return "\(bundleIdentifier).bg-fetch"
    }

    static var keychainService: String {
        return "\(bundleIdentifier).github-token"
    }
}

enum InterfaceStyle: Int {
    case automatic
    case light
    case dark
}

extension Notification.Name {
    static let didChangeInterfaceStyle = Notification.Name("didChangeInterfaceStyle")
    static let isCollectingWorkouts = Notification.Name("isCollectingWorkouts")
    static let collectingActivityData = Notification.Name("isCollectingActivityData")
    static let collectingDistanceData = Notification.Name("isCollectingDistanceData")
    static let didFinishExport = Notification.Name("didFinishExport")
}

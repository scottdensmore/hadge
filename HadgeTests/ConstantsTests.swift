import XCTest
@testable import Hadge

final class ConstantsTests: XCTestCase {
    func testAppIdentifierSuffixesStayStable() {
        XCTAssertTrue(AppIdentifiers.backgroundFetchTask.hasSuffix(".bg-fetch"))
        XCTAssertTrue(AppIdentifiers.keychainService.hasSuffix(".github-token"))
    }

    func testInterfaceStyleRawValues() {
        XCTAssertEqual(InterfaceStyle.automatic.rawValue, 0)
        XCTAssertEqual(InterfaceStyle.light.rawValue, 1)
        XCTAssertEqual(InterfaceStyle.dark.rawValue, 2)
    }

    func testNotificationNamesStayStable() {
        XCTAssertEqual(Notification.Name.didChangeInterfaceStyle.rawValue, "didChangeInterfaceStyle")
        XCTAssertEqual(Notification.Name.isCollectingWorkouts.rawValue, "isCollectingWorkouts")
        XCTAssertEqual(Notification.Name.collectingActivityData.rawValue, "isCollectingActivityData")
        XCTAssertEqual(Notification.Name.collectingDistanceData.rawValue, "isCollectingDistanceData")
        XCTAssertEqual(Notification.Name.didFinishExport.rawValue, "didFinishExport")
    }
}

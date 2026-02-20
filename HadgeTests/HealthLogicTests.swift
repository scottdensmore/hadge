import XCTest
import HealthKit
@testable import Hadge

final class HealthLogicTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.lastWorkout)
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.lastActivitySyncDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.lastSyncDate)
        super.tearDown()
    }

    func testQuantityToStringSupportsFloatAndIntFormatting() {
        let sut = Health()
        let quantity = HKQuantity(unit: .meter(), doubleValue: 1234.567)

        XCTAssertEqual(sut.quantityToString(quantity, unit: .meter()), "1234.57")
        XCTAssertEqual(sut.quantityToString(quantity, unit: .meter(), int: true), "1235")
        XCTAssertEqual(sut.quantityToString(nil, unit: .meter()), "0.00")
    }

    func testGenerateContentForDistancesIncludesExpectedColumns() {
        let sut = Health()
        let distances: [Any] = [[
            "date": "2026-01-01",
            "walkingDistance": HKQuantity(unit: .meter(), doubleValue: 10),
            "steps": HKQuantity(unit: .count(), doubleValue: 20),
            "swimmingDistance": HKQuantity(unit: .meter(), doubleValue: 30),
            "strokes": HKQuantity(unit: .count(), doubleValue: 40),
            "cyclingDistance": HKQuantity(unit: .meter(), doubleValue: 50),
            "wheelchairDistance": HKQuantity(unit: .meter(), doubleValue: 60),
            "downhillDistance": HKQuantity(unit: .meter(), doubleValue: 70)
        ]]

        let content = sut.generateContentForDistances(distances: distances)

        XCTAssertTrue(content.contains("Date,Distance Walking/Running,Steps"))
        XCTAssertTrue(content.contains("2026-01-01,10.00,20.00,30.00,40.00,50.00,60.00,70.00"))
    }

    func testGenerateContentForWorkoutsIncludesElevationWhenAvailable() {
        let sut = Health()
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3600)

        let workoutWithoutElevation = HKWorkout(
            activityType: .walking,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 100),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 2000),
            metadata: nil
        )

        let workoutWithElevation = HKWorkout(
            activityType: .running,
            start: start.addingTimeInterval(10),
            end: end.addingTimeInterval(10),
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 150),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 3000),
            metadata: ["HKElevationAscended": HKQuantity(unit: .meter(), doubleValue: 25)]
        )

        let content = sut.generateContentForWorkouts(workouts: [workoutWithoutElevation, workoutWithElevation])
        let lines = content.split(separator: "\n")

        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[1].contains(",25.00,"))
        XCTAssertTrue(lines[2].contains(",0,"))
    }

    func testFreshWorkoutAndActivityTracking() {
        let sut = Health()

        let workout = HKWorkout(
            activityType: .running,
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 10),
            duration: 10,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: nil
        )

        XCTAssertTrue(sut.freshWorkoutsAvailable(workouts: [workout]))

        sut.markLastWorkout(workouts: [workout])
        XCTAssertFalse(sut.freshWorkoutsAvailable(workouts: [workout]))

        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.lastActivitySyncDate)
        XCTAssertTrue(sut.freshActivityAvailable())

        UserDefaults.standard.set("9999-12-31", forKey: UserDefaultKeys.lastActivitySyncDate)
        XCTAssertFalse(sut.freshActivityAvailable())
    }

    func testMarkLastDistancePersistsDate() {
        let sut = Health()

        sut.markLastDistance(distances: [["date": "2026-02-01"]])

        XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaultKeys.lastActivitySyncDate), "2026-02-01")
        XCTAssertNotNil(UserDefaults.standard.object(forKey: UserDefaultKeys.lastSyncDate))
    }
}

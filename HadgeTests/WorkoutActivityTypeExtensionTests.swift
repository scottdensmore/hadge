import XCTest
import HealthKit
@testable import Hadge

final class WorkoutActivityTypeExtensionTests: XCTestCase {
    func testValuesExposeKnownActivities() {
        let values = HKWorkoutActivityType.values

        XCTAssertFalse(values.isEmpty)
        XCTAssertTrue(values.contains(.running))
        XCTAssertTrue(values.contains(.walking))
        XCTAssertFalse(values.contains(.other))
    }

    func testValuesHaveReadableNamesAndEmojis() {
        HKWorkoutActivityType.values.forEach { activityType in
            XCTAssertFalse(activityType.name.isEmpty)
            XCTAssertNotEqual(activityType.name, "Other")
            XCTAssertFalse((activityType.associatedEmoji ?? "").isEmpty)
        }
    }

    func testGenderSpecificEmojiMappings() {
        XCTAssertEqual(HKWorkoutActivityType.running.associatedEmojiFemale, "🏃‍♀️")
        XCTAssertEqual(HKWorkoutActivityType.running.associatedEmojiMale, "🏃‍♂️")

        XCTAssertEqual(HKWorkoutActivityType.cycling.associatedEmojiFemale, HKWorkoutActivityType.cycling.associatedEmoji)
        XCTAssertEqual(HKWorkoutActivityType.cycling.associatedEmojiMale, HKWorkoutActivityType.cycling.associatedEmoji)
    }
}

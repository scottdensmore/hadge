import XCTest
import HealthKit
@testable import Hadge

private final class StubDistanceDataSource: DistanceDataSource {
    var injectedSteps: [String: HKQuantity]?
    var injectedStrokes: [String: HKQuantity]?
    var injectedCyclingDistances: [String: HKQuantity]?
    var injectedDownhillDistances: [String: HKQuantity]?
    var injectedSwimmingDistances: [String: HKQuantity]?
    var injectedWalkingDistances: [String: HKQuantity]?
    var injectedWheelchairDistances: [String: HKQuantity]?

    override func queryDistances(start: Date, end: Date) {
        steps = injectedSteps
        strokes = injectedStrokes
        cyclingDistances = injectedCyclingDistances
        downhillDistances = injectedDownhillDistances
        swimmingDistances = injectedSwimmingDistances
        walkingDistances = injectedWalkingDistances
        wheelchairDistances = injectedWheelchairDistances
    }
}

final class DistanceDataSourceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testGetAllDistancesStartsAtFirstNonZeroStepForPastYears() {
        let sut = StubDistanceDataSource()
        let oldYear = Health.shared().year - 1
        let day1 = makeDate(year: oldYear, month: 1, day: 1)
        let day2 = makeDate(year: oldYear, month: 1, day: 2)
        let day3 = makeDate(year: oldYear, month: 1, day: 3)

        sut.injectedSteps = [
            day2.toFormat("yyyy-MM-dd"): HKQuantity(unit: .count(), doubleValue: 123)
        ]

        let expectation = expectation(description: "completion")
        sut.getAllDistances(start: day1, end: day3) { distances in
            let dates = (distances ?? []).compactMap { $0["date"] as? String }
            XCTAssertEqual(dates, [
                day2.toFormat("yyyy-MM-dd"),
                day3.toFormat("yyyy-MM-dd")
            ])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testGetAllDistancesIncludesCurrentYearEvenWithoutSteps() {
        let sut = StubDistanceDataSource()
        let currentYear = Health.shared().year
        let day1 = makeDate(year: currentYear, month: 1, day: 1)
        let day2 = makeDate(year: currentYear, month: 1, day: 2)

        let expectation = expectation(description: "completion")
        sut.getAllDistances(start: day1, end: day2) { distances in
            let dates = (distances ?? []).compactMap { $0["date"] as? String }
            XCTAssertEqual(dates, [
                day1.toFormat("yyyy-MM-dd"),
                day2.toFormat("yyyy-MM-dd")
            ])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

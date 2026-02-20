import XCTest
import HealthKit
@testable import Hadge

final class SplitsDataSourceTests: XCTestCase {
    private let quantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

    func testStringFromTimeIntervalFormatsExpectedOutput() {
        let sut = SplitsDataSource()

        XCTAssertEqual(sut.stringFromTimeInterval(3661.789), "01:01:01.789")
    }

    func testDurationSubtractsFullPauseSpannedBySample() {
        let sut = SplitsDataSource()
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 30)
        let sample = makeSample(start: start, end: end)
        let pauses = [[Date(timeIntervalSince1970: 10), Date(timeIntervalSince1970: 20)]]

        let duration = sut.getDurationAjustedForPauses(pauses, currentSample: sample, lastDate: start)

        XCTAssertEqual(duration, 20, accuracy: 0.001)
    }

    func testDurationIsZeroWhenSampleFallsCompletelyInsidePause() {
        let sut = SplitsDataSource()
        let lastDate = Date(timeIntervalSince1970: 12)
        let sample = makeSample(start: lastDate, end: Date(timeIntervalSince1970: 18))
        let pauses = [[Date(timeIntervalSince1970: 10), Date(timeIntervalSince1970: 20)]]

        let duration = sut.getDurationAjustedForPauses(pauses, currentSample: sample, lastDate: lastDate)

        XCTAssertEqual(duration, 0, accuracy: 0.001)
    }

    func testDurationSubtractsTailWhenSampleEndsDuringPause() {
        let sut = SplitsDataSource()
        let lastDate = Date(timeIntervalSince1970: 0)
        let sample = makeSample(start: lastDate, end: Date(timeIntervalSince1970: 15))
        let pauses = [[Date(timeIntervalSince1970: 10), Date(timeIntervalSince1970: 20)]]

        let duration = sut.getDurationAjustedForPauses(pauses, currentSample: sample, lastDate: lastDate)

        XCTAssertEqual(duration, 10, accuracy: 0.001)
    }

    func testDurationSubtractsHeadWhenSampleStartsDuringPause() {
        let sut = SplitsDataSource()
        let lastDate = Date(timeIntervalSince1970: 12)
        let sample = makeSample(start: lastDate, end: Date(timeIntervalSince1970: 25))
        let pauses = [[Date(timeIntervalSince1970: 10), Date(timeIntervalSince1970: 20)]]

        let duration = sut.getDurationAjustedForPauses(pauses, currentSample: sample, lastDate: lastDate)

        XCTAssertEqual(duration, 5, accuracy: 0.001)
    }

    private func makeSample(start: Date, end: Date) -> HKQuantitySample {
        HKQuantitySample(type: quantityType, quantity: HKQuantity(unit: .meter(), doubleValue: 50), start: start, end: end)
    }
}

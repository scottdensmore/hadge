import XCTest
@testable import Hadge

final class StringDateTests: XCTestCase {
    func testToDateParsesDefaultFormat() {
        let date = "2026-01-15 13:45:30 +00:00".toDate()

        XCTAssertNotNil(date)
    }

    func testToDateParsesCustomFormat() {
        let date = "2026/01/15".toDate(withFormat: "yyyy/MM/dd")

        XCTAssertNotNil(date)
    }

    func testToDateReturnsNilForInvalidInput() {
        XCTAssertNil("not-a-date".toDate())
    }
}

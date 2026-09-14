import XCTest
@testable import Hadge

final class PaddingLabelTests: XCTestCase {
    func testDefaultInsets() {
        let label = PaddingLabel()
        XCTAssertEqual(label.topInset, 0.0)
        XCTAssertEqual(label.bottomInset, 0.0)
        XCTAssertEqual(label.leftInset, 20.0)
        XCTAssertEqual(label.rightInset, 20.0)
    }

    func testCustomInsetsAndIntrinsicContentSize() {
        let label = PaddingLabel()
        label.text = "Testing"
        label.topInset = 5.0
        label.bottomInset = 10.0
        label.leftInset = 15.0
        label.rightInset = 25.0

        let baseLabel = UILabel()
        baseLabel.text = "Testing"

        let labelSize = label.intrinsicContentSize
        let baseSize = baseLabel.intrinsicContentSize

        XCTAssertEqual(labelSize.width, baseSize.width + 40.0)
        XCTAssertEqual(labelSize.height, baseSize.height + 15.0)
    }
}

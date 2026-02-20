import XCTest
@testable import Hadge

private final class MockGitHubFileUpdater: GitHubFileUpdating {
    struct UpdateCall {
        let path: String
        let content: String
        let message: String
    }

    var calls: [UpdateCall] = []
    var onUpdate: (() -> Void)?

    func updateFile(path: String, content: String, message: String, completionHandler: @escaping (String?) -> Void) {
        calls.append(UpdateCall(path: path, content: content, message: message))
        onUpdate?()
        completionHandler("sha")
    }
}

final class HealthExportTests: XCTestCase {
    func testExportDataProcessesYearsInSortedOrder() {
        let sut = Health()
        let updater = MockGitHubFileUpdater()
        sut.fileUpdater = updater

        let years: [String: [Any]] = [
            "2021": ["c"],
            "2019": ["a"],
            "2020": ["b"]
        ]

        let expectation = expectation(description: "completion")
        sut.exportData(years, directory: "workouts", contentHandler: { values in
            "rows=\(values.count)"
        }, completionHandler: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(updater.calls.map { $0.path }, [
            "workouts/2019.csv",
            "workouts/2020.csv",
            "workouts/2021.csv"
        ])
    }

    func testExportDataCompletesImmediatelyWhenStopped() {
        let sut = Health()
        let updater = MockGitHubFileUpdater()
        sut.fileUpdater = updater
        sut.stopExport = true

        let expectation = expectation(description: "completion")
        sut.exportData(["2026": ["a"]], directory: "workouts", contentHandler: { _ in "data" }, completionHandler: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(updater.calls.isEmpty)
    }

    func testExportDataCompletesWhenStopExportIsSetMidRun() {
        let sut = Health()
        let updater = MockGitHubFileUpdater()
        sut.fileUpdater = updater

        updater.onUpdate = {
            sut.stopExport = true
        }

        let expectation = expectation(description: "completion")
        sut.exportData(["2025": ["a"], "2026": ["b"]], directory: "workouts", contentHandler: { _ in "data" }, completionHandler: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(updater.calls.count, 1)
    }
}

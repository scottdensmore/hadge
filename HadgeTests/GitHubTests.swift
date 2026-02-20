import XCTest
import SwiftyJSON
@testable import Hadge

private final class InMemoryCredentialStore: GitHubCredentialStore {
    private var storage: [String: String] = [:]

    subscript(_ key: String) -> String? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
}

final class GitHubTests: XCTestCase {
    func testIsSignedInRequiresTokenAndUsername() {
        let store = InMemoryCredentialStore()
        let sut = GitHub()
        sut.keychain = store

        XCTAssertFalse(sut.isSignedIn())

        store["token"] = "secret"
        XCTAssertFalse(sut.isSignedIn())

        store["username"] = "alice"
        XCTAssertTrue(sut.isSignedIn())
    }

    func testReturnAuthenticatedUsernameFallsBackWhenNotSignedIn() {
        let sut = GitHub()
        sut.keychain = InMemoryCredentialStore()

        XCTAssertEqual(sut.returnAuthenticatedUsername(), "github")
    }

    func testProcessReturnsNilWhenOAuthIsMissing() {
        let sut = GitHub()
        let expectation = expectation(description: "completion")

        sut.process(url: URL(string: "https://example.com")!) { username in
            XCTAssertNil(username)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testGetRepositoryReturnsNilWhenConfigOrUsernameMissing() {
        let sut = GitHub()
        sut.keychain = InMemoryCredentialStore()

        let expectation = expectation(description: "completion")
        sut.getRepository { repositoryId in
            XCTAssertNil(repositoryId)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCreateRepositoryReturnsNilWhenAuthIsMissing() {
        let sut = GitHub()
        sut.keychain = InMemoryCredentialStore()

        let expectation = expectation(description: "completion")
        sut.createRepository { repositoryId in
            XCTAssertNil(repositoryId)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testUpdateFileReturnsNilWhenUsernameMissing() {
        let sut = GitHub()
        sut.keychain = InMemoryCredentialStore()

        let expectation = expectation(description: "completion")
        sut.updateFile(path: "a.csv", content: "x", message: "m") { sha in
            XCTAssertNil(sha)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCreateRequestReturnsNilWhenCredentialsMissing() {
        let sut = GitHub()
        sut.keychain = InMemoryCredentialStore()

        let request = sut.createRequest(url: URL(string: "https://api.github.com")!, httpMethod: "GET")

        XCTAssertNil(request)
    }

    func testCreateRequestIncludesBasicAuthHeader() {
        let store = InMemoryCredentialStore()
        store["username"] = "alice"
        store["token"] = "secret"

        let sut = GitHub()
        sut.keychain = store

        let request = sut.createRequest(url: URL(string: "https://api.github.com")!, httpMethod: "PUT")

        XCTAssertEqual(request?.httpMethod, "PUT")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Basic YWxpY2U6c2VjcmV0")
    }

    func testHandleRequestReturnsTransportError() {
        let sut = GitHub()
        let expectedError = NSError(domain: "tests", code: 42)
        sut.requestExecutor = { _, completion in
            completion(nil, nil, expectedError)
        }

        let expectation = expectation(description: "completion")
        let request = URLRequest(url: URL(string: "https://example.com")!)

        sut.handleRequest(request) { json, status, error in
            XCTAssertNil(json)
            XCTAssertEqual(status, 0)
            XCTAssertEqual((error as NSError?)?.code, expectedError.code)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testHandleRequestReturnsParsingErrorForInvalidJSON() {
        let sut = GitHub()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        sut.requestExecutor = { _, completion in
            completion(Data("not-json".utf8), response, nil)
        }

        let expectation = expectation(description: "completion")
        let request = URLRequest(url: URL(string: "https://example.com")!)

        sut.handleRequest(request) { json, status, error in
            XCTAssertNil(json)
            XCTAssertEqual(status, 200)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testHandleRequestReturnsJSONAndStatusOnSuccess() {
        let sut = GitHub()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)
        sut.requestExecutor = { _, completion in
            completion(Data("{\"id\":\"123\"}".utf8), response, nil)
        }

        let expectation = expectation(description: "completion")
        let request = URLRequest(url: URL(string: "https://example.com")!)

        sut.handleRequest(request) { json, status, error in
            XCTAssertEqual(json?["id"].string, "123")
            XCTAssertEqual(status, 201)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testGetFileReturnsNilWhenResponseHasNoSha() {
        let store = InMemoryCredentialStore()
        store["username"] = "alice"
        store["token"] = "secret"

        let sut = GitHub()
        sut.keychain = store
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        sut.requestExecutor = { _, completion in
            completion(Data("{}".utf8), response, nil)
        }

        let expectation = expectation(description: "completion")
        sut.getFile(path: "missing.csv") { sha in
            XCTAssertNil(sha)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testUpdateFileCreatesNewFileWhenShaIsMissing() throws {
        let store = InMemoryCredentialStore()
        store["username"] = "alice"
        store["token"] = "secret"

        let sut = GitHub()
        sut.keychain = store

        var requests: [URLRequest] = []
        sut.requestExecutor = { request, completion in
            requests.append(request)
            if request.httpMethod == "GET" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)
                completion(Data("{}".utf8), response, nil)
                return
            }

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            completion(Data("{\"content\":{\"sha\":\"new-sha\"}}".utf8), response, nil)
        }

        let expectation = expectation(description: "completion")
        sut.updateFile(path: "workouts/2026.csv", content: "hello", message: "msg") { sha in
            XCTAssertEqual(sha, "new-sha")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].httpMethod, "GET")
        XCTAssertEqual(requests[1].httpMethod, "PUT")

        let body = try XCTUnwrap(requests[1].httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(json["sha"])
        XCTAssertEqual(json["message"] as? String, "msg")
    }
}

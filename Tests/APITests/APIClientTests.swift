// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import API

final class APIClientTests: XCTestCase {
    var sut: APIClient!
    
    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]

        sut = APIClient(configuration: configuration, host: "api.github.com", delegate: MockAPIClientDelegate())
    }
    
    func testLoadDataFromLocalFile() async throws {
        // GIVEN
        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "user", withExtension: "json"))
        let request = URLRequest(url: fileURL)
        
        // WHEN
        let (data, response) = try await sut.send(request)
        
        // THEN
        XCTAssertEqual(data.count, 1321)
        XCTAssertEqual(response.url, fileURL)
    }
    
    func testLoadMockedData() async throws {
        // TODO: add test
    }
    
    func testCancellingTheRequest() async throws {
        // Given
        let url = URL(string: "https://api.github.com/users/kean")!
        var mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: json(named: "user")
        ])
        mock.delay = DispatchTimeInterval.seconds(60)
        mock.register()
        
        // When
        let task = Task {
            try await sut.send(URLRequest(url: url))
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            task.cancel()
        }
        
        // Then
        do {
            let _ = try await task.value
        } catch {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
    }
    
    func testLogsAreSaved() {
        // TODO: add test
    }
    
    // MARK: Basics
    
    func testGetJson() {
        
    }
    
    // MARK: Parameters
    
    func testPassingAbsoluteURL() {
        
    }
    
    func testPassingRelativeURL() {
        
    }
    
    func testPassingQueryItems() {
        
    }
    
    func testPassingInvalidPath() {
        
    }
    
    // MARK: Authorization
    
    // TODO: Add Authorization tests
    
    // MARK: Integration Tests
    
    func _testGitHubUsersApi() async throws {
        let api = GitHubAPI(host: "api.github.com")
        
        let user = try await api.users.get(named: "kean")
        
        XCTAssertEqual(user.name, "Alexander Grebenyuk")
    }
}

private final class MockAPIClientDelegate: APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) {
        
    }
    
    func client(_ client: APIClient, didEncounterInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        // TODO:
        URLError(.badServerResponse)
    }
}

private func json(named name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json")
    return try! Data(contentsOf: url!)
}

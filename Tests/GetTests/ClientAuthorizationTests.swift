// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class APIClientAuthorizationTests: XCTestCase {
    private var client: APIClient!
    private let delegate = MockAuthorizingDelegate()
    
    override func setUp() {
        super.setUp()

        client = APIClient(host: "api.github.com") {
            $0.delegate = delegate
            $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
    }
    
    func testAuthorizationHeaderIsPassed() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 401, data: [
            .get: "Unauthorized".data(using: .utf8)!
        ])
        
        mock.onRequest = { request, arguments in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer: expired-token")

            self.delegate.token = "valid-token"
            var mock = Mock.get(url: url, json: "user")
            mock.onRequest = { request, arguments in
                XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer: valid-token")
            }
            mock.register()
        }
        mock.register()
        
        // WHEN
        let user: User = try await client.send(.get("/user")).value
                                               
        // THEN
        XCTAssertEqual(user.login, "kean")
    }
}

private final class MockAuthorizingDelegate: APIClientDelegate {
    var token = "expired-token"
    
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async {
        request.allHTTPHeaderFields = ["Authorization": "Bearer: \(token)"]
    }
    
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool {
        if case .unacceptableStatusCode(let statusCode) = (error as? APIError), statusCode == 401 {
            return true
        }
        return false
    }
}

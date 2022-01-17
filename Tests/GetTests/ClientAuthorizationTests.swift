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

    func testAuthorizationHeaderWidhValidToken() async throws {
        // GIVEN
        delegate.token = Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, arguments in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer valid-token")
        }
        mock.register()

        // WHEN
        try await client.send(.get("/user"))
    }
    
    func testAuthorizationHeaderWithExpiredToken() async throws {
        // GIVEN
        delegate.token = Token(value: "expired-token", expiresDate: Date(timeIntervalSinceNow: -1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, arguments in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer valid-token")
        }
        mock.register()
        
        // WHEN
        try await client.send(.get("/user"))
    }

    func testAuthorizationHeaderWithInvalidToken() async throws {
        // GIVEN
        delegate.token = Token(value: "invalid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 401, data: [
            .get: "Unauthorized".data(using: .utf8)!
        ])
        mock.onRequest = { request, arguments in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer invalid-token")

            var mock = Mock.get(url: url, json: "user")
            mock.onRequest = { request, arguments in
                XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer valid-token")
            }
            mock.register()
        }
        mock.register()

        // WHEN
        try await client.send(.get("/user"))
    }
}

private final class MockAuthorizingDelegate: APIClientDelegate {
    var token: Token!
    let tokenRefresher = TokenRefresher()

    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        let now = Date()

        // Refresh the token if it has expired.
        if token.expiresDate < now {
            token = try await tokenRefresher.refreshToken()
        }

        request.addValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
    }
    
    func shouldClientRetry(_ client: APIClient, withError error: Error) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = (error as? APIError), statusCode == 401 {
            token = try await tokenRefresher.refreshToken()
            return true
        }
        return false
    }
}

private struct Token {
    /// Value for authorization header.
    var value: String
    /// Expiration date of the token. Even within the expiration date,the token may
    /// have been invalidated in the server.
    var expiresDate: Date
}

private struct TokenRefresher {
    func refreshToken() async throws -> Token {
        // TODO: Refresh (make sure you only refresh once if multiple requests fail)
        Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
    }
}

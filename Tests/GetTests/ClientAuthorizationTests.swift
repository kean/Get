// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import Get

final class APIClientAuthorizationTests: XCTestCase {

    func testAuthorizationHeaderWidhValidToken() async throws {
        // GIVEN
        let (client, delegate) = makeSUT()

        delegate.token = Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, _ in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token valid-token")
        }
        mock.register()

        // WHEN
        try await client.send(.get("/user"))
    }

    func testAuthorizationHeaderWithExpiredToken() async throws {
        // GIVEN
        let (client, delegate) = makeSUT()

        delegate.token = Token(value: "expired-token", expiresDate: Date(timeIntervalSinceNow: -1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, _ in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token valid-token")
        }
        mock.register()

        // WHEN
        try await client.send(.get("/user"))
    }

    func testAuthorizationHeaderWithInvalidToken() async throws {
        // GIVEN
        let (client, delegate) = makeSUT()

        delegate.token = Token(value: "invalid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 401, data: [
            .get: "Unauthorized".data(using: .utf8)!
        ])
        mock.onRequest = { request, _ in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token invalid-token")

            var mock = Mock.get(url: url, json: "user")
            mock.onRequest = { request, _ in
                XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token valid-token")
            }
            mock.register()
        }
        mock.register()

        // WHEN
        try await client.send(.get("/user"))
    }

    // MARK: - Helpers

    private func makeSUT(using baseURL: URL? = URL(string: "https://api.github.com"),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (APIClient, MockAuthorizingDelegate) {
        let delegate = MockAuthorizingDelegate()
        let client = APIClient.github {
            $0.delegate = delegate
        }

        trackForMemoryLeak(client, file: file, line: line)

        return (client, delegate)
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

        request.addValue("token \(token.value)", forHTTPHeaderField: "Authorization")
    }

    func shouldClientRetry(_ client: APIClient, for request: URLRequest, withError error: Error) async throws -> Bool {
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

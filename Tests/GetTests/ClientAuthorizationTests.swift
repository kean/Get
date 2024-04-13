// The MIT License (MIT)
//
// Copyright (c) 2021-2024 Alexander Grebenyuk (github.com/kean).

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import Get

final class APIClientAuthorizationTests: XCTestCase {
    var client: APIClient!
    private let delegate = MockAuthorizingDelegate()

    override func setUp() {
        super.setUp()

        client = APIClient.mock {
            $0.delegate = delegate
        }
    }

    func testAuthorizationHeaderWidhValidToken() async throws {
        // GIVEN
        delegate.token = Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, _ in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token valid-token")
        }
        mock.register()

        // WHEN
        try await client.send(Request(path: "/user"))
    }

    func testAuthorizationHeaderWithExpiredToken() async throws {
        // GIVEN
        delegate.token = Token(value: "expired-token", expiresDate: Date(timeIntervalSinceNow: -1000))
        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        mock.onRequest = { request, _ in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "token valid-token")
        }
        mock.register()

        // WHEN
        try await client.send(Request(path: "/user"))
    }

    func testAuthorizationHeaderWithInvalidToken() async throws {
        // GIVEN
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
        try await client.send(Request(path: "/user"))
    }

    func testFailingWillSendRequestDoesntTriggerRetry() async throws {
        // GIVEN
        struct WillSendFailed: Error {}

        class MockFailingDelegate: APIClientDelegate {
            func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
                throw WillSendFailed()
            }

            func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
                XCTFail()
                return false
            }
        }

        let delegate = MockFailingDelegate()
        client = .mock {
            $0.delegate = delegate
        }

        // WHEN
        do {
            try await client.send(Request(path: "/user"))
        } catch {
            print(error)
        }
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

    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = error as? APIError,
           statusCode == 401, attempts == 1 {
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

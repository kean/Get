// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class AuthenticationInterceptorTests: XCTestCase {
    private var client: APIClient!
    private var delegate: AuthenticationInterceptor<StubAuthenticator>!

    override func setUp() {
        super.setUp()

        delegate = AuthenticationInterceptor(authenticator: StubAuthenticator())

        client = APIClient(host: "example.com") {
            $0.delegate = delegate
            $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
    }

    func testRefreshTokenOnlyOnceForParallelRequests() async throws {
        // GIVEN
        delegate.authenticator.token = .invalidToken
        Mock.get(url: URL(string: "https://example.com/user?access_token=refreshed-invalid-token")!,
                 statusCode: 200,
                 json: "user").register()
        Mock.get(url: URL(string: "https://example.com/user?access_token=invalid-token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()

        // WHEN
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.client.send(.get("/user")) }
            group.addTask { try await self.client.send(.get("/user")) }
            group.addTask { try await self.client.send(.get("/user")) }
        }

        // THEN
        XCTAssertEqual(delegate.authenticator.token.value, "refreshed-invalid-token")
        XCTAssertEqual(delegate.authenticator.refreshCount, 1)
    }
}

private class StubAuthenticator: Authenticator {
    typealias Credential = Token

    var token: Token!

    var refreshCount = 0

    func credential() async throws -> Token { token }

    func refresh(credential: Credential, for client: APIClient) async throws -> Credential {
        token = Token(value: "refreshed-\(credential.value)", expiresDate: Date(timeIntervalSinceNow: 1000))
        refreshCount += 1
        return token
    }

    func apply(_ credential: Token, to request: inout URLRequest) async throws {
        request.setQueryItems([.init(name: "access_token", value: credential.value)])
    }

    func didRequest(_: URLRequest, failDueToAuthenticationError error: Error) -> Bool {
        if case .unacceptableStatusCode(let status) = (error as? APIError), status == 401 {
            return true
        }
        return false
    }

    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Token) -> Bool {
        guard let url = urlRequest.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return false }

        return queryItems.contains(where: { $0.name == "access_token" && $0.value == credential.value })
    }
}

private struct Token: Equatable {
    /// Value for authorization header.
    var value: String
    /// Expiration date of the token. Even within the expiration date,the token may
    /// have been invalidated in the server.
    var expiresDate: Date

    static let validToken = Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
    static let invalidToken = Token(value: "invalid-token", expiresDate: Date(timeIntervalSinceNow: 1000))
    static let expiredToken = Token(value: "valid-token", expiresDate: Date(timeIntervalSinceNow: -1000))
}

private extension URLRequest {
    mutating func setQueryItems(_ items: [URLQueryItem]) {
        var components = URLComponents(url: url!, resolvingAgainstBaseURL: true)!
        components.queryItems = items
        url = components.url!
    }
}

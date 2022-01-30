// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class AuthenticationInterceptorTests: XCTestCase {
    private var client: APIClient!
    private var authenticator =  StubAuthenticator()

    override func setUp() {
        super.setUp()

        client = APIClient(host: "example.com") {
            $0.delegate = AuthenticationInterceptor(authenticator: authenticator)
            $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
    }

    func testAuthorizeRequest() async throws {
        // GIVEN
        Mock.get(url: URL(string: "https://example.com/user?token=refreshed-token")!,
                 statusCode: 200,
                 json: "user").register()

        // WHEN
        try await self.client.send(.get("/user"))

        // THEN
        XCTAssertEqual(authenticator.credential.value, "refreshed-token")
        XCTAssertEqual(authenticator.refreshCount, 0)
    }

    func testRefreshAndRetryRequestWhenCredentialIsInvalid() async throws {
        // GIVEN
        authenticator.credential = .invalidCredetial
        Mock.get(url: URL(string: "https://example.com/user?token=refreshed-token")!,
                 statusCode: 200,
                 json: "user").register()
        Mock.get(url: URL(string: "https://example.com/user?token=token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()

        // WHEN
        try await self.client.send(.get("/user"))

        // THEN
        XCTAssertEqual(authenticator.credential.value, "refreshed-token")
        XCTAssertEqual(authenticator.refreshCount, 1)
    }

    func testThrowErrorWhenCredentialIsInvalid() async {
        // GIVEN
        authenticator.credential = .invalidCredetial
        Mock.get(url: URL(string: "https://example.com/user?token=refreshed-token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()
        Mock.get(url: URL(string: "https://example.com/user?token=token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()

        do {
            // WHEN
            try await self.client.send(.get("/user"))
            XCTFail("Should throw an error")
        } catch {
            // THEN
            XCTAssertEqual(authenticator.credential.value, "refreshed-token")
            XCTAssertEqual(authenticator.refreshCount, 1)
            guard case APIError.unacceptableStatusCode(401) = error else {
                XCTFail("Should receive http status code 401")
                return
            }
        }
    }

    func testThrowErrorWhenFailToGetCredential() async {
        // GIVEN
        authenticator.credential = .invalidCredetial
        authenticator.shouldFailToGetCredential = true

        do {
            // WHEN
            try await self.client.send(.get("/user"))
            XCTFail("Should throw an error")
        } catch {
            // THEN
            XCTAssertEqual(authenticator.credential.value, "token")
            XCTAssertEqual(authenticator.refreshCount, 0)
            XCTAssertEqual((error as? AuthenticationError)?.reason, .loadingCredentialFailed)
        }
    }

    func testThrowErrorWhenFailToApplyCredential() async {
        // GIVEN
        authenticator.credential = .invalidCredetial
        authenticator.shouldFailToApplyCredential = true

        do {
            // WHEN
            try await self.client.send(.get("/user"))
            XCTFail("Should throw an error")
        } catch {
            // THEN
            XCTAssertEqual(authenticator.credential.value, "token")
            XCTAssertEqual(authenticator.refreshCount, 0)
            XCTAssertEqual((error as? AuthenticationError)?.reason, .applyingCredentialFailed)
        }
    }

    func testThrowErrorWhenFailToRefreshCredential() async {
        // GIVEN
        authenticator.credential = .invalidCredetial
        authenticator.shouldFailToRefreshCredential = true
        Mock.get(url: URL(string: "https://example.com/user?token=refreshed-token")!,
                 statusCode: 200,
                 json: "user").register()
        Mock.get(url: URL(string: "https://example.com/user?token=token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()

        do {
            // WHEN
            try await self.client.send(.get("/user"))
            XCTFail("Should throw an error")
        } catch {
            // THEN
            XCTAssertEqual(authenticator.credential.value, "token")
            XCTAssertEqual(authenticator.refreshCount, 0)
            XCTAssertEqual((error as? AuthenticationError)?.reason, .refreshingCredentialFailed)
        }
    }

    func testRefreshCredentialOnlyOnceForParallelRequests() async throws {
        // GIVEN
        authenticator.credential = .invalidCredetial
        Mock.get(url: URL(string: "https://example.com/user?token=refreshed-token")!,
                 statusCode: 200,
                 json: "user").register()
        Mock.get(url: URL(string: "https://example.com/user?token=token")!,
                 statusCode: 401,
                 message: "Unauthorized").register()

        // WHEN
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.client.send(.get("/user")) }
            group.addTask { try await self.client.send(.get("/user")) }
            group.addTask { try await self.client.send(.get("/user")) }
        }

        // THEN
        XCTAssertEqual(authenticator.credential.value, "refreshed-token")
        XCTAssertEqual(authenticator.refreshCount, 1)
    }
}

private class StubAuthenticator: Authenticator {
    typealias Credential = TestCredential

    enum TestError: Error {
        case error
    }

    var credential: TestCredential = .validCredential

    var shouldFailToGetCredential = false
    var shouldFailToApplyCredential = false
    var shouldFailToRefreshCredential = false
    var refreshCount = 0

    func credential() async throws -> Credential {
        guard !shouldFailToGetCredential else { throw TestError.error }
        return credential
    }

    func apply(_ credential: Credential, to request: inout URLRequest) async throws {
        guard !shouldFailToApplyCredential else { throw TestError.error }
        request.setQueryItems([.init(name: "token", value: credential.value)])
    }

    func refresh(credential: Credential, for client: APIClient) async throws -> Credential {
        guard !shouldFailToRefreshCredential else { throw TestError.error }
        self.credential = TestCredential(value: "refreshed-\(credential.value)",
                                         expiresDate: Date(timeIntervalSinceNow: 1000))
        refreshCount += 1
        return self.credential
    }

    func didRequest(_: URLRequest, failDueToAuthenticationError error: Error) -> Bool {
        if case .unacceptableStatusCode(let status) = (error as? APIError), status == 401 {
            return true
        }
        return false
    }

    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Credential) -> Bool {
        guard let url = urlRequest.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return false }

        return queryItems.contains(where: { $0.name == "token" && $0.value == credential.value })
    }
}

private struct TestCredential: Equatable {
    /// Value for authorization header.
    var value: String
    /// Expiration date of the token. Even within the expiration date,the token may
    /// have been invalidated in the server.
    var expiresDate: Date

    static let validCredential = TestCredential(value: "refreshed-token",
                                                expiresDate: Date(timeIntervalSinceNow: 1000))
    static let invalidCredetial = TestCredential(value: "token",
                                                 expiresDate: Date(timeIntervalSinceNow: 1000))
    static let expiredCredential = TestCredential(value: "refreshed-token",
                                                  expiresDate: Date(timeIntervalSinceNow: -1000))
}

private extension URLRequest {
    mutating func setQueryItems(_ items: [URLQueryItem]) {
        var components = URLComponents(url: url!, resolvingAgainstBaseURL: true)!
        components.queryItems = items
        url = components.url!
    }
}
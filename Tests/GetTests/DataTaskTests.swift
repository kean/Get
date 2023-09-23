// The MIT License (MIT)
//
// Copyright (c) 2021-2023 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class DataTaskTests: XCTestCase {
    var client: APIClient!

    override func setUp() {
        super.setUp()

        self.client = .mock()
    }

    // MARK: Basic Requests

    // You don't need to provide a predefined list of resources in your app.
    // You can define the requests inline instead.
    func testDefiningRequestInline() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let dataTask = await client.dataTask(with: Request(path: "/user"))
        let user = try await dataTask.response.decode(User.self)

        // THEN
        XCTAssertEqual(user.login, "kean")
    }

    func testResponseMetadata() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let response = try await client.dataTask(with: Paths.user.get).response

        // THEN the client returns not just the value, but data, original
        // request, and more
        let value = try await response.decode(User.self)
        XCTAssertEqual(value.login, "kean")
        XCTAssertEqual(response.data.count, 1321)
        XCTAssertEqual(response.originalRequest?.url, url)
        XCTAssertEqual(response.statusCode, 200)
#if !os(Linux)
        let metrics = try XCTUnwrap(response.metrics)
        let transaction = try XCTUnwrap(metrics.transactionMetrics.first)
        XCTAssertEqual(transaction.request.url, URL(string: "https://api.github.com/user"))
#endif
    }

    // MARK: Failures

    func testFailingRequest() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 500, data: [
            .get: "nope".data(using: .utf8)!
        ]).register()

        // WHEN
        do {
            let _ = try await client.dataTask(with: Request(path: "/user")).response
        } catch {
            // THEN
            let error = try XCTUnwrap(error as? APIError)
            switch error {
            case .unacceptableStatusCode(let code):
                XCTAssertEqual(code, 500)
            }
        }
    }

#warning("easier way to ignore response?")
    func testSendingRequestWithInvalidURL() async throws {
        // GIVEN
        let request = Request(path: "https://api.github.com  ---invalid")

        // WHEN
        do {
            try await client.dataTask(with: request).response
        } catch {
            // THEN
            let error = try XCTUnwrap(error as? URLError)
            XCTAssertEqual(error.code, .badURL)
        }
    }

    // MARK: Cancellation

    func testCancellingRequests() async throws {
        // Given
        let url = URL(string: "https://api.github.com/users/kean")!
        var mock = Mock.get(url: url, json: "user")
        mock.delay = DispatchTimeInterval.seconds(60)
        mock.register()

        // When
        let task = Task { [client] in
            try await client!.dataTask(with: Request(path: "/users/kean")).response
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            task.cancel()
        }

        // Then
        do {
            _ = try await task.value
        } catch {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
    }

    // MARK: Decoding

    func testDecodeCurrentValueFromResponse() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        let request = Request<User>(path: "/user")

        // WHEN
        let response = try await client.dataTask(with: request).response
        let user = try await response.value

        // THEN
        XCTAssertEqual(user.login, "kean")
    }

    func testDecodeSpecificValueFromResponse() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        let request = Request<User>(path: "/user")

        // WHEN
        let response = try await client.dataTask(with: request).response
        let user = try await response.decode(User.self)

        // THEN
        XCTAssertEqual(user.login, "kean")
    }

    // You don't need to provide a predefined list of resources in your app.
    // You can define the requests inline instead.
    func testConvenienceValueAccessors() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        let request = Request<User>(path: "/user")

        // WHEN
        let user = try await client.dataTask(with: request).value

        // THEN
        XCTAssertEqual(user.login, "kean")
    }
}

#warning("test cancelling during waiting for retry")

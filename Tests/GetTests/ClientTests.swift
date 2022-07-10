// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class APIClientTests: XCTestCase {

    // MARK: Basic Requests

    // You don't need to provide a predefined list of resources in your app.
    // You can define the requests inline instead.
    func testDefiningRequestInline() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let user: User = try await client.send(.get("/user")).value

        // THEN
        XCTAssertEqual(user.login, "kean")
    }

    func testResponseMetadata() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let response = try await client.send(Paths.user.get)

        // THEN the client returns not just the value, but data, original
        // request, and more
        XCTAssertEqual(response.value.login, "kean")
        XCTAssertEqual(response.data.count, 1321)
        XCTAssertEqual(response.request.url, url)
        XCTAssertEqual(response.statusCode, 200)
#if !os(Linux)
        let metrics = try XCTUnwrap(response.metrics)
        let transaction = try XCTUnwrap(metrics.transactionMetrics.first)
        XCTAssertEqual(transaction.request.url, URL(string: "https://api.github.com/user")!)
#endif
    }

    func testCancellingRequests() async throws {
        // Given
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/users/kean")!
        var mock = Mock.get(url: url, json: "user")
        mock.delay = DispatchTimeInterval.seconds(60)
        mock.register()

        // When
        let task = Task {
            try await client.send(.get("/users/kean"))
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

    // MARK: Response Types

    // func value(for:) -> Decodable
    func testResponseDecodable() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let user: User = try await client.send(.get("/user")).value

        // THEN returns decoded JSON
        XCTAssertEqual(user.login, "kean")
    }

    // func value(for:) -> Decodable
    func testResponseDecodableOptional() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .html, statusCode: 200, data: [
            .get: Data()
        ]).register()

        // WHEN
        let user: User? = try await client.send(.get("/user")).value

        // THEN returns decoded JSON
        XCTAssertNil(user)
    }

    // func value(for:) -> Decodable
    func testResponseEmpty() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .html, statusCode: 200, data: [
            .get: Data()
        ]).register()

        // WHEN
        try await client.send(.get("/user")).value
    }

    // func value(for:) -> Data
    func testResponseData() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .html, statusCode: 200, data: [
            .get: "<h>Hello</h>".data(using: .utf8)!
        ]).register()

        // WHEN
        let data: Data = try await client.send(.get("/user")).value

        // THEN return unprocessed data (NOT what Data: Decodable does by default)
        XCTAssertEqual(String(data: data, encoding: .utf8), "<h>Hello</h>")
    }

    // func value(for:) -> String
    func testResponeString() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: "hello".data(using: .utf8)!
        ]).register()

        // WHEN
        let text: String = try await client.send(.get("/user")).value

        // THEN
        XCTAssertEqual(text, "hello")
    }

    func testDecodingWithVoidResponse() async throws {
#if os(watchOS)
        throw XCTSkip("Mocker URLProtocol isn't being called for POST requests on watchOS")
#endif

        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .post: json(named: "user")
        ]).register()

        // WHEN
        let request = Request<Void>.post("/user", body: ["login": "kean"])
        try await client.send(request)
    }

    // MARK: - Retries

    func testRetries() async throws {
        // GIVEN
        final class RetryingDelegate: APIClientDelegate {
            func client(_ client: APIClient, shouldRetryRequest request: URLRequest, attempts: Int, error: Error) async throws -> Bool {
                attempts < 3
            }
        }

        let client = APIClient.github {
            $0.delegate = RetryingDelegate()
        }

        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 401, data: [
            .get: "Unauthorized".data(using: .utf8)!
        ])
        var attemptsCount = 0
        mock.onRequest = { _, _ in
            attemptsCount += 1
        }
        mock.register()

        // WHEN
        do {
            try await client.send(.get("/user"))
            XCTFail("Expected request to fail")
        } catch {
            XCTAssertEqual(attemptsCount, 3)
            let error = try XCTUnwrap(error as? APIError)
            switch error {
            case let .unacceptableStatusCode(statusCode):
                XCTAssertEqual(statusCode, 401)
            }
        }
    }

    // MARK: - Fetching Data

    func testFetchData() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let response = try await client.data(for: .get("/user"))

        // THEN
        let user = try JSONDecoder().decode(User.self, from: response.data)
        XCTAssertEqual(user.login, "kean")
    }

    // MARK: - Downloads

#if !os(Linux)
    func testDownloads() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let response = try await client.download(for: .get("/user"))

        // THEN
        let data = try Data(contentsOf: response.location)
        let user = try JSONDecoder().decode(User.self, from: data)
        XCTAssertEqual(user.login, "kean")
    }
#endif

    // MARK: - Uploads

    func testUpload() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .post: json(named: "user")
        ]).register()

        // WHEN

        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "user", withExtension: "json"))
        let user: User = try await client.upload(for: .post("/user"), fromFile: fileURL).value

        // THEN
        XCTAssertEqual(user.login, "kean")
    }

    // MARK: - Request Body

    func testPassEncodableRequestBody() async throws {
#if os(watchOS)
        throw XCTSkip("Mocker URLProtocol isn't being called for POST requests on watchOS")
#endif

        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
            .post: json(named: "user")
        ])
        mock.onRequest = { request, _ in
            guard let body = request.httpBody ?? request.httpBodyStream?.data,
                  let json = try? JSONSerialization.jsonObject(with: body, options: []),
                  let user = json as? [String: Any] else {
                return XCTFail()
            }
            XCTAssertEqual(user["id"] as? Int, 1)
            XCTAssertEqual(user["login"] as? String, "kean")
        }
        mock.register()

        // WHEN
        let body = User(id: 1, login: "kean")
        let request = Request<Void>.post("/user", body: body)
        try await client.send(request)
    }

    func testPassingNilBody() async throws {
#if os(watchOS)
        throw XCTSkip("Mocker URLProtocol isn't being called for POST requests on watchOS")
#endif

        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
            .post: json(named: "user")
        ])
        mock.onRequest = { request, _ in
            XCTAssertNil(request.httpBody)
            XCTAssertNil(request.httpBodyStream)
        }
        mock.register()

        // WHEN
        let body: User? = nil
        let request = Request<Void>.post("/user", body: body)
        try await client.send(request)
    }

    // MARK: - Configuring Request

    func testConfigureRequest() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        var mock = Mock.get(url: url, json: "user")
        var request: URLRequest?
        mock.onRequest = { a, _ in
            request = a
        }
        mock.register()

        // WHEN
        let response: Response<User> = try await client.send(.get("/user")) {
            $0.cachePolicy = .reloadIgnoringLocalCacheData
        }

        // THEN
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(response.value.login, "kean")
    }

    // MARK: - Absolute and Relative Paths

    func testRelativePaths() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN/THEN
        do {
            _ = try await client.send(.get("/user")) {
                XCTAssertEqual($0.url, URL(string: "https://api.github.com/user"))
            }
        } catch { /* Do nothing */ }

        do {
            _ = try await client.send(.get("user")) {
                XCTAssertEqual($0.url, URL(string: "https://api.github.com/user"))
            }
        } catch { /* Do nothing */ }
    }

    func testRelativePathsSlash() async throws {
        // GIVEN
        let client = makeSUT(using: URL(string: "https://api.github.com/"))

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN/THEN
        do {
            _ = try await client.send(.get("/user")) {
                XCTAssertEqual($0.url, URL(string: "https://api.github.com/user"))
            }
        } catch { /* Do nothing */ }

        do {
            _ = try await client.send(.get("user")) {
                XCTAssertEqual($0.url, URL(string: "https://api.github.com/user"))
            }
        } catch { /* Do nothing */ }
    }

    func testAbsolutePaths() async throws {
        // GIVEN
        let client = makeSUT()

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        do {
            _ = try await client.send(.get("https://example.com/user")) {
                XCTAssertEqual($0.url, URL(string: "https://example.com/user"))
            }
        } catch { /* Do nothing */ }
    }

    // MARK: - Helpers

    private func makeSUT(using baseURL: URL? = URL(string: "https://api.github.com"),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> APIClient {
        let client = APIClient.github()
        trackForMemoryLeak(client, file: file, line: line)
        return client
    }
}

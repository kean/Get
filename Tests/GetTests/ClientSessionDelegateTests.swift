// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

#if !os(Linux)
final class APIClientSessionDelegateTests: XCTestCase {
    private let delegate = SessionDelegate()
    private var client: APIClient!

    override func setUp() {
        super.setUp()

        self.client = .github {
            $0.sessionDelegate = delegate
        }
    }

    // MARK: - Global Delegate

    func testThatMetricsAreCollected() async throws {
        #if os(watchOS)
        throw XCTSkip("Mocker URLProtocol isn't being called for requests on watchOS")
        #endif

        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        try await client.send(.get("/user"))

        // THEN
        XCTAssertEqual(delegate.metrics.count, 1)
        let metrics = try XCTUnwrap(delegate.metrics.first?.value)
        let transaction = try XCTUnwrap(metrics.transactionMetrics.first)
        XCTAssertEqual(transaction.request.url, URL(string: "https://api.github.com/user")!)
    }

    // MARK: - Per-Task Delegate

    func testSettingDelegate() async throws {
        // GIVEN
        self.client = .github()

        final class MockDelegate: NSObject, URLSessionDataDelegate {
            var response: URLResponse?

            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
                self.response = response
                return .cancel
            }
        }

        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let delegate = MockDelegate()
        let request = Request<Void>.get("/user")
        do {
            try await client.send(request, delegate: delegate)
            XCTFail("Request was supposed to be cancelled")
        } catch {
            // Do nothing
        }

        // THEN
        XCTAssertEqual(delegate.response?.url, url)
    }

    func testSettingDelegateCallbackBased() async throws {
        // GIVEN
        self.client = .github()

        final class MockDelegate: NSObject, URLSessionDataDelegate {
            var response: URLResponse?

            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
                self.response = response
                completionHandler(.cancel)
            }
        }
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let delegate = MockDelegate()
        let request = Request<Void>.get("/user")
        do {
            try await client.send(request, delegate: delegate)
            XCTFail("Request was supposed to be cancelled")
        } catch {
            // Do nothing
        }

        // THEN
        XCTAssertEqual(delegate.response?.url, url)
    }

    func testSetTaskDelegateTogetherWithSessionDelegate() async throws {
        // GIVEN
        final class MockDelegate: NSObject, URLSessionDataDelegate {
            var response: URLResponse?

            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
                self.response = response
                completionHandler(.cancel)
            }
        }
        let url = URL(string: "https://api.github.com/user")!
        Mock.get(url: url, json: "user").register()

        // WHEN
        let delegate = MockDelegate()
        let request = Request<Void>.get("/user")
        do {
            try await client.send(request, delegate: delegate)
            XCTFail("Request was supposed to be cancelled")
        } catch {
            // Do nothing
        }

        // THEN
        XCTAssertEqual(delegate.response?.url, url)
    }
}

private final class SessionDelegate: NSObject, URLSessionTaskDelegate {
    var metrics: [URLSessionTask: URLSessionTaskMetrics] = [:]

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics[task] = metrics
    }
}
#endif

// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

#if !os(Linux)
final class APIClientSessionDelegateTests: XCTestCase {

    func testThatMetricsAreCollected() async throws {
        #if os(watchOS)
        throw XCTSkip("Mocker URLProtocol isn't being called for requests on watchOS")
        #endif

        // GIVEN
        let (client, delegate) = makeSUT()

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

    // MARK: - Helpers

    private func makeSUT(using baseURL: URL? = URL(string: "https://api.github.com"),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (APIClient, SessionDelegate) {
        let delegate = SessionDelegate()
        let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
            $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
            $0.sessionConfiguration.urlCache = nil
            $0.sessionDelegate = delegate
        }

        trackForMemoryLeak(client, file: file, line: line)

        return (client, delegate)
    }
}

private final class SessionDelegate: NSObject, URLSessionTaskDelegate {
    var metrics: [URLSessionTask: URLSessionTaskMetrics] = [:]

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics[task] = metrics
    }
}
#endif

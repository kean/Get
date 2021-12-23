// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class APIClientSessionDelegateTests: XCTestCase {
    var client: APIClient!
    private var delegate: SessionDelegate!
    
    override func setUp() {
        super.setUp()
        
        delegate = SessionDelegate()
        client = APIClient(host: "api.github.com") {
            $0.sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
            $0.sessionConfiguration.urlCache = nil
            $0.sessionDelegate = delegate
        }
    }
    
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
}

private final class SessionDelegate: NSObject, URLSessionTaskDelegate {
    var metrics: [URLSessionTask: URLSessionTaskMetrics] = [:]
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics[task] = metrics
    }
}

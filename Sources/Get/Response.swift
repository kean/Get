// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A response with an associated value and metadata.
public struct Response<T> {
    /// Decoded response value.
    public var value: T
    /// Original response data.
    public var data: Data
    /// Original request.
    public var request: URLRequest
    /// Original response.
    public var response: URLResponse
    /// Response HTTP status code.
    public var statusCode: Int? { (response as? HTTPURLResponse)?.statusCode }
    /// Task metrics collected for the request.
    public var metrics: URLSessionTaskMetrics?

    /// Initializes the response.
    public init(value: T, data: Data, request: URLRequest, response: URLResponse, metrics: URLSessionTaskMetrics? = nil) {
        self.value = value
        self.data = data
        self.request = request
        self.response = response
        self.metrics = metrics
    }
}

extension Response where T == URL {
    public var location: URL { value }
}

extension Response: @unchecked Sendable where T: Sendable {}

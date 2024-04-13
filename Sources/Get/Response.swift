// The MIT License (MIT)
//
// Copyright (c) 2021-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A response with an associated value and metadata.
public struct Response<T> {
    /// Decoded response value.
    public let value: T
    /// Original response.
    public let response: URLResponse
    /// Response HTTP status code.
    public var statusCode: Int? { (response as? HTTPURLResponse)?.statusCode }
    /// Original response data.
    public let data: Data
    /// Original request.
    public var originalRequest: URLRequest? { task.originalRequest }
    /// The URL request object currently being handled by the task. May be
    /// different from the original request.
    public var currentRequest: URLRequest? { task.currentRequest }
    /// Completed task.
    public let task: URLSessionTask
    /// Task metrics collected for the request.
    public let metrics: URLSessionTaskMetrics?

    /// Initializes the response.
    public init(value: T, data: Data, response: URLResponse, task: URLSessionTask, metrics: URLSessionTaskMetrics? = nil) {
        self.value = value
        self.data = data
        self.response = response
        self.task = task
        self.metrics = metrics
    }

    /// Returns a response containing the mapped value.
    public func map<U>(_ closure: (T) throws -> U) rethrows -> Response<U> {
        Response<U>(value: try closure(value), data: data, response: response, task: task, metrics: metrics)
    }
}

extension Response where T == URL {
    /// The location of the downloaded file. Only applicable for requests
    /// performed using ``APIClient/download(for:delegate:configure:)``.
    public var location: URL { value }
}

extension Response: @unchecked Sendable where T: Sendable {}

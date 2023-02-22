// The MIT License (MIT)
//
// Copyright (c) 2021-2023 Alexander Grebenyuk (github.com/kean).

import Foundation
import Combine

public final class DataTask<T>: @unchecked Sendable {
    var task: Task<Response, Error>!

    public var delegate: URLSessionDataDelegate?

#warning("implement progress")
    public var progress: some Publisher<Float, Never> { _progress }
    var _progress = CurrentValueSubject<Float, Never>(0.0)

    public func cancel() {
        task.cancel()
    }

    public var response: Response {
        get async throws { try await result.get() }
    }

    public var result: Result<Response, Error> {
        get async {
            await withTaskCancellationHandler(operation: {
                await task.result
            }, onCancel: {
                cancel()
            })
        }
    }

#warning("add publisher in addition to Async/Await?")

#warning("this isn't thread-safe")
    public var configure: (@Sendable (inout URLRequest) -> Void)?

    /// A response with an associated value and metadata.
    public struct Response: TaskDesponse {
        /// Original response.
        public let response: URLResponse
        /// Original response data.
        public let data: Data
        /// Completed task.
        public let task: URLSessionTask
        /// Task metrics collected for the request.
        public let metrics: URLSessionTaskMetrics?

        /// Initializes the response.
        public init(data: Data, response: URLResponse, task: URLSessionTask, metrics: URLSessionTaskMetrics? = nil) {
            self.data = data
            self.response = response
            self.task = task
            self.metrics = metrics
        }
    }
}

// Pros: this approach will allow users to extend the task with custom decoders

extension DataTask where T: Decodable {
    public var value: T {
        get async throws { try await response.decode(T.self) }
    }
}

extension DataTask.Response where T: Decodable {
    public var value: T {
        get async throws { try await decode(T.self) }
    }
}

extension DataTask.Response {
    public func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        try await Get.decode(data, using: decoder)
    }
}

// Silences Sendable warnings in some Foundation APIs.
struct Box<T>: @unchecked Sendable {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

#warning("add in docs that you can easily add custom decoders to the requests withot modifying the client iself")

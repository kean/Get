// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct AnyEncodable: Encodable {
    private let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

extension URLRequest {
    public func cURLDescription() -> String {
        guard let url = url, let method = httpMethod else {
            return "$ curl command generation failed"
        }
        var components = ["curl -v"]
        components.append("-X \(method)")
        for header in allHTTPHeaderFields ?? [:] {
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.key): \(escapedValue)\"")
        }
        if let httpBodyData = httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escapedBody)\"")
        }
        components.append("\"\(url.absoluteString)\"")
        return components.joined(separator: " \\\n\t")
    }
}

actor Serializer {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(decoder: JSONDecoder?, encoder: JSONEncoder?) {
        if let decoder = decoder {
            self.decoder = decoder
        } else {
            self.decoder = JSONDecoder()
            self.decoder.dateDecodingStrategy = .iso8601
        }
        if let encoder = encoder {
            self.encoder = encoder
        } else {
            self.encoder = JSONEncoder()
            self.encoder.dateEncodingStrategy = .iso8601
        }
    }

    func decode<T: Decodable>(_ data: Data) async throws -> T {
        try decoder.decode(T.self, from: data)
    }

    func encode<T: Encodable>(_ entity: T) async throws -> Data {
        try encoder.encode(entity)
    }
}

// A simple URLSession wrapper adding async/await APIs compatible with older platforms.
final class DataLoader: NSObject, URLSessionDataDelegate {
    private var handlers = [URLSessionTask: TaskHandler]()
    private typealias Completion = (Result<(Data, URLResponse, URLSessionTaskMetrics?), Error>) -> Void

    /// Loads data with the given request.
    func data(for request: URLRequest, session: URLSession) async throws -> (Data, URLResponse, URLSessionTaskMetrics?) {
        final class Box { var task: URLSessionTask? }
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                box.task = self.loadData(with: request, session: session) { result in
                    continuation.resume(with: result)
                }
            }
        })
    }

    private func loadData(with request: URLRequest, session: URLSession, completion: @escaping Completion) -> URLSessionTask {
        let task = session.dataTask(with: request)
        session.delegateQueue.addOperation {
            self.handlers[task] = TaskHandler(completion: completion)
        }
        task.resume()
        return task
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = handlers[task] else { return }
        handlers[task] = nil
        if let response = task.response, error == nil {
            handler.completion(.success((handler.data ?? Data(), response, handler.metrics)))
        } else {
            handler.completion(.failure(error ?? URLError(.unknown)))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        handlers[task]?.metrics = metrics
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let handler = handlers[dataTask] else {
            return
        }
        if handler.data == nil {
            handler.data = Data()
        }
        handler.data!.append(data)
    }

    private final class TaskHandler {
        var data: Data?
        var metrics: URLSessionTaskMetrics?
        let completion: Completion

        init(completion: @escaping Completion) {
            self.completion = completion
        }
    }
}

/// Allows users to monitor URLSession.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class URLSessionProxyDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    private var delegate: URLSessionDelegate
    #if !os(Linux)
    private let interceptedSelectors: Set<Selector>
    #endif
    private let loader: DataLoader

    static func make(loader: DataLoader, delegate: URLSessionDelegate?) -> URLSessionDelegate {
        guard let delegate = delegate else { return loader }
        return URLSessionProxyDelegate(loader: loader, delegate: delegate)
    }

    init(loader: DataLoader, delegate: URLSessionDelegate) {
        self.loader = loader
        self.delegate = delegate
        #if !os(Linux)
        self.interceptedSelectors = [
            #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didFinishCollecting:))
        ]
        #endif
    }

    // MARK: URLSessionDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        loader.urlSession(session, dataTask: dataTask, didReceive: data)
        #if !os(Linux)
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
        #else
        (delegate as? URLSessionDataDelegate)?.urlSession(session, dataTask: dataTask, didReceive: data)
        #endif
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        loader.urlSession(session, task: task, didCompleteWithError: error)
        #if !os(Linux)
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
        #else
        (delegate as? URLSessionTaskDelegate)?.urlSession(session, task: task, didCompleteWithError: error)
        #endif
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        loader.urlSession(session, task: task, didFinishCollecting: metrics)
        #if !os(Linux)
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didFinishCollecting: metrics)
        #else
        (delegate as? URLSessionTaskDelegate)?.urlSession(session, task: task, didFinishCollecting: metrics)
        #endif
    }

    // MARK: Proxy

    #if !os(Linux)
    override func responds(to aSelector: Selector!) -> Bool {
        if interceptedSelectors.contains(aSelector) {
            return true
        }
        return delegate.responds(to: aSelector) || super.responds(to: aSelector)
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        interceptedSelectors.contains(selector) ? nil : delegate
    }
    #endif
}

extension OperationQueue {
    convenience init(maxConcurrentOperationCount: Int) {
        self.init()
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
}

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
    func data(for request: URLRequest, session: URLSession, delegate: URLSessionDataDelegate?) async throws -> (Data, URLResponse, URLSessionTaskMetrics?) {
        final class Box { var task: URLSessionTask? }
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                box.task = self.loadData(with: request, session: session, delegate: delegate) { result in
                    continuation.resume(with: result)
                }
            }
        })
    }

    private func loadData(with request: URLRequest, session: URLSession, delegate: URLSessionDataDelegate?, completion: @escaping Completion) -> URLSessionTask {
        let task = session.dataTask(with: request)
        session.delegateQueue.addOperation {
            self.handlers[task] = TaskHandler(delegate: delegate, completion: completion)
        }
        task.resume()
        return task
    }

    private final class TaskHandler {
        let delegate: URLSessionDataDelegate?
        let completion: Completion
        var data: Data?
        var metrics: URLSessionTaskMetrics?

        init(delegate: URLSessionDataDelegate?, completion: @escaping Completion) {
            self.delegate = delegate
            self.completion = completion
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let handler = handlers[dataTask] else { return }
#if os(Linux)
        handler.delegate?.urlSession(session, dataTask: dataTask, didReceive: data)
#else
        handler.delegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
#endif
        if handler.data == nil {
            handler.data = Data()
        }
        handler.data!.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = handlers[task] else { return }
        handlers[task] = nil
#if os(Linux)
        handler.delegate?.urlSession(session, task: task, didCompleteWithError: error)
#else
        handler.delegate?.urlSession?(session, task: task, didCompleteWithError: error)
#endif
        if let response = task.response, error == nil {
            handler.completion(.success((handler.data ?? Data(), response, handler.metrics)))
        } else {
            handler.completion(.failure(error ?? URLError(.unknown)))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        handlers[task]?.metrics = metrics
    }
}

#if !os(Linux)
extension DataLoader {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if handlers[dataTask]?.delegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) != nil {
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        handlers[dataTask]?.delegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        handlers[dataTask]?.delegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if handlers[dataTask]?.delegate?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(proposedResponse)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if handlers[task]?.delegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(request)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if handlers[task]?.delegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        if handlers[task]?.delegate?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(.continueLoading, nil)
        }
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        handlers[task]?.delegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            handlers[task]?.delegate?.urlSession?(session, didCreateTask: task)
        } else {
            // Doesn't exist on earlier versions
        }
    }
}
#else
extension DataLoader {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if handlers[dataTask]?.delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) != nil {
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if handlers[dataTask]?.delegate?.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(proposedResponse)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if handlers[task]?.delegate?.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(request)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if handlers[task]?.delegate?.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        if handlers[task]?.delegate?.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) != nil {
            // Do nothing, delegate called
        } else {
            completionHandler(.continueLoading, nil)
        }
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        handlers[task]?.delegate?.urlSession(session, taskIsWaitingForConnectivity: task)
    }
}
#endif

#if !os(Linux)
/// Allows users to monitor URLSession.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class URLSessionProxyDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    private var delegate: URLSessionDelegate
    private let interceptedSelectors: Set<Selector>
    private let loader: DataLoader

    static func make(loader: DataLoader, delegate: URLSessionDelegate?) -> URLSessionDelegate {
        guard let delegate = delegate else { return loader }
        return URLSessionProxyDelegate(loader: loader, delegate: delegate)
    }

    init(loader: DataLoader, delegate: URLSessionDelegate) {
        self.loader = loader
        self.delegate = delegate
        self.interceptedSelectors = [
            #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didFinishCollecting:))
        ]
    }

    // MARK: URLSessionDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        loader.urlSession(session, dataTask: dataTask, didReceive: data)
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        loader.urlSession(session, task: task, didCompleteWithError: error)
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        loader.urlSession(session, task: task, didFinishCollecting: metrics)
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didFinishCollecting: metrics)
    }

    // MARK: Proxy

    override func responds(to aSelector: Selector!) -> Bool {
        if interceptedSelectors.contains(aSelector) {
            return true
        }
        return delegate.responds(to: aSelector) || super.responds(to: aSelector)
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        interceptedSelectors.contains(selector) ? nil : delegate
    }
}
#endif

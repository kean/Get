// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
            // Do nothing, delegate called
        } else {
            completionHandler(.allow)
        }
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

#if swift(>=5.7)
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            handlers[task]?.delegate?.urlSession?(session, didCreateTask: task)
        } else {
            // Doesn't exist on earlier versions
        }
    }
#endif
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
}
#endif

// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// A simple URLSession wrapper adding async/await APIs compatible with older platforms.
final class DataLoader: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {
    private var handlers = [URLSessionTask: TaskHandler]()

    var userSessionDelegate: URLSessionDelegate? {
        didSet {
            userTaskDelegate = userSessionDelegate as? URLSessionTaskDelegate
            userDataDelegate = userSessionDelegate as? URLSessionDataDelegate
            userDownloadDelegate = userSessionDelegate as? URLSessionDownloadDelegate
        }
    }
    private var userTaskDelegate: URLSessionTaskDelegate?
    private var userDataDelegate: URLSessionDataDelegate?
    private var userDownloadDelegate: URLSessionDownloadDelegate?

    private lazy var downloadDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("com.github.kean.get/Downloads/")

    func data(for request: URLRequest, session: URLSession, delegate: URLSessionDataDelegate?) async throws -> (Data, URLResponse, URLSessionTaskMetrics?) {
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                let task = session.dataTask(with: request)
                session.delegateQueue.addOperation {
                    let handler = DataTaskHandler(delegate: delegate)
                    handler.completion = continuation.resume(with:)
                    self.handlers[task] = handler
                }
                task.resume()
                box.task = task
            }
        })
    }

    func download(for request: URLRequest, session: URLSession, delegate: URLSessionDownloadDelegate?) async throws -> (URL, URLResponse, URLSessionTaskMetrics?) {
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                let task = session.downloadTask(with: request)
                session.delegateQueue.addOperation {
                    let handler = DownloadTaskHandler(delegate: delegate)
                    handler.completion = continuation.resume(with:)
                    self.handlers[task] = handler
                }
                task.resume()
                box.task = task
            }
        })
    }

    func upload(for request: URLRequest, fromFile fileURL: URL, session: URLSession, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse, URLSessionTaskMetrics?) {
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                let task = session.uploadTask(with: request, fromFile: fileURL)
                session.delegateQueue.addOperation {
                    let handler = DataTaskHandler(delegate: delegate)
                    handler.completion = continuation.resume(with:)
                    self.handlers[task] = handler
                }
                task.resume()
                box.task = task
            }
        })
    }

    private final class Box {
        var task: URLSessionTask?
    }

    // MARK: - URLSessionDelegate

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
#if os(Linux)
        userSessionDelegate?.urlSession(session, didBecomeInvalidWithError: error)
#else
        userSessionDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
#endif
    }

#if !os(Linux)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if #available(macOS 11.0, *) {
            userSessionDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
        } else {
            // Fallback on earlier versions
        }
    }
#endif

    // MARK: - URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = handlers[task] else { return assertionFailure() }
        handlers[task] = nil
#if os(Linux)
        handler.delegate?.urlSession(session, task: task, didCompleteWithError: error)
        userTaskDelegate?.urlSession(session, task: task, didCompleteWithError: error)
#else
        handler.delegate?.urlSession?(session, task: task, didCompleteWithError: error)
        userTaskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
#endif
        switch handler {
        case let handler as DataTaskHandler:
            if let response = task.response, error == nil {
                handler.completion?(.success((handler.data ?? Data(), response, handler.metrics)))
            } else {
                handler.completion?(.failure(error ?? URLError(.unknown)))
            }
        case let handler as DownloadTaskHandler:
            if let location = handler.location, let response = task.response, error == nil {
                handler.completion?(.success((location, response, handler.metrics)))
            } else {
                handler.completion?(.failure(error ?? URLError(.unknown)))
            }
        default:
            break
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let handler = handlers[task]
        handler?.metrics = metrics
#if os(Linux)
        handler?.delegate?.urlSession(session, task: task, didFinishCollecting: metrics)
        userTaskDelegate?.urlSession(session, task: task, didFinishCollecting: metrics)
#else
        handler?.delegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
        userTaskDelegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
#endif
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
#if os(Linux)
        handlers[task]?.delegate?.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
        completionHandler(request)
#else
        handlers[task]?.delegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
        completionHandler(request)
#endif
    }

#if !os(Linux)
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        handlers[task]?.delegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
        userTaskDelegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
    }

#if swift(>=5.7)
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            handlers[task]?.delegate?.urlSession?(session, didCreateTask: task)
            userTaskDelegate?.urlSession?(session, didCreateTask: task)
        } else {
            // Doesn't exist on earlier versions
        }
    }
#endif
#endif

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
#if os(Linux)
        handlers[task]?.delegate?.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
        completionHandler(.performDefaultHandling, nil)
#else
        handlers[task]?.delegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
        completionHandler(.performDefaultHandling, nil)
#endif
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
#if os(Linux)
        handlers[task]?.delegate?.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
        completionHandler(.continueLoading, nil)
#else
        handlers[task]?.delegate?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
        userTaskDelegate?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
        completionHandler(.continueLoading, nil)
#endif
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
#if os(Linux)
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
        userDataDelegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
        completionHandler(.allow)
#else
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
        userDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
        completionHandler(.allow)
#endif
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let handler = handlers[dataTask] as? DataTaskHandler else { return }
#if os(Linux)
        handler.dataDelegate?.urlSession(session, dataTask: dataTask, didReceive: data)
        userDataDelegate?.urlSession(session, dataTask: dataTask, didReceive: data)
#else
        handler.dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
        userDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
#endif
        if handler.data == nil {
            handler.data = Data()
        }
        handler.data!.append(data)
    }

#if !os(Linux)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        userDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        userDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
    }
#endif

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
#if os(Linux)
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ??
        userDataDelegate?.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        completionHandler(proposedResponse)
#else
        (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ??
        userDataDelegate?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ??
        completionHandler(proposedResponse)
#endif
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let handler = (handlers[downloadTask] as? DownloadTaskHandler)
        try? FileManager.default.createDirectory(at: downloadDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        let newLocation = downloadDirectoryURL.appendingPathExtension(location.lastPathComponent)
        try? FileManager.default.moveItem(at: location, to: newLocation)
        handler?.location = newLocation
        handler?.downloadDelegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: newLocation)
        userDownloadDelegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: newLocation)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
#if os(Linux)
        (handlers[downloadTask] as? DownloadTaskHandler)?.downloadDelegate?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        userDownloadDelegate?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
#else
        (handlers[downloadTask] as? DownloadTaskHandler)?.downloadDelegate?.urlSession?(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        userDownloadDelegate?.urlSession?(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
#endif
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
#if os(Linux)
        (handlers[downloadTask] as? DownloadTaskHandler)?.downloadDelegate?.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        userDownloadDelegate?.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
#else
        (handlers[downloadTask] as? DownloadTaskHandler)?.downloadDelegate?.urlSession?(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        userDownloadDelegate?.urlSession?(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
#endif
    }
}

private class TaskHandler {
    let delegate: URLSessionTaskDelegate?
    var metrics: URLSessionTaskMetrics?

    init(delegate: URLSessionTaskDelegate?) {
        self.delegate = delegate
    }
}

private final class DataTaskHandler: TaskHandler {
    typealias Completion = (Result<(Data, URLResponse, URLSessionTaskMetrics?), Error>) -> Void

    let dataDelegate: URLSessionDataDelegate?
    var completion: Completion?
    var data: Data?

    override init(delegate: URLSessionTaskDelegate?) {
        self.dataDelegate = delegate as? URLSessionDataDelegate
        super.init(delegate: delegate)
    }
}

private final class DownloadTaskHandler: TaskHandler {
    typealias Completion = (Result<(URL, URLResponse, URLSessionTaskMetrics?), Error>) -> Void

    let downloadDelegate: URLSessionDownloadDelegate?
    var completion: Completion?
    var location: URL?

    init(delegate: URLSessionDownloadDelegate?) {
        self.downloadDelegate = delegate
        super.init(delegate: delegate)
    }
}

extension OperationQueue {
    static func serial() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
}

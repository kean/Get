// The MIT License (MIT)
//
// Copyright (c) 2015-2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public protocol APIClientProtocol {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
    
#warning("TODO: process in background and disptch on main queue (maybe decode on networking OperationQueue?")

#warning("TODO: seet Content-Type when posting a JSON")

#warning("TOOD: implement authentication")

#warning("TODO: is it defined somewhere in URLSession?")
public enum HTTPMethod {
    case get
    case post
    case delete
}

extension URLRequest {
    #warning("TODO: use throws")
    private func make(_ url: URL, method: HTTPMethod, parameters: [String: String]?, headers: [String: String]?) -> URLRequest? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            fatalError() // TODO: throw
        }
        if let parameters = parameters {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        fatalError() // TODO: craete URLRequest
    }
}

public final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let delegate: URLSessionTaskDelegate
    
    public init() {
        self.session = URLSession(configuration: .default)
        self.delegate = TaskDelegate()
    }
    
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        #warning("TODO: implement using URLSession / something like Nuke / new URLSesion async/await APIs with delegate")
        // TODO: Does URLSession async/await cancel in-flight requests? If no, we'll have to implement something else ourselves
        
        return try await session.data(for: request, delegate: delegate)
    }
    
    private final class TaskDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            print("hey")
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
            print("hey")
        }
    }
}

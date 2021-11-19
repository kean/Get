// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

#warning("TODO: do this on the NetworkClient level? I think we should just remove the NetworkClient because it's confusing")
protocol APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest)
    // TODO: not should if we need this
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error
}

public struct Request<Response> {
    var method: String
    var path: String
    var query: [String: String]?
    var body: AnyEncodable?
}

extension Request where Response == Void {
    static func delete<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "DELETE", path: path, body: AnyEncodable(body))
    }
    
    static func post<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "POST", path: path, body: AnyEncodable(body))
    }
}

extension Request where Response: Decodable {
    static func get(_ path: String, query: [String: String]? = nil) -> Request {
        Request(method: "GET", path: path, query: query)
    }
    
    static func post<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "POST", path: path, body: AnyEncodable(body))
    }
}

/// A set of high-level APIs for defining REST JSON clients.
actor APIClient {
    private let session: URLSession
    private let host: String
    private let serializer = Serializer()
    private let delegate: APIClientDelegate
    private let taskDelegate = TaskDelegate()

    /// - parameter host: The default host to be used for relative paths.
    init(configuration: URLSessionConfiguration = .default, host: String, delegate: APIClientDelegate) {
        self.session = URLSession(configuration: configuration)
        self.host = host
        self.delegate = delegate
    }
    
    // MARK: Networking

    func send<Response>(_ request: Request<Response>) async throws -> Response where Response: Decodable {
        try await send(request) { try await self.serializer.decode($0) }
    }
    
    func send(_ request: Request<Void>) async throws -> Void {
        try await send(request) { _ in () }
    }
    
    private func send<Response>(
        _ request: Request<Response>,
        _ decode: @escaping (Data) async throws -> Response
    ) async throws -> Response {
        let url = try makeURL(path: request.path, query: request.query)
        let request = try await makeRequest(url: url, method: request.method, body: request.body)
        let (data, response) = try await send(request)
        try validate(response: response, data: data)
        return try await decode(data)
    }
        
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await session.data(for: request, delegate: taskDelegate)
    }
    
    // MARK: Request Factory
    
    private func makeURL(path: String, query: [String: String]?) throws -> URL {
        guard let url = URL(string: path),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if path.starts(with: "/") {
            components.scheme = "https"
            components.host = host
        }
        if let query = query {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
    
    private func makeRequest(url: URL, method: String, body: AnyEncodable?) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try await serializer.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        delegate.client(self, willSendRequest: &request)
        return request
    }
    
    // MARK: Serialization
    
    private func encode<T: Encodable>(_ entity: T) async throws -> Data {
        try await serializer.encode(entity)
    }
    
    private func decode<T: Decodable>(_ data: Data) async throws -> T {
        try await serializer.decode(data)
    }
    
    private func empty(_ data: Data) async throws -> Void {
        ()
    }
    
    // MARK: Validation
    
    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if !(200..<300).contains(httpResponse.statusCode) {
            throw delegate.client(self, didReceiveInvalidResponse: httpResponse, data: data)
        }
    }
    
    // MARK: Misc

    #warning("TODO: remove")
    enum Error: Swift.Error {
        case unacceptableStatusCode(Int)
    }
}

private actor Serializer {
    func encode<T: Encodable>(_ entity: T) async throws -> Data {
        try JSONEncoder().encode(entity)
    }
    
    func decode<T: Decodable>(_ data: Data) async throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}

private final class TaskDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // TODO: Save metrics for Pulse + integrate Pulse yo
    }
}

struct AnyEncodable: Encodable {
    private let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

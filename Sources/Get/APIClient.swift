// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws
    func shouldClientRetry(_ client: APIClient, withError error: Error) async throws -> Bool
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error
}

public actor APIClient {
    private let conf: Configuration
    private let session: URLSession
    private let serializer: Serializer
    private let delegate: APIClientDelegate
    private let loader = DataLoader()

    public struct Configuration {
        public var host: String
        public var port: Int?
        /// If `true`, uses `http` instead of `https`.
        public var isInsecure = false
        public var sessionConfiguration: URLSessionConfiguration = .default
        /// By default, uses decoder with `.iso8601` date decoding strategy.
        public var decoder: JSONDecoder?
        /// By default, uses encoder with `.iso8601` date encoding strategy.
        public var encoder: JSONEncoder?
        /// The (optional) client delegate.
        public var delegate: APIClientDelegate?
        /// The (optional) URLSession delegate that allows you to monitor the underlying URLSession.
        public var sessionDelegate: URLSessionDelegate?

        public init(host: String, sessionConfiguration: URLSessionConfiguration = .default, delegate: APIClientDelegate? = nil) {
            self.host = host
            self.sessionConfiguration = sessionConfiguration
            self.delegate = delegate
        }
    }

    /// Initializes the client with the given parameters.
    ///
    /// - parameter host: A host to be used for requests with relative paths.
    /// - parameter configure: Updates the client configuration.
    public convenience init(host: String, _ configure: (inout APIClient.Configuration) -> Void = { _ in }) {
        var configuration = Configuration(host: host)
        configure(&configuration)
        self.init(configuration: configuration)
    }

    /// Initializes the client with the given configuration.
    public init(configuration: Configuration) {
        self.conf = configuration
        let queue = OperationQueue(maxConcurrentOperationCount: 1)
        let delegate = URLSessionProxyDelegate.make(loader: loader, delegate: configuration.sessionDelegate)
        self.session = URLSession(configuration: configuration.sessionConfiguration, delegate: delegate, delegateQueue: queue)
        self.delegate = configuration.delegate ?? DefaultAPIClientDelegate()
        self.serializer = Serializer(decoder: configuration.decoder, encoder: configuration.encoder)
    }

    /// Sends the given request and returns a response with a decoded response value.
    public func send<T: Decodable>(_ request: Request<T?>) async throws -> Response<T?> {
        try await send(request) { data in
            if data.isEmpty {
                return nil
            } else {
                return try await self.decode(data)
            }
        }
    }

    /// Sends the given request and returns a response with a decoded response value.
    public func send<T: Decodable>(_ request: Request<T>) async throws -> Response<T> {
        try await send(request, decode)
    }

    private func decode<T: Decodable>(_ data: Data) async throws -> T {
        if T.self == Data.self {
            return data as! T
        } else if T.self == String.self {
            guard let string = String(data: data, encoding: .utf8) else { throw URLError(.badServerResponse) }
            return string as! T
        } else {
            return try await self.serializer.decode(data)
        }
    }

    /// Sends the given request.
    @discardableResult
    public func send(_ request: Request<Void>) async throws -> Response<Void> {
        try await send(request) { _ in () }
    }

    private func send<T>(_ request: Request<T>, _ decode: @escaping (Data) async throws -> T) async throws -> Response<T> {
        let response = try await data(for: request)
        let value = try await decode(response.value)
        return response.map { _ in value } // Keep metadata
    }

    /// Returns response data for the given request.
    public func data<T>(for request: Request<T>) async throws -> Response<Data> {
        let request = try await makeRequest(for: request)
        return try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> Response<Data> {
        do {
            return try await actuallySend(request)
        } catch {
            guard try await delegate.shouldClientRetry(self, withError: error) else { throw error }
            return try await actuallySend(request)
        }
    }

    private func actuallySend(_ request: URLRequest) async throws -> Response<Data> {
        var request = request
        try await delegate.client(self, willSendRequest: &request)
        let (data, response, metrics) = try await loader.data(for: request, session: session)
        try validate(response: response, data: data)
        return Response(value: data, data: data, request: request, response: response, metrics: metrics)
    }

    private func makeRequest<T>(for request: Request<T>) async throws -> URLRequest {
        let url = try makeURL(path: request.path, query: request.query)
        return try await makeRequest(url: url, method: request.method, body: request.body, headers: request.headers)
    }

    private func makeURL(path: String, query: [(String, String?)]?) throws -> URL {
        guard let url = URL(string: path),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if path.starts(with: "/") {
            components.scheme = conf.isInsecure ? "http" : "https"
            components.host = conf.host
            if let port = conf.port {
                components.port = port
            }
        }
        if let query = query {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func makeRequest(url: URL, method: String, body: AnyEncodable?, headers: [String: String]?) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method
        if let body = body {
            request.httpBody = try await serializer.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if !(200..<300).contains(httpResponse.statusCode) {
            throw delegate.client(self, didReceiveInvalidResponse: httpResponse, data: data)
        }
    }
}

public enum APIError: Error, LocalizedError {
    case unacceptableStatusCode(Int)

    public var errorDescription: String? {
        switch self {
        case .unacceptableStatusCode(let statusCode):
            return "Response status code was unacceptable: \(statusCode)."
        }
    }
}

public extension APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {}
    func shouldClientRetry(_ client: APIClient, withError error: Error) async throws -> Bool { false }
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        APIError.unacceptableStatusCode(response.statusCode)
    }
}

private struct DefaultAPIClientDelegate: APIClientDelegate {}

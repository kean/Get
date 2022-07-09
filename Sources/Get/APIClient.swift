// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs network requests constructed using ``Request``.
public actor APIClient {
    private let conf: Configuration
    private let session: URLSession
    private let serializer: Serializer
    private let delegate: APIClientDelegate
    private let loader = DataLoader()

    /// The configuration for ``APIClient``.
    public struct Configuration {
        /// A base URL. For example, `"https://api.github.com"`.
        public var baseURL: URL?
        /// By default, `URLSessionConfiguration.default`.
        public var sessionConfiguration: URLSessionConfiguration = .default
        /// By default, uses decoder with `.iso8601` date decoding strategy.
        public var decoder: JSONDecoder?
        /// By default, uses encoder with `.iso8601` date encoding strategy.
        public var encoder: JSONEncoder?
        /// The (optional) client delegate.
        public var delegate: APIClientDelegate?
#if !os(Linux)
        /// The (optional) URLSession delegate that allows you to monitor the underlying URLSession.
        public var sessionDelegate: URLSessionDelegate?
#endif
        /// Overrides the default delegate queue.
        public var delegateQueue: OperationQueue?

        /// Initializes the configuration.
        public init(baseURL: URL?, sessionConfiguration: URLSessionConfiguration = .default, delegate: APIClientDelegate? = nil) {
            self.baseURL = baseURL
            self.sessionConfiguration = sessionConfiguration
            self.delegate = delegate
        }
    }

    /// Initializes the client with the given parameters.
    ///
    /// - parameter baseURL: A base URL. For example, `"https://api.github.com"`.
    /// - parameter configure: Updates the client configuration.
    public convenience init(baseURL: URL?, _ configure: (inout APIClient.Configuration) -> Void = { _ in }) {
        var configuration = Configuration(baseURL: baseURL)
        configure(&configuration)
        self.init(configuration: configuration)
    }

    /// Initializes the client with the given configuration.
    public init(configuration: Configuration) {
        self.conf = configuration
#if !os(Linux)
        let delegate = URLSessionProxyDelegate.make(loader: loader, delegate: configuration.sessionDelegate)
#else
        let delegate = loader
#endif
        let delegateQueue = configuration.delegateQueue ?? .serial()
        self.session = URLSession(configuration: configuration.sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)
        self.delegate = configuration.delegate ?? DefaultAPIClientDelegate()
        self.serializer = Serializer(decoder: configuration.decoder, encoder: configuration.encoder)
    }

    /// Sends the given request and returns a response with a decoded response value.
    public func send<T: Decodable>(_ request: Request<T?>, delegate: URLSessionDataDelegate? = nil) async throws -> Response<T?> {
        try await send(request, delegate: delegate) { data in
            if data.isEmpty {
                return nil
            } else {
                return try await self.decode(data)
            }
        }
    }

    /// Sends the given request and returns a response with a decoded response value.
    public func send<T: Decodable>(_ request: Request<T>, delegate: URLSessionDataDelegate? = nil) async throws -> Response<T> {
        try await send(request, delegate: delegate, decode)
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
    public func send(_ request: Request<Void>, delegate: URLSessionDataDelegate? = nil) async throws -> Response<Void> {
        try await send(request, delegate: delegate) { _ in () }
    }

    private func send<T>(_ request: Request<T>, delegate: URLSessionDataDelegate?, _ decode: @escaping (Data) async throws -> T) async throws -> Response<T> {
        let request = try await makeURLRequest(for: request)
        let response = try await send(request, delegate: delegate)
        let value = try await decode(response.value)
        return response.map { _ in value } // Keep metadata
    }

    private func send(_ request: URLRequest, delegate: URLSessionDataDelegate?) async throws -> Response<Data> {
        do {
            return try await actuallySend(request, delegate: delegate)
        } catch {
            guard try await self.delegate.shouldClientRetry(self, for: request, withError: error) else { throw error }
            return try await actuallySend(request, delegate: delegate)
        }
    }

    private func actuallySend(_ request: URLRequest, delegate: URLSessionDataDelegate?) async throws -> Response<Data> {
        var request = request
        try await self.delegate.client(self, willSendRequest: &request)
        let (data, response, metrics) = try await loader.data(for: request, session: session, delegate: delegate)
        try validate(response: response, data: data)
        return Response(value: data, data: data, request: request, response: response, metrics: metrics)
    }

    private func makeURLRequest<T>(for request: Request<T>) async throws -> URLRequest {
        let url = try makeURL(path: request.path, query: request.query)
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpMethod = request.method
        if let body = request.body {
            urlRequest.httpBody = try await serializer.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        return urlRequest
    }

    private func makeURL(path: String, query: [(String, String?)]?) throws -> URL {
        if let url = try delegate.client(self, makeURLForPath: path, query: query) {
            return url
        }
        func makeAbsoluteURL() -> URL? {
            path.starts(with: "/") ? conf.baseURL?.appendingPathComponent(path) : URL(string: path)
        }
        guard let url = makeAbsoluteURL(),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if let query = query, !query.isEmpty {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
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

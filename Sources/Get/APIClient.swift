// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs network requests constructed using ``Request``.
public actor APIClient {
    /// The configuration with which the client was initialized with.
    public let configuration: Configuration
    /// The underlying `URLSession` instance.
    public let session: URLSession

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let delegate: APIClientDelegate
    private let dataLoader = DataLoader()

    /// The configuration for ``APIClient``.
    public struct Configuration {
        /// A base URL. For example, `"https://api.github.com"`.
        public var baseURL: URL?
        /// The (optional) client delegate.
        public var delegate: APIClientDelegate?
        /// By default, `URLSessionConfiguration.default`.
        public var sessionConfiguration: URLSessionConfiguration = .default
        /// The (optional) URLSession delegate that allows you to monitor the underlying URLSession.
        public var sessionDelegate: URLSessionDelegate?
        /// Overrides the default delegate queue.
        public var sessionDelegateQueue: OperationQueue?
        /// By default, uses decoder with `.iso8601` date decoding strategy.
        public var decoder: JSONDecoder
        /// By default, uses encoder with `.iso8601` date encoding strategy.
        public var encoder: JSONEncoder

        /// Initializes the configuration.
        public init(
            baseURL: URL?,
            sessionConfiguration: URLSessionConfiguration = .default,
            delegate: APIClientDelegate? = nil
        ) {
            self.baseURL = baseURL
            self.sessionConfiguration = sessionConfiguration
            self.delegate = delegate
            self.decoder = JSONDecoder()
            self.decoder.dateDecodingStrategy = .iso8601
            self.encoder = JSONEncoder()
            self.encoder.dateEncodingStrategy = .iso8601
        }
    }

    // MARK: Initializers

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
        self.configuration = configuration
        let delegateQueue = configuration.sessionDelegateQueue ?? .serial()
        self.session = URLSession(configuration: configuration.sessionConfiguration, delegate: dataLoader, delegateQueue: delegateQueue)
        self.dataLoader.userSessionDelegate = configuration.sessionDelegate
        self.delegate = configuration.delegate ?? DefaultAPIClientDelegate()
        self.decoder = configuration.decoder
        self.encoder = configuration.encoder
    }

    // MARK: Sending Requests

    /// Sends the given request.
    ///
    /// - parameters:
    ///   - request: The request to perform.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// - returns: A response with a decoded body.
    public func send<T: Decodable>(
        _ request: Request<T>,
        delegate: URLSessionDataDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<T> {
        try await _send(request, delegate: delegate, configure: configure, decode)
    }

    /// Sends the given request.
    ///
    /// - parameters:
    ///   - request: The request to perform.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// - returns: A response with a decoded body or `nil` if the data was empty.
    public func send<T: Decodable>(
        _ request: Request<T?>,
        delegate: URLSessionDataDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<T?> {
        try await _send(request, delegate: delegate, configure: configure) { data in
            if data.isEmpty {
                return nil
            } else {
                return try await self.decode(data)
            }
        }
    }

    /// Sends the given request.
    ///
    /// - parameters:
    ///   - request: The request to perform.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// - returns: A response with an empty value.
    @discardableResult
    public func send(
        _ request: Request<Void>,
        delegate: URLSessionDataDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<Void> {
        try await _send(request, delegate: delegate, configure: configure) { _ in () }
    }

    private func _send<T, U>(
        _ request: Request<T>,
        delegate: URLSessionDataDelegate?,
        configure: ((inout URLRequest) -> Void)?,
        _ decode: @escaping (Data) async throws -> U
    ) async throws -> Response<U> {
        let request = try await makeURLRequest(for: request, configure)
        return try await performWithRetries(request: request) { request in
            let (data, response, metrics) = try await dataLoader.data(for: request, session: session, delegate: delegate)
            try validate(response: response, data: data)
            let value = try await decode(data)
            return Response(value: value, data: data, request: request, response: response, metrics: metrics)
        }
    }

    private func decode<T: Decodable>(_ data: Data) async throws -> T {
        if T.self == Data.self {
            return data as! T
        } else if T.self == String.self {
            guard let string = String(data: data, encoding: .utf8) else { throw URLError(.badServerResponse) }
            return string as! T
        } else {
            return try await Task.detached { [decoder] in
                try decoder.decode(T.self, from: data)
            }.value
        }
    }

    // MARK: Fetch Data

    /// Fetches the data for the given request.
    ///
    /// - parameters:
    ///   - request: The request to perform.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// - returns: A response with a raw response data.
    public func data<T>(
        for request: Request<T>,
        delegate: URLSessionDataDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<Data> {
        try await _send(request, delegate: delegate, configure: configure) { $0 }
    }

#if !os(Linux)

    // MARK: Downloads

    /// Downloads the data for the given request.
    ///
    /// - parameters:
    ///   - request: The request to perform.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// - important: Make sure to move the downloaded file to a location in your app after the completion.
    ///
    /// - returns: A response with a location of the downloaded file.
    public func download<T>(
        for request: Request<T>,
        delegate: URLSessionDownloadDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<URL> {
        let request = try await makeURLRequest(for: request, configure)
        return try await _download(request, attempts: 1, delegate: delegate)
    }

    private func _download(
        _ request: URLRequest,
        attempts: Int,
        delegate: URLSessionDownloadDelegate?
    ) async throws -> Response<URL> {
        try await performWithRetries(request: request) { request in
            let (location, response, metrics) = try await dataLoader.download(for: request, session: session, delegate: delegate)
            try validate(response: response, data: Data())
            return Response(value: location, data: Data(), request: request, response: response, metrics: metrics)
        }
    }

#endif

    // MARK: Upload

    /// Convenience method to upload data from the file.
    ///
    /// - parameters:
    ///   - request: The URLRequest for which to upload data.
    ///   - fileURL: File to upload.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// Returns decoded response.
    public func upload<T: Decodable>(
        for request: Request<T>,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<T> {
        let request = try await makeURLRequest(for: request, configure)
        return try await _upload(request, fromFile: fileURL, delegate: delegate, decode)
    }

    /// Convenience method to upload data from the file.
    ///
    /// - parameters:
    ///   - request: The URLRequest for which to upload data.
    ///   - fileURL: File to upload.
    ///   - delegate: Task-specific delegate.
    ///   - configure: Modifies the underlying `URLRequest` before sending it.
    ///
    /// Returns decoded response.
    public func upload(
        for request: Request<Void>,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate? = nil,
        configure: ((inout URLRequest) -> Void)? = nil
    ) async throws -> Response<Void> {
        let request = try await makeURLRequest(for: request, configure)
        return try await _upload(request, fromFile: fileURL, delegate: delegate, { _ in () })
    }

    private func _upload<T>(
        _ request: URLRequest,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate? = nil,
        _ decode: @escaping (Data) async throws -> T
    ) async throws -> Response<T> {
        try await performWithRetries(request: request) { request in
            let (data, response, metrics) = try await dataLoader.upload(for: request, fromFile: fileURL, session: session, delegate: delegate)
            try validate(response: response, data: data)
            let value = try await decode(data)
            return Response(value: value, data: data, request: request, response: response, metrics: metrics)
        }
    }

    // MARK: Helpers

    private func performWithRetries<T>(
        request: URLRequest,
        attempts: Int = 1,
        send: (URLRequest) async throws -> T
    ) async throws -> T {
        do {
            var request = request
            try await self.delegate.client(self, willSendRequest: &request)
            return try await send(request)
        } catch {
            guard try await self.delegate.client(self, shouldRetryRequest: request, attempts: attempts, error: error) else {
                throw error
            }
            return try await performWithRetries(request: request, attempts: attempts + 1, send: send)
        }
    }

    private func makeURLRequest<T>(
        for request: Request<T>,
        _ configure: ((inout URLRequest) -> Void)?
    ) async throws -> URLRequest {
        let url = try makeURL(path: request.path, query: request.query)
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpMethod = request.method
        if let body = request.body {
            urlRequest.httpBody = try await Task.detached { [encoder] in
                try encoder.encode(body)
            }.value
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        configure?(&urlRequest)
        return urlRequest
    }

    private func makeURL(path: String, query: [(String, String?)]?) throws -> URL {
        if let url = try delegate.client(self, makeURLForPath: path, query: query) {
            return url
        }
        func makeAbsoluteURL() -> URL? {
            let isRelative = path.starts(with: "/") || URL(string: path)?.scheme == nil
            return isRelative ? configuration.baseURL?.appendingPathComponent(path) : URL(string: path)
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

/// Represents an error encountered by the client.
public enum APIError: Error, LocalizedError {
    case unacceptableStatusCode(Int)

    /// Returns the debug description.
    public var errorDescription: String? {
        switch self {
        case .unacceptableStatusCode(let statusCode):
            return "Response status code was unacceptable: \(statusCode)."
        }
    }
}

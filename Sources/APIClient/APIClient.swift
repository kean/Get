// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public protocol APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest)
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error
}

public actor APIClient {
    private let conf: Configuration
    private let session: URLSession
    private let serializer: Serializer
    private let delegate: APIClientDelegate
    
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
        public var delegate: APIClientDelegate?
    }

    /// Initializes the client with the given parameters.
    ///
    /// - parameter host: A host to be used for requests with relative paths.
    /// - parameter configuration: By default, `URLSessionConfiguration.default`.
    /// - parameter delegate: A delegate to customize various aspects of the client.
    public convenience init(host: String, configuration: URLSessionConfiguration = .default, delegate: APIClientDelegate? = nil) {
        self.init(configuration: Configuration(host: host, sessionConfiguration: configuration, delegate: delegate))
    }
    
    /// Initializes the client with the given configuration.
    public init(configuration: Configuration) {
        self.conf = configuration
        self.session = URLSession(configuration: configuration.sessionConfiguration)
        self.delegate = configuration.delegate ?? DefaultAPIClientDelegate()
        self.serializer = Serializer(decoder: configuration.decoder, encoder: configuration.encoder)
    }
    
    /// Returns a decoded response value for the given request.
    public func value<T: Decodable>(for request: Request<T>) async throws -> T {
        try await send(request).value
    }

    /// Sends the given request and returns a response with a decoded response value.
    public func send<T: Decodable>(_ request: Request<T>) async throws -> Response<T> {
        try await send(request, serializer.decode)
    }

    /// Sends the given request.
    @discardableResult
    public func send(_ request: Request<Void>) async throws -> Response<Void> {
        try await send(request) { _ in () }
    }
    
    private func send<T>(_ request: Request<T>, _ decode: @escaping (Data) async throws -> T) async throws -> Response<T> {
        let response = try await data(for: request)
        let value = try await decode(response.value)
        return response.map { _ in value }
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
            guard await delegate.shouldClientRetry(self, withError: error) else { throw error }
            return try await actuallySend(request)
        }
    }

    private func actuallySend(_ request: URLRequest) async throws -> Response<Data> {
        var request = request
        delegate.client(self, willSendRequest: &request)
        let (data, response) = try await session.data(for: request, delegate: nil)
        try validate(response: response, data: data)
        let httpResponse = (response as? HTTPURLResponse) ?? HTTPURLResponse() // The right side should never be executed
        return Response(value: data, data: data, request: request, response: httpResponse, statusCode: httpResponse.statusCode)
    }

    private func makeRequest<T>(for request: Request<T>) async throws -> URLRequest {
        let url = try makeURL(path: request.path, query: request.query)
        return try await makeRequest(url: url, method: request.method, body: request.body)
    }

    private func makeURL(path: String, query: [String: String?]?) throws -> URL {
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

    private func makeRequest(url: URL, method: String, body: AnyEncodable?) async throws -> URLRequest {
        var request = URLRequest(url: url)
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
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) {}
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool { false }
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        APIError.unacceptableStatusCode(response.statusCode)
    }
}

private struct DefaultAPIClientDelegate: APIClientDelegate {}

private actor Serializer {
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

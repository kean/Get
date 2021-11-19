// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import PulseCore

// TOOD: Add default delegate and default methods
// TODO: URLError(.badServerResponse) for invalid response (404)?
public protocol APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest)
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error
}

public actor APIClient {
    private let session: URLSession
    private let host: String
    private let serializer = Serializer()
    private let delegate: APIClientDelegate
    
    public init(host: String, configuration: URLSessionConfiguration = .default, delegate: APIClientDelegate) {
        self.host = host
        self.session = URLSession(configuration: configuration)
        self.delegate = delegate
    }

    public func send<Response>(_ request: Request<Response>) async throws -> Response where Response: Decodable {
        try await send(request) { try await self.serializer.decode($0) }
    }
    
    public func send(_ request: Request<Void>) async throws -> Void {
        try await send(request) { _ in () }
    }
    
    private func send<T>(_ request: Request<T>, _ decode: @escaping (Data) async throws -> T) async throws -> T {
        let url = try makeURL(path: request.path, query: request.query)
        let request = try await makeRequest(url: url, method: request.method, body: request.body)
        let (data, response) = try await send(request)
        try validate(response: response, data: data)
        return try await decode(data)
    }
    
     public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request, delegate: nil)
     }
        
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
        // TODO: Move outside of `make`
        delegate.client(self, willSendRequest: &request)
        return request
    }
        
    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if !(200..<300).contains(httpResponse.statusCode) {
            throw delegate.client(self, didReceiveInvalidResponse: httpResponse, data: data)
        }
    }
}

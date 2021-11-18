// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

protocol PathProtocol {
    var rawValue: String { get }
}

// This as a protocol?
struct API {
    let client: APIClientProtocol
    let host: String

    init(client: APIClientProtocol, host: String) {
        self.client = client
        self.host = host
    }
}

// TODO: Add a way to adopt requests?
extension API {
    func get<T: Decodable>(_ path: String, query: Query? = nil) async throws -> T {
        try await send(.get, path, query: query, response: decode)
    }
    
    func post<T: Decodable, U: Encodable>(_ path: String, body: U) async throws -> T {
        try await send(.post, path, body: .encoded(body), response: decode)
    }
    
    func post<U: Encodable>(_ path: String, body: U) async throws {
        try await send(.post, path, body: .encoded(body), response: { _ in () })
    }
    
    func delete<U: Encodable>(_ path: String, body: U) async throws {
        try await send(.delete, path , body: .encoded(body), response: { _ in () })
    }

    private func send<Response>(_ method: HTTPMethod, _ path: String, query: [String: String]? = nil, body: RequestBody? = nil, response: @escaping (Data) throws -> Response, headers: Headers? = nil) async throws -> Response {
        guard let inputURL = URL(string: path),
              var components = URLComponents(url: inputURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if path.starts(with: "/") { // Relative path
            components.scheme = "https"
            components.host = host
        }
        if let query = query {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url)
        
        // TODO: pass body
        
        let (data, response) = try client.send(request)
        
        // TODO: parse response (see WWDC video for that)
        
        fatalError()
    }
}

typealias Query = [String: String]
typealias Headers = [String: String]

enum RequestBody {
    case data(() throws -> (Data, String))
    case stream(InputStream)
    
    static func encoded<T: Encodable>(_ entity: T) -> RequestBody {
        .data({ (try JSONEncoder().encode(entity), "application/json") })
    }
}

private func decode<T: Decodable>(_ data: Data) throws -> T {
    try JSONDecoder().decode(T.self, from: data)
}

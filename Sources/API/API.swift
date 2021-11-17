// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

protocol PathProtocol {
    var rawValue: String { get }
}

// This as a protocol?
struct API<Path: PathProtocol> {
    let client: APIClientProtocol
    let host: String

    init(client: APIClientProtocol, host: String) {
        self.client = client
        self.host = host
    }
}

extension API {
    func get<T: Decodable>(_ path: Path, parameters: HTTPParameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        try await send(path, method: .get, parameters: parameters, response: decode, headers: headers)
    }
    
    func post<T: Decodable, U: Encodable>(_ path: Path, body: U, headers: HTTPHeaders? = nil) async throws -> T {
        try await send(path, method: .post, body: .encoded(body), response: decode, headers: headers)
    }
    
    func post<U: Encodable>(_ path: Path, body: U, headers: HTTPHeaders? = nil) async throws {
        try await send(path, method: .post, body: .encoded(body), response: { _ in () }, headers: headers)
    }
    
    func delete<U: Encodable>(_ path: Path, body: U, headers: HTTPHeaders? = nil) async throws {
        try await send(path, method: .delete, body: .encoded(body), response: { _ in () }, headers: headers)
    }

    private func send<Response>(_ path: Path, method: HTTPMethod, parameters: HTTPParameters? = nil, body: RequestBody? = nil, response: @escaping (Data) throws -> Response, headers: HTTPHeaders?) async throws -> Response {
        fatalError()
    }
    
    private func makeURL(for path: Path) throws -> URL {
        // TODO: Add a way to pass full URL, overriding default path
        try URL(host: host, path: path.rawValue)
    }
}

struct HTTPParameters: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, String)...) {
        
    }
}

/// TODO: https://developer.apple.com/documentation/foundation/nsurlrequest#1776617
struct HTTPHeaders: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, String)...) {
        
    }
    
    func setValue(_ value: String, forKey key: String) {
        fatalError()
    }
    
    /// TODO: https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
    func addValue(_ value: String, forKey key: String) {
        fatalError()
    }
}

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

private func decode(_ data: Data) -> Void {
    ()
}

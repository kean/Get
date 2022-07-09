// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An HTTP network request.
public struct Request<Response>: @unchecked Sendable {
    /// HTTP method, e.g. "GET".
    public var method: String
    /// Resource path.
    public var path: String
    /// Request query items.
    public var query: [(String, String?)]?
    /// Request headers to be added to the request.
    public var headers: [String: String]?
    /// ID provided by the user. Not used by the API client.
    public var id: String?

    let body: AnyEncodable?

    /// Initialiazes the request with the given parameters.
    public init(method: String, path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = nil
    }

    /// Initialiazes the request with the given parameters and the request body.
    public init<U: Encodable>(method: String, path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body.map(AnyEncodable.init)
    }

    public static func get(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "GET", path: path, query: query, headers: headers)
    }

    public static func post(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", path: path, query: query, headers: headers)
    }

    public static func post<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", path: path, query: query, body: body, headers: headers)
    }

    public static func put(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", path: path, query: query, headers: headers)
    }

    public static func put<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", path: path, query: query, body: body, headers: headers)
    }

    public static func patch(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", path: path, query: query, headers: headers)
    }

    public static func patch<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", path: path, query: query, body: body, headers: headers)
    }

    public static func delete(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", path: path, query: query, headers: headers)
    }

    public static func delete<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", path: path, query: query, body: body, headers: headers)
    }

    public static func options(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "OPTIONS", path: path, query: query, headers: headers)
    }

    public static func head(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "HEAD", path: path, query: query, headers: headers)
    }

    public static func trace(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "TRACE", path: path, query: query, headers: headers)
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

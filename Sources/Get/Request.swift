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
    public var method: HTTPMethod
    /// Resource URL. Can be either absolute or relative.
    public var url: String
    /// Request query items.
    public var query: [(String, String?)]?
    /// Request body.
    public var body: Encodable?
    /// Request headers to be added to the request.
    public var headers: [String: String]?
    /// ID provided by the user. Not used by the API client.
    public var id: String?

    /// Initialiazes the request with the given parameters and the request body.
    public init(
        url: String,
        method: HTTPMethod = .get,
        query: [(String, String?)]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        id: String? = nil,
        _ configure: (inout Request) -> Void = { _ in }
    ) {
        self.method = method
        self.url = url
        self.query = query
        self.headers = headers
        self.body = body
        self.id = id
        configure(&self)
    }

    /// Changes the respones type keeping the rest of the request parameters.
    public func withResponse<T>(_ type: T.Type) -> Request<T> {
        Request<T>(url: url, method: method, query: query, body: body, headers: headers, id: id)
    }
}

extension Request where Response == Void {
    public init(
        url: String,
        method: HTTPMethod = .get,
        query: [(String, String?)]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        id: String? = nil,
        _ configure: (inout Request) -> Void = { _ in }
    ) {
        self.method = method
        self.url = url
        self.query = query
        self.headers = headers
        self.body = body
        self.id = id
        configure(&self)
    }
}

public struct HTTPMethod: ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let get: HTTPMethod = "GET"
    public static let post: HTTPMethod = "POST"
    public static let patch: HTTPMethod = "PATCH"
    public static let put: HTTPMethod = "PUT"
    public static let delete: HTTPMethod = "DELETE"
    public static let options: HTTPMethod = "OPTIONS"
    public static let head: HTTPMethod = "HEAD"
    public static let trace: HTTPMethod = "TRACE"
}

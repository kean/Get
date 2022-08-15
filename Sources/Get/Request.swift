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

    /// Initialiazes the request with the given parameters.
    public init(
        url: String,
        method: HTTPMethod = .get,
        query: [(String, String?)]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        id: String? = nil
    ) {
        self.method = method
        self.url = url
        self.query = query
        self.headers = headers
        self.body = body
        self.id = id
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
        id: String? = nil
    ) {
        self.method = method
        self.url = url
        self.query = query
        self.headers = headers
        self.body = body
        self.id = id
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


// Deprecated in Get 1.0
@available(*, deprecated, message: "Please use Request initializer instead")
extension Request {
    public static func get(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .get, query: query, headers: headers)
    }

    public static func post(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .post, query: query, body: body, headers: headers)
    }

    public static func put(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .put, query: query, body: body, headers: headers)
    }

    public static func patch(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .patch, query: query, body: body, headers: headers)
    }

    public static func delete(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .delete, query: query, body: body, headers: headers)
    }

    public static func options(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .options, query: query, headers: headers)
    }

    public static func head(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .head, query: query, headers: headers)
    }

    public static func trace(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .trace, query: query, headers: headers)
    }
}

// Deprecated in Get 1.0
@available(*, deprecated, message: "Please use Request initializer instead")
extension Request where Response == Void {
    public static func get(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .get, query: query, headers: headers)
    }

    public static func post(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .post, query: query, body: body, headers: headers)
    }

    public static func put(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .put, query: query, body: body, headers: headers)
    }

    public static func patch(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .patch, query: query, body: body, headers: headers)
    }

    public static func delete(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .delete, query: query, body: body, headers: headers)
    }

    public static func options(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .options, query: query, headers: headers)
    }

    public static func head(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .head, query: query, headers: headers)
    }

    public static func trace(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(url: url, method: .trace, query: query, headers: headers)
    }
}

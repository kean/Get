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
    /// Resource URL. Can be either absolute or relative.
    public var url: String
    /// Request query items.
    public var query: [(String, String?)]?
    /// Request headers to be added to the request.
    public var headers: [String: String]?
    /// ID provided by the user. Not used by the API client.
    public var id: String?

    // Deprecated in Get 1.0
    @available(*, deprecated, message: "Rename to url.")
    public var path: String {
        get { url }
        set { url = newValue }
    }

    let body: AnyEncodable?

    /// Initialiazes the request with the given parameters and the request body.
    public init(
        method: String = "GET",
        url: String,
        query: [(String, String?)]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) {
        self.method = method
        self.url = url
        self.query = query
        self.headers = headers
        self.body = body.map(AnyEncodable.init)
    }
}

extension Request {
    public static func get(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "GET", url: url, query: query, headers: headers)
    }

    public static func post(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", url: url, query: query, body: body, headers: headers)
    }

    public static func put(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", url: url, query: query, body: body, headers: headers)
    }

    public static func patch(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", url: url, query: query, body: body, headers: headers)
    }

    public static func delete(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", url: url, query: query, body: body, headers: headers)
    }

    public static func options(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "OPTIONS", url: url, query: query, headers: headers)
    }

    public static func head(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "HEAD", url: url, query: query, headers: headers)
    }

    public static func trace(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "TRACE", url: url, query: query, headers: headers)
    }
}

extension Request where Response == Void {
    public static func get(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "GET", url: url, query: query, headers: headers)
    }

    public static func post(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", url: url, query: query, body: body, headers: headers)
    }

    public static func put(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", url: url, query: query, body: body, headers: headers)
    }

    public static func patch(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", url: url, query: query, body: body, headers: headers)
    }

    public static func delete(_ url: String, query: [(String, String?)]? = nil, body: Encodable? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", url: url, query: query, body: body, headers: headers)
    }

    public static func options(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "OPTIONS", url: url, query: query, headers: headers)
    }

    public static func head(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "HEAD", url: url, query: query, headers: headers)
    }

    public static func trace(_ url: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "TRACE", url: url, query: query, headers: headers)
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

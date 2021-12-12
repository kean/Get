// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct Request<Response> {
    public var method: String
    public var path: String
    public var query: [String: String?]?
    var body: AnyEncodable?
    public var id: String?

    public static func get(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "GET", path: path, query: query)
    }

    public static func post(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "POST", path: path, query: query)
    }
    
    public static func post<U: Encodable>(_ path: String, query: [String: String?]? = nil, body: U?) -> Request {
        Request(method: "POST", path: path, query: query, body: body.map(AnyEncodable.init))
    }

    public static func put(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "PUT", path: path, query: query)
    }
    
    public static func put<U: Encodable>(_ path: String, query: [String: String?]? = nil, body: U?) -> Request {
        Request(method: "PUT", path: path, query: query, body: body.map(AnyEncodable.init))
    }
    
    public static func patch(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "PATCH", path: path, query: query)
    }
    
    public static func patch<U: Encodable>(_ path: String, query: [String: String?]? = nil, body: U?) -> Request {
        Request(method: "PATCH", path: path, query: query, body: body.map(AnyEncodable.init))
    }
    
    public static func delete(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "DELETE", path: path, query: query)
    }
    
    public static func delete<U: Encodable>(_ path: String, query: [String: String?]? = nil, body: U?) -> Request {
        Request(method: "DELETE", path: path, query: query, body: body.map(AnyEncodable.init))
    }
    
    public static func options(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "OPTIONS", path: path, query: query)
    }
    
    public static func head(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "HEAD", path: path, query: query)
    }
    
    public static func trace(_ path: String, query: [String: String?]? = nil) -> Request {
        Request(method: "TRACE", path: path, query: query)
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

extension URLRequest {
    public func cURLDescription() -> String {
        guard let url = url, let method = httpMethod else {
            return "$ curl command generation failed"
        }
        var components = ["curl -v"]
        components.append("-X \(method)")
        for header in allHTTPHeaderFields ?? [:] {
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.key): \(escapedValue)\"")
        }
        if let httpBodyData = httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escapedBody)\"")
        }
        components.append("\"\(url.absoluteString)\"")
        return components.joined(separator: " \\\n\t")
    }
}

public struct Response<T> {
    public let value: T
    /// Original response data.
    public let data: Data
    /// Original request.
    public let request: URLRequest
    public let response: HTTPURLResponse
    public let statusCode: Int
    
    func map<U>(_ closure: (T) -> U) -> Response<U> {
        Response<U>(value: closure(value), data: data, request: request, response: response, statusCode: statusCode)
    }
}

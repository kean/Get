// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct Request<Response> {
    public var method: String
    public var path: String
    public var query: [(String, String?)]?
    var body: AnyEncodable?
    public var headers: [String: String]?
    public var id: String?

    public static func get(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "GET", path: path, query: query, headers: headers)
    }

    public static func post(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", path: path, query: query, headers: headers)
    }
    
    public static func post<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "POST", path: path, query: query, body: body.map(AnyEncodable.init), headers: headers)
    }

    public static func put(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", path: path, query: query, headers: headers)
    }
    
    public static func put<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "PUT", path: path, query: query, body: body.map(AnyEncodable.init), headers: headers)
    }
    
    public static func patch(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", path: path, query: query, headers: headers)
    }
    
    public static func patch<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "PATCH", path: path, query: query, body: body.map(AnyEncodable.init), headers: headers)
    }
    
    public static func delete(_ path: String, query: [(String, String?)]? = nil, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", path: path, query: query, headers: headers)
    }
    
    public static func delete<U: Encodable>(_ path: String, query: [(String, String?)]? = nil, body: U?, headers: [String: String]? = nil) -> Request {
        Request(method: "DELETE", path: path, query: query, body: body.map(AnyEncodable.init), headers: headers)
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

public struct Response<T> {
    public let value: T
    /// Original response data.
    public let data: Data
    /// Original request.
    public let request: URLRequest
    public let response: HTTPURLResponse
    public let statusCode: Int
    public var metrics: URLSessionTaskMetrics?
    
    func map<U>(_ closure: (T) -> U) -> Response<U> {
        Response<U>(value: closure(value), data: data, request: request, response: response, statusCode: statusCode, metrics: metrics)
    }
}

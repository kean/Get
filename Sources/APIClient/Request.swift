// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct Request<T> {
    var method: String
    var path: String
    var query: [String: String]?
    var body: AnyEncodable?

    public static func get(_ path: String, query: [String: String]? = nil) -> Request {
        Request(method: "GET", path: path, query: query)
    }
    
    public static func post<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "POST", path: path, body: AnyEncodable(body))
    }
    
    public static func patch<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "PATCH", path: path, body: AnyEncodable(body))
    }
    
    public static func put<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "PUT", path: path, body: AnyEncodable(body))
    }
    
    public static func delete<U: Encodable>(_ path: String, body: U) -> Request {
        Request(method: "DELETE", path: path, body: AnyEncodable(body))
    }
}

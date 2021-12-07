// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct Request<Response> {
    var method: String
    var path: String
    var query: [String: String?]?
    var body: AnyEncodable?

    public static func get(_ path: String, query: [String: String?]? = nil) -> Request {
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

// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

extension URL {
    /// A helper throwable URL initializer.
    init(scheme: String = "https", host: String, path: String) throws {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        guard let url = components.url else {
            assertionFailure("Failed to create URL for host: \(host), path: \(path)")
            throw URLError(.badURL)
        }
        self = url
    }
}

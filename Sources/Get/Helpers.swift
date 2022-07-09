// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct AnyEncodable: Encodable {
    private let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

actor Serializer {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(decoder: JSONDecoder?, encoder: JSONEncoder?) {
        if let decoder = decoder {
            self.decoder = decoder
        } else {
            self.decoder = JSONDecoder()
            self.decoder.dateDecodingStrategy = .iso8601
        }
        if let encoder = encoder {
            self.encoder = encoder
        } else {
            self.encoder = JSONEncoder()
            self.encoder.dateEncodingStrategy = .iso8601
        }
    }

    func decode<T: Decodable>(_ data: Data) async throws -> T {
        try decoder.decode(T.self, from: data)
    }

    func encode<T: Encodable>(_ entity: T) async throws -> Data {
        try encoder.encode(entity)
    }
}

extension OperationQueue {
    static func serial() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
}

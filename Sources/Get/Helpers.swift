// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

// A simple URLSession wrapper adding async/await APIs compatible with older platforms.
final class DataLoader: NSObject, URLSessionDataDelegate {
    private var handlers = [URLSessionTask: TaskHandler]()
    private typealias Completion = (Result<(Data, URLResponse), Error>) -> Void
    
    /// Loads data with the given request.
    func data(for request: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        final class Box { var task: URLSessionTask? }
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation { continuation in
                box.task = self.loadData(with: request, session: session) { result in
                    continuation.resume(with: result)
                }
            }
        })
    }
    
    private func loadData(with request: URLRequest, session: URLSession, completion: @escaping Completion) -> URLSessionTask {
        let task = session.dataTask(with: request)
        session.delegateQueue.addOperation {
            self.handlers[task] = TaskHandler(completion: completion)
        }
        task.resume()
        return task
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = handlers[task] else { return }
        handlers[task] = nil
        if let data = handler.data, let response = task.response, error == nil {
            handler.completion(.success((data, response)))
        } else {
            handler.completion(.failure(error ?? URLError(.unknown)))
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let handler = handlers[dataTask] else {
            return
        }
        if handler.data == nil {
            handler.data = Data()
        }
        handler.data!.append(data)
    }

    private final class TaskHandler {
        var data: Data?
        let completion: Completion

        init(completion: @escaping Completion) {
            self.completion = completion
        }
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

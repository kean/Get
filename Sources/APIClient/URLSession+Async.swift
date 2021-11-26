import Foundation

extension URLSession {
    @available(macOS, obsoleted: 12, message: "Use new URLSession data(for:) method instead")
    @available(iOS, obsoleted: 15, message: "Use new URLSession data(for:) method instead")
    @available(macCatalyst, obsoleted: 15, message: "Use new URLSession data(for:) method instead")
    @available(watchOS, obsoleted: 8, message: "Use new URLSession data(for:) method instead")
    @available(tvOS, obsoleted: 15, message: "Use new URLSession data(for:) method instead")
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        let cancellableTask = CancellableTask()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                cancellableTask.task = dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }
                cancellableTask.task?.resume()
            }
        } onCancel: {
            cancellableTask.task?.cancel()
        }
    }
}

private final class CancellableTask {
    var task: URLSessionTask?
}

// The MIT License (MIT)
//
// Copyright (c) 2021-2024 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Allows you to modify ``APIClient`` behavior.
public protocol APIClientDelegate {
    /// Allows you to modify the request right before it is sent.
    ///
    /// Gets called right before sending the request. If the retries are enabled,
    /// is called before every attempt.
    ///
    /// - parameters:
    ///   - client: The client that sends the request.
    ///   - request: The request about to be sent. Can be modified
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws

    /// Validates response for the given request.
    ///
    /// - parameters:
    ///   - client: The client that sent the request.
    ///   - response: The response with an invalid status code.
    ///   - data: Body of the response, if any.
    ///   - request: Failing request.
    ///
    /// - throws: An error to be returned to the user. By default, throws
    /// ``APIError/unacceptableStatusCode(_:)`` if the code is outside of
    /// the `200..<300` range.
    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, task: URLSessionTask) throws

    /// Gets called after a networking failure. Only one retry attempt is allowed.
    ///
    /// - important: This method will only be called for network requests, but not for
    /// response body decoding failures or failures with creating requests using
    /// ``client(_:makeURLForRequest:)-8w0zh`` and ``client(_:willSendRequest:)-2d1ke``.
    ///
    /// - parameters:
    ///   - client: The client that sent the request.
    ///   - task: The failed task.
    ///   - error: The encountered error.
    ///   - attempts: The number of already performed attempts.
    ///
    /// - returns: Return `true` to retry the request.
    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool

    /// Constructs URL for the given request.
    ///
    /// - parameters:
    ///   - client: The client that sends the request.
    ///   - url: The URL passed by the client.
    ///   - request: The request about to be sent.
    ///
    /// - returns: The URL for the request. Return `nil` to use the default
    /// logic used by client.
    func client<T>(_ client: APIClient, makeURLForRequest request: Request<T>) throws -> URL?

    /// Allows you to override the client's encoder for a specific request.
    ///
    /// - Parameters:
    ///   - client: The client that sends the request.
    ///   - request: The request about to be sent.
    /// - Returns: The JSONEncoder for the request. Return `nil` to use the default
    /// encoder set in the client.
    func client<T>(_ client: APIClient, encoderForRequest request: Request<T>) -> JSONEncoder?

    /// Allows you to override the client's decoder for a specific request.
    ///
    /// - Parameters:
    ///   - client: The client that sends the request.
    ///   - request: The request that was performed.
    /// - Returns: The JSONDecoder for the request. Return `nil` to use the default
    /// decoder set in the client.
    func client<T>(_ client: APIClient, decoderForRequest request: Request<T>) -> JSONDecoder?
}

public extension APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        // Do nothing
    }

    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        false // Disabled by default
    }

    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, task: URLSessionTask) throws {
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.unacceptableStatusCode(response.statusCode)
        }
    }

    func client<T>(_ client: APIClient, makeURLForRequest request: Request<T>) throws -> URL? {
        nil // Use default handlings
    }

    func client<T>(_ client: APIClient, encoderForRequest request: Request<T>) -> JSONEncoder? {
        nil
    }

    func client<T>(_ client: APIClient, decoderForRequest request: Request<T>) -> JSONDecoder? {
        nil
    }
}

struct DefaultAPIClientDelegate: APIClientDelegate {}

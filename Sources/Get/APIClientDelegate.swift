// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

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
    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, request: URLRequest) throws

    /// Gets called after failure.  Only one retry attempt is allowed.
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
    ///   - request: The request about to be sent.
    ///
    /// - returns: The URL for the request. Return `nil` to use the default
    /// logic used by client.
    func client(_ client: APIClient, makeURLForPath path: String, query: [(String, String?)]?) throws -> URL?

    // Deprecated in Get 1.0
    @available(*, deprecated, message: "Please implement client(_:validateResponse:data:request:) instead. The current method is no longer used.")
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error

    // Deprecated in Get 1.0
    @available(*, deprecated, message: "Please use client(_:shouldRetryRequest:attempts:error:). The current method is no longer used.")
    func shouldClientRetry(_ client: APIClient, for request: URLRequest, withError error: Error) async throws -> Bool
}

public extension APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        // Do nothing
    }


    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        false // Disabled by default
    }

    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, request: URLRequest) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        throw APIError.unacceptableStatusCode(response.statusCode)
    }

    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        APIError.unacceptableStatusCode(response.statusCode)
    }

    func client(_ client: APIClient, makeURLForPath path: String, query: [(String, String?)]?) throws -> URL? {
        nil // Use default handlings
    }

    func shouldClientRetry(_ client: APIClient, for request: URLRequest, withError error: Error) async throws -> Bool { false }
}

struct DefaultAPIClientDelegate: APIClientDelegate {}

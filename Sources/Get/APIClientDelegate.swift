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

    /// Gets called when the request fails with an HTTP status code outside of
    /// the `200..<300` range.
    ///
    /// - parameters:
    ///   - client: The client that sent the request.
    ///   - response: The response with an invalid status code.
    ///   - data: Body of the response, if any.
    ///
    /// - returns: Error to be returned to the user. By default, returns
    /// ``APIError/unacceptableStatusCode(_:)``.
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error

    /// Gets called after failure.  Only one retry attempt is allowed.
    ///
    /// - parameters:
    ///   - client: The client that sent the request.
    ///   - response: The current request.
    ///   - error: The encountered error.
    ///
    /// - returns: Return `true` to retry the request.
    func shouldClientRetry(_ client: APIClient, for request: URLRequest, withError error: Error) async throws -> Bool

    /// Constructs URL for the given request.
    ///
    /// - parameters:
    ///   - client: The client that sends the request.
    ///   - request: The request about to be sent.
    ///
    /// - returns: The URL for the request. Return `nil` to use the default
    /// logic used by client.
    func client<T>(_ client: APIClient, makeURLForRequest request: Request<T>) throws -> URL?
}

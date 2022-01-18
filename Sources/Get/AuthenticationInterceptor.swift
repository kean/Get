// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

/// Types adopting the `Authenticator` protocol will load or update `Credential` and
/// apply the `Credential` to `URLRequest`.
public protocol Authenticator {
    /// Type of credential used to authenticate requests.
    associatedtype Credential

    /// Provide the current `Credential`.
    func credential() async throws -> Credential

    /// Refreshes the `Credential`.
    ///
    /// - parameter credential: The `Credential` before the refresh.
    func refreshCredential(with credential: Credential) async throws -> Credential

    /// Applies the `Credential` to the `URLRequest`.
    ///
    /// Example: Add access token in `Credential` to the `Authorization` header of `URLRequest`.
    ///
    /// - parameter credential: The `Credential`.
    /// - parameter urlRequest: The `URLRequest`.
    func apply(_ credential: Credential, to request: inout URLRequest) async throws
}


// MARK: - Errors

/// Represents various authentication failures that occur when using the `AuthenticationInterceptor`.
public struct AuthenticationError: Error, LocalizedError {
    /// Reason for the authentication error
    public enum Reason {
        case loadingCredentialFailed
        case refreshingCredentialFailed
        case applyingCredentialFailed
    }

    /// Underlying reason an authentication error occurred.
    public var reason: Reason

    /// The underlying `Error` responsible for generating the failure associated with `AuthenticationError`.
    public var underlyingError: Error?

    public var errorDescription: String? {
        switch reason {
        case .loadingCredentialFailed:
            return "Failed to load `Credential`."
        case .refreshingCredentialFailed:
            return "Failed to refresh `Credential`"
        case .applyingCredentialFailed:
            return "Failed to apply `Credential` to `URLRequest`."
        }
    }
}

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


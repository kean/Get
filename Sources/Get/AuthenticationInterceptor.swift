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

// MARK: -

/// The `AuthenticationInterceptor` class provides authentication for requests using exclusive control.
/// It relies on an `Authenticator` type to handle the actual `URLRequest` authentication and `Credential` refresh.
public class AuthenticationInterceptor<AuthenticatorType: Authenticator> {
    /// Type of credential used to authenticate requests.
    public typealias Credential = AuthenticatorType.Credential

    /// The `State` manage the loading state and the observers waiting to load with exclusive control.
    private actor State {
        var isLoading = false
        var observers: [(Result<Credential, Error>) -> Void] = []

        func startLoading() {
            isLoading = true
        }

        func endLoading(with result: Result<Credential, Error>) {
            observers.forEach { $0(result) }
            observers.removeAll()

            isLoading = false
        }

        func observeCredential() async throws -> Credential {
            try await withUnsafeThrowingContinuation { continueation in
                observers.append(continueation.resume(with:))
            }
        }
    }

    /// An instance that adopting the `Authenticator` protocol.
    public let authenticator: AuthenticatorType

    private let state = State()

    /// Initializes the `AuthorizationIntercepter` instance with the given parameters.
    ///
    /// - parameter authenticator: An instance that adopting the `Authenticator` protocol.
    public init(authenticator: AuthenticatorType) {
        self.authenticator = authenticator
    }

    /// Load the `Credential` using the exclusive control.
    ///
    /// - throws: Error wrapped in `AuthenticationError`.
    public func loadCredential() async throws -> Credential {
        guard await !state.isLoading else {
            // Waiting for credentials to be updated.
            return try await state.observeCredential()
        }

        await state.startLoading()

        do {
            let credential = try await authenticator.credential()
            await state.endLoading(with: .success(credential))
            return credential
        } catch {
            // Wrap the error with `AuthenticationError`.
            let authError = AuthenticationError(reason: .loadingCredentialFailed, underlyingError: error)
            await state.endLoading(with: .failure(authError))
            throw authError
        }
    }

    /// Refresh the `Credential` using the exclusive control.
    ///
    /// - throws: Error wrapped in `AuthenticationError`.
    @discardableResult
    public func refreshCredential() async throws -> Credential {
        guard await !state.isLoading else {
            // Waiting for credentials to be updated.
            return try await state.observeCredential()
        }

        await state.startLoading()

        do {
            let credential = try await authenticator.credential()
            let refreshedCredential = try await authenticator.refreshCredential(with: credential)
            await state.endLoading(with: .success(refreshedCredential))
            return refreshedCredential
        } catch {
            // Wrap the error with `AuthenticationError`.
            let authError = AuthenticationError(reason: .refreshingCredentialFailed, underlyingError: error)
            await state.endLoading(with: .failure(authError))
            throw authError
        }
    }
}

// MARK: - APIClientDelegate

extension AuthenticationInterceptor: APIClientDelegate {
    /// Apply the `Credential` to the `URLRequest` before sending the request.
    public func client(_: APIClient, willSendRequest request: inout URLRequest) async throws {
        let token = try await loadCredential()
        do {
            try await authenticator.apply(token, to: &request)
        } catch {
            // Wrap the error with `AuthenticationError`.
            throw AuthenticationError(reason: .applyingCredentialFailed, underlyingError: error)
        }
    }

    /// If an authentication error is received, refresh `Credentail` and retry the request.
    public func shouldClientRetry(_: APIClient, withError error: Error) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = (error as? APIError), statusCode == 401 {
            try await refreshCredential()
            return true
        }

        return false
    }
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

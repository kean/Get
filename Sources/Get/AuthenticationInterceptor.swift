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

    /// Applies the `Credential` to the `URLRequest`.
    ///
    /// Example: Add access token in `Credential` to the `Authorization` header of `URLRequest`.
    ///
    /// - parameter credential: The current `Credential`.
    /// - parameter request: The `URLRequest` to be sent.
    func apply(_ credential: Credential, to request: inout URLRequest) async throws

    /// Refreshes the `Credential`.
    ///
    /// - parameter credential: The current `Credential`.
    func refresh(_ credential: Credential) async throws -> Credential

    /// Determines whether the `URLRequest` failed due to an authentication error.
    ///
    /// Example of retrying if the HTTP status code is `401`:
    /// ```
    /// func didRequest(_ request: URLRequest, failDueToAuthenticationError error: Error) -> Bool {
    ///     if case .unacceptableStatusCode(let status) = (error as? APIError), status == 401 {
    ///        return true
    ///     }
    ///     return false
    /// }
    /// ```
    ///
    /// - parameter request: The `URLRequest` that was sent.
    /// - parameter error: The `Error` raised by sending the request.
    ///
    /// - returns: `true` if the `URLRequest` failed due to an authentication error, `false` otherwise.
    func didRequest(_ request: URLRequest, failDueToAuthenticationError error: Error) -> Bool

    /// Determines whether the `URLRequest` is authenticated with the `Credential`.
    ///
    /// Example of checking if `URLRequest` is authenticated with `Credential`:
    /// ```
    /// func isRequest(_ request: URLRequest, authenticatedWith credential: Credential) -> Bool {
    ///     request.value(forHTTPHeaderField: "Authorization") == "token \(credential.value)"
    /// }
    /// ```
    ///
    /// - parameter request: The `URLRequest`.
    /// - parameter credential: The `Credential`.
    ///
    /// - returns: `true` if the `URLRequest` is authenticated with the `Credential`, `false` otherwise.
    func isRequest(_ request: URLRequest, authenticatedWith credential: Credential) -> Bool
}

// MARK: -

/// The `AuthenticationInterceptor` class provides authentication for requests using exclusive control.
/// It relies on an `Authenticator` type to handle the actual `URLRequest` authentication and `Credential` refresh.
public class AuthenticationInterceptor<AuthenticatorType: Authenticator> {
    /// Type of credential used to authenticate requests.
    public typealias Credential = AuthenticatorType.Credential

    /// The `State` manage the loading state and the observers waiting to load with exclusive control.
    private actor State {
        private var isLoading = false
        private var waitingContinuations: [UnsafeContinuation<Credential, Error>] = []

        func startLoadingIfPossible() async -> Bool {
            guard !isLoading else { return false }

            isLoading = true
            return true
        }

        func endLoading(with result: Result<Credential, Error>) {
            let continuations = waitingContinuations
            waitingContinuations.removeAll()

            isLoading = false

            // Return loading result to waiting continuations.
            continuations.forEach { $0.resume(with: result) }
        }

        func waitForResultOfCredentialLoading() async throws -> Credential {
            try await withUnsafeThrowingContinuation { continueation in
                waitingContinuations.append(continueation)
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
    private func loadCredential() async throws -> Credential {
        guard await state.startLoadingIfPossible() else {
            return try await state.waitForResultOfCredentialLoading()
        }

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
    private func refresh(_ credential: Credential, with client: APIClient) async throws {
        guard await state.startLoadingIfPossible() else {
            _ = try await state.waitForResultOfCredentialLoading()
            return
        }

        do {
            let refreshedCredential = try await authenticator.refresh(credential)
            await state.endLoading(with: .success(refreshedCredential))
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
    ///
    /// - throws: The error wrapped in `AuthenticationError`.
    public func client(_: APIClient, willSendRequest request: inout URLRequest) async throws {
        let credential = try await loadCredential()

        do {
            try await authenticator.apply(credential, to: &request)
        } catch {
            // Wrap the error with `AuthenticationError`.
            throw AuthenticationError(reason: .applyingCredentialFailed, underlyingError: error)
        }
    }

    /// If an authentication error is received, refresh `Credentail` and retry the request.
    ///
    /// - throws: The error wrapped in `AuthenticationError`.
    public func shouldClientRetry(_ client: APIClient, for request: URLRequest, with error: Error) async throws -> Bool {
        if authenticator.didRequest(request, failDueToAuthenticationError: error) {
            let credential = try await loadCredential()

            // If Credential has been updated, retry without updating Credential.
            guard authenticator.isRequest(request, authenticatedWith: credential) else {
                return true
            }

            try await refresh(credential, with: client)
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

    public init(reason: Reason, underlyingError: Error) {
        self.reason = reason
        self.underlyingError = underlyingError
    }
}

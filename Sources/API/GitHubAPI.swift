// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct GitHubAPI {
    let api: API<Path>

    public init(client: APIClientProtocol, host: String) {
        self.api = API<Path>(client: client, host: host)
    }
    
    // TODO: Is this the best way to represent URLs?
    public enum Path: String, PathProtocol {
        case user = "/user"
        case userEmails = "/user/emails"
    }
}

// MARK: - /user/emails

extension GitHubAPI {
    /// List email addresses for the authenticated user.
    public func getUserEmails() async throws -> [UserEmail] {
        try await api.get(.userEmails)
    }
    
    /// Add an email address for the authenticated user.
    public func postUserEmails(emails: [String]) async throws {
        try await api.post(.userEmails, body: emails)
    }
    
    /// Delete an email address for the authenticated user.
    public func deleteUserEmails(emails: [String]) async throws {
        try await api.delete(.userEmails, body: emails)
    }
}

// TODO: Should it be in a namespace?
public struct UserEmail: Decodable {
    public let email: String
    public let verified: Bool
    public let primary: Bool
    public let visibility: String
}

// MARK: - /user

extension GitHubAPI {
    public func getUser() async throws -> User {
        try await api.get(.user)
    }
}

public struct User: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let hirable: Bool
    public let location: String
    public let bio: String
}

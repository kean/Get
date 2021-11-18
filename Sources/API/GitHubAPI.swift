// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - GitHubAPI (Example)

public struct GitHubAPI {
    let api: API

    public init(client: APIClientProtocol, host: String) {
        self.api = API(client: client, host: host)
    }
    
    public var userEmails: UserEmailsAPI { UserEmailsAPI(api: api) }
    public var user: UserAPI { UserAPI(api: api) }
}

// MARK: - /user/emails

extension GitHubAPI {
    public struct UserEmailsAPI {
        let api: API

        public let path: String = "/user/emails"
        
        /// List email addresses for the authenticated user.
        public func get() async throws -> [UserEmail] {
            try await api.get(path)
        }
        
        /// Add an email address for the authenticated user.
        public func post(_ emails: [String]) async throws {
            try await api.post(path, body: emails)
        }
        
        /// Delete an email address for the authenticated user.
        public func delete(_ emails: [String]) async throws {
            try await api.delete(path, body: emails)
        }
    }
}

// MARK: - /user

extension GitHubAPI {
    public struct UserAPI {
        let api: API

        public let path: String = "/user"
        
        public func get() async throws -> User {
            try await api.get(path)
        }
    }
}

// MARK: - Entities

public struct UserEmail: Decodable {
    public let email: String
    public let verified: Bool
    public let primary: Bool
    public let visibility: String
}

public struct User: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let hirable: Bool
    public let location: String
    public let bio: String
}

// MARK: - Usage


func usage() async throws {
    let client = APIClient()
    let api = GitHubAPI(client: client, host: "api.github.com")
    
    let user = try await api.user.get()
    let emails = try await api.userEmails.get()
    
    try await api.userEmails.delete(["octocat@gmail.com"])
    

    // Mocking
//    let mockClient = MockClient()
//    mockClient.set("path-to-json-file", for: api.userEmails.path, .get)
}

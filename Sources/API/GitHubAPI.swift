// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - GitHubAPI (Example)

public struct GitHubAPI {
    let api: APIClient

    public init(host: String) {
        self.api = APIClient(configuration: .default, host: host, delegate: GitHubAPIClientDelegate())
    }
}

// MARK: - /user

extension GitHubAPI {
    public var user: UserAPI { UserAPI(api: api) }
    
    public struct UserAPI {
        let api: APIClient

        public let path: String = "/user"
        
        public func get() async throws -> User {
            try await api.get(path)
        }
    }
}

// MARK: - /user/emails

extension GitHubAPI.UserAPI {
    
    public var emails: EmailsAPI { EmailsAPI(api: api) }
    
    public struct EmailsAPI {
        let api: APIClient

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

// MARK: - /users

extension GitHubAPI {
    public var users: UsersAPI { UsersAPI(api: api) }
    
    public struct UsersAPI {
        let api: APIClient

        public let path: String = "/users"
        
        public func get(named name: String) async throws -> User {
            try await api.get(path + "/\(name)")
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
    public let hireable: Bool
    public let location: String
    public let bio: String
}

// MARK: - APIClientDelegate

private final class GitHubAPIClientDelegate: APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) {
        request.setValue("Bearer: \("your-access-token")", forHTTPHeaderField: "Authorization")
    }
    
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool {
        switch error {
        case let error as APIClient.Error:
            switch error {
            case .unacceptableStatusCode(let statusCode):
                if statusCode == 401 {
                    // TODO: refresh access token and automatically retry.
                    // If refresh fails, ask for a password. If the user
                    // decides to logout, logout.
                    return true
                } else {
                    return false
                }
            }
        default:
            return false
        }
    }
    
    func client(_ client: APIClient, didEncounterInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        APIClient.Error.unacceptableStatusCode(response.statusCode)
    }
}

// MARK: - Usage

func usage() async throws {
    let api = GitHubAPI(host: "api.github.com")
        
    let user = try await api.user.get()
    let emails = try await api.user.emails.get()
    
    try await api.user.emails.delete(["octocat@gmail.com"])
        
    // Mocking
//    let mockClient = MockClient()
//    mockClient.set("path-to-json-file", for: api.userEmails.path, .get)
}

// TOOD: temp
public protocol AuthorizationProviderProtocol {
    func getAccessToken() -> String?
    func refreshAccessToken(_ accessToken: String) async throws
}

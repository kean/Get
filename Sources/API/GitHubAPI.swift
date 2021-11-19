// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - GitHubAPI (Example)

public struct GitHubAPI {
    public init() {}
}

// MARK: - /user

extension GitHubAPI {
    public var user: UserAPI { UserAPI() }
    
    public struct UserAPI {
        public let path: String = "/user"
        
        public var get: Request<User> {
            .get("/user")
        }
    }
}

// MARK: - /user/emails

extension GitHubAPI.UserAPI {
    public var emails: EmailsAPI { EmailsAPI() }
    
    public struct EmailsAPI {
        public let path: String = "/user/emails"
        
        public var get: Request<[UserEmail]> {
            .get(path)
        }
        
        public func post(_ emails: [String]) -> Request<Void> {
            .post(path, body: emails)
        }
        
        public func patch(_ emails: [String]) -> Request<Void> {
            .post(path, body: emails)
        }
        
        public func delete(_ emails: [String]) -> Request<Void> {
            .delete(path, body: emails)
        }
    }
}

// MARK: - /users

extension GitHubAPI {
    public var users: UsersAPI { UsersAPI() }
    
    public struct UsersAPI {
        public let path: String = "/users"
        
        public func get(named name: String) -> Request<User> {
            .get(path + "/\(name)")
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
    
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        APIClient.Error.unacceptableStatusCode(response.statusCode)
    }
}

// MARK: - Usage

func usage() async throws {
    let api = GitHubAPI()
    let client = APIClient(host: "api.github.com", delegate: GitHubAPIClientDelegate())
        
    let user = try await client.send(api.user.get)
    let user2 = try await client.send(GitHubAPI().user.get)
    let user2 = try await client.send(.user.get)
    let emails = try await client.send(api.user.emails.get)
    
    try await client.send(api.user.emails.delete(["octocat@gmail.com"]))

    // Mocking
//    let mockClient = MockClient()
//    mockClient.set("path-to-json-file", for: api.userEmails.path, .get)
}

// TOOD: temp
public protocol AuthorizationProviderProtocol {
    func getAccessToken() -> String?
    func refreshAccessToken(_ accessToken: String) async throws
}

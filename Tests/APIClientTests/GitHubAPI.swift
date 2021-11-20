// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import APIClient

// An example of an API definition. Feel free to use any other method for
// organizing the resources.
public struct GitHubAPI {
    public init() {}
}

// MARK: - /user

extension GitHubAPI {
    public var user: UserAPI { UserAPI() }
    
    public struct UserAPI {
        public let path: String = "/user"
        
        public var get: Request<User> {
            .get(path)
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
                
        public func delete(_ emails: [String]) -> Request<Void> {
            .delete(path, body: emails)
        }
    }
}

// MARK: - /users/{username}

extension GitHubAPI {
    public func users(_ name: String) -> UsersAPI {
        UsersAPI(name: name)
    }
    
    public struct UsersAPI {
        public let path: String
        
        init(name: String) {
            self.path = "/users/\(name)"
        }
        
        public var get: Request<User> {
            .get(path)
        }
    }
}

// MARK: - /users/{username}/followers

extension GitHubAPI.UsersAPI {
    public var followers: FollowersAPI { FollowersAPI(path: path) }
    
    public struct FollowersAPI {
        public let path: String
        
        init(path: String) {
            self.path = path + "/followers"
        }
        
        public var get: Request<[User]> {
            .get(path)
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
    public let login: String
    public let name: String
    public let hireable: Bool
    public let location: String
    public let bio: String
}

// MARK: - APIClientDelegate

enum GitHubError: Error {
    case unacceptableStatusCode(Int)
}

private final class GitHubAPIClientDelegate: APIClientDelegate {
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) {
        request.setValue("Bearer: \("your-access-token")", forHTTPHeaderField: "Authorization")
    }
        
    func shouldClientRetry(_ client: APIClient, withError error: Error) async -> Bool {
        if case .unacceptableStatusCode(let status) = (error as? GitHubError), status == 401 {
            return await refreshAccessToken()
        }
        return false
    }
    
    private func refreshAccessToken() async -> Bool {
        // TODO: Refresh (make sure you only refresh once if multiple requests fail)
        return false
    }
    
    func client(_ client: APIClient, didReceiveInvalidResponse response: HTTPURLResponse, data: Data) -> Error {
        GitHubError.unacceptableStatusCode(response.statusCode)
    }
}


// MARK: - Usage

func usage() async throws {
    let api = GitHubAPI()
    let client = APIClient(host: "api.github.com", delegate: GitHubAPIClientDelegate())
    
    let user = try await client.send(api.user.get)
    let emails = try await client.send(api.user.emails.get)
    
    try await client.send(api.user.emails.delete(["octocat@gmail.com"]))
        
    let followers = try await client.send(api.users("kean").followers.get)
    
    let user2: User = try await client.send(.get("/user"))
}

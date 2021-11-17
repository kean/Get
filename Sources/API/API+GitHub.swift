// The MIT License (MIT)
//
// Copyright (c) 2015-2021 Alexander Grebenyuk (github.com/kean).

import Foundation

public struct API {
    let client: APIClientProtocol
    
    #warning("TODO: pass environment")
    public init(client: APIClientProtocol) {
        self.client = client
    }
}

extension API {
    public func getUser() async throws -> UserResponse {
        fatalError()
    }
    
    public func postEmails(emails: [String]) async throws {
        fatalError()
    }
}

public struct UserResponse: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let hirable: Bool
    public let location: String
    public let bio: String
}

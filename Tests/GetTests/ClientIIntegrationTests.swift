// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

final class APIClientIntegrationTests: XCTestCase {

    func _testGitHubUsersApi() async throws {
        let client = APIClient.github()
        let user = try await client.send(Paths.users("kean").get).value
        XCTAssertEqual(user.login, "kean")
    }
}

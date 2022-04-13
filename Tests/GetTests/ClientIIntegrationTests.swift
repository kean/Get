// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class APIClientIntegrationTests: XCTestCase {

    func _testGitHubUsersApi() async throws {
        let sut = makeSUT()
        let user = try await sut.send(Paths.users("kean").get).value
        
        XCTAssertEqual(user.login, "kean")
    }

    // MARK: - Helpers

    private func makeSUT(using baseURL: URL? = URL(string: "https://api.github.com")) -> APIClient {
        let client = APIClient(baseURL: URL(string: "https://api.github.com"))

        trackForMemoryLeak(client)

        return client
    }
    
}

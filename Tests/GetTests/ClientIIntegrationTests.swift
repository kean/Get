// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import Get

final class APIClientIntegrationTests: XCTestCase {
    var sut: APIClient!
    
    override func setUp() {
        super.setUp()
        
        sut = APIClient(host: "api.github.com")
    }

    func _testGitHubUsersApi() async throws {
        let user = try await sut.send(Paths.users("kean").get).value
        
        XCTAssertEqual(user.login, "kean")
    }
}

// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ClientMakeRequestsTests: XCTestCase {
    var client: APIClient!

    override func setUp() {
        super.setUp()

        client = .github()
    }

    // MARK: - Relative Paths

    func testRelativePathStartingWithSlash() async throws {
        // GIVEN
        let request = Request.get("/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    func testRelativePath() async throws {
        // GIVEN
        let request = Request.get("user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    // MARK: - Absolute Paths

    func testAbsolutePaths() async throws {
        // GIVEN
        let request = Request.get("https://example.com/user")

        // WHEN client's baseURL is ignored
        let urlRequest = try await client.makeURLRequest(for: request)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/user")
    }
}

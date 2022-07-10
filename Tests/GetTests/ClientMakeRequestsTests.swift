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

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    func testRelativePath() async throws {
        // GIVEN
        let request = Request.get("user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    // MARK: - Absolute Paths

    func testAbsolutePaths() async throws {
        // GIVEN
        let request = Request.get("https://example.com/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN client's baseURL is ignored
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/user")
    }

    // MARK: - Override "Accept" and "Content-Type" Headers

    func testAcceptHeadersAreSetByDefault() async throws {
        // GIVEN
        let request = Request.get("https://example.com/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertNil(urlRequest.value(forHTTPHeaderField: "Content-Type")) // No body
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testContentTypeHeadersAreSetByDefault() async throws {
        // GIVEN
        let request = Request.post("https://example.com/user", body: User(id: 123, login: "kean"))

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testOverrideAcceptAndContentHeaders() async throws {
        // GIVEN
        let request = Request.put("https://example.com/user", body: User(id: 123, login: "kean"), headers: [
            "Content-Type": "application/xml",
            "Accept": "application/xml"
        ])

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/xml")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/xml")
    }
}

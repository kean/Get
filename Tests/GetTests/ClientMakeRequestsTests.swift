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

        client = .mock()
    }

    // MARK: - Relative Paths

    func testRelativePathStartingWithSlash() async throws {
        // GIVEN
        let request = Request(path: "/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    func testRelativePath() async throws {
        // GIVEN
        let request = Request(path: "user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/user")
    }

    func testRelativePathEmpty() async throws {
        // GIVEN
        let request = Request(path: "")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/")
    }

    func testRelativePathRoot() async throws {
        // GIVEN
        let request = Request(path: "/")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/")
    }

    func testBaseURLWithPathComponent() async throws {
        // GIVEN
        let client = APIClient(baseURL: URL(string: "https://gitlab.com/api/v4"))
        let request = Request(path: "/test")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertEqual(urlRequest.url, URL(string: "https://gitlab.com/api/v4/test"))
    }

    // MARK: - Absolute Paths

    func testAbsolutePaths() async throws {
        // GIVEN
        let request = Request(path: "https://example.com/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN client's baseURL is ignored
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/user")
    }

    // MARK: - Override "Accept" and "Content-Type" Headers

    func testAcceptHeadersAreSetByDefault() async throws {
        // GIVEN
        let request = Request(path: "https://example.com/user")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN
        XCTAssertNil(urlRequest.value(forHTTPHeaderField: "Content-Type")) // No body
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testContentTypeHeadersAreSetByDefault() async throws {
        // GIVEN
        var request = Request(path: "https://example.com/user", method: .post)
        request.body = User(id: 123, login: "kean")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN default headers are set
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testOverrideAcceptAndContentTypeHeaders() async throws {
        // GIVEN
        var request = Request(path: "https://example.com/user", method: .put)
        request.body = User(id: 123, login: "kean")
        request.headers = [
            "Content-Type": "application/xml",
            "Accept": "application/xml"
        ]

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN headers provided by the user are set
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/xml")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/xml")
    }

    func testOverrideAcceptAndContentTypeHeadersUsingSessionConfiguration() async throws {
        // GIVEN
        let client = APIClient(baseURL: URL(string: "https://api.github.com")) {
            $0.sessionConfiguration.httpAdditionalHeaders = [
                "Content-Type": "application/xml",
                "Accept": "application/xml"
            ]
        }
        var request = Request(path: "https://example.com/user", method: .put)
        request.body = User(id: 123, login: "kean")

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN headers are set when request is execute by URLSession
        XCTAssertNil(urlRequest.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertNil(urlRequest.value(forHTTPHeaderField: "Accept"))
    }
}

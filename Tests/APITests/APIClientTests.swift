// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import API

final class APIClientTests: XCTestCase {
    let sut = APIClient()
    
    func testSendLoadsData() async throws {
        // GIVEN
        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "users-kean", withExtension: "json"))
        let request = URLRequest(url: fileURL)
        
        // WHEN
        let (data, response) = try await sut.send(request)
        
        // THEN
        XCTAssertEqual(data.count, 1321)
        XCTAssertEqual(response.url, fileURL)
    }
    
    func testParseResponse() async throws {

    }
}

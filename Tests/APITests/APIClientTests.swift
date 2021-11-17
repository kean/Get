import XCTest
@testable import API

final class APIClientTests: XCTestCase {
    let sut = APIClient()
    
    
    func testSend() async throws {
        let usersURL = try XCTUnwrap(Bundle.module.url(forResource: "users-kean", withExtension: "json"))
        
    }
    
    func testParseResponse() async throws {
        
    }
}

// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ClientMiscTests: XCTestCase {
    /// Making sure all expected APIs compile
    func testClientInit() {
        _ = APIClient(baseURL: nil)
        _ = APIClient(baseURL: URL(string: "https://api.github.com"))
        _ = APIClient(baseURL: URL(string: "https://api.github.com")) {
            $0.sessionConfiguration.allowsConstrainedNetworkAccess = false
        }
        _ = APIClient(configuration: .init(baseURL: URL(string: "https://api.github.com")))
    }
}

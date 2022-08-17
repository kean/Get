// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
@testable import Get

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ClientDelegateTests: XCTestCase {
    // Override query item encoding.
    // Addresses https://github.com/kean/Get/issues/35
    func testOverridingQueryItemsEncoding() async throws {
        // GIVEN
        class ClientDelegate: APIClientDelegate {
            func client(_ client: APIClient, makeURLFor url: String, query: [(String, String?)]?) throws -> URL? {
                func makeURLComponents() -> URLComponents? {
                    let url = url.isEmpty ? "/" : url
                    let isRelative = url.starts(with: "/") || URL(string: url)?.scheme == nil
                    if isRelative {
                        let url = URL(string: url, relativeTo: client.configuration.baseURL)
                        return url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: true) }
                    } else {
                        return URLComponents(string: url)
                    }
                }
                guard var components = makeURLComponents() else {
                    throw URLError(.badURL)
                }
                if let query = query, !query.isEmpty {
                    func encode(_ string: String) -> String {
                        string.addingPercentEncoding(withAllowedCharacters: .nonReservedURLQueryAllowed) ?? string
                    }

                    let percentEncoded = query.reduce(into: [String]()) { queryString, query in
                        queryString.append("\(encode(query.0))=\(encode(query.1 ?? ""))")
                    }.joined(separator: "&")

                    components.percentEncodedQuery = percentEncoded
                }
                guard let url = components.url else {
                    throw URLError(.badURL)
                }
                return url
            }
        }

        let client = APIClient.mock {
            $0.delegate = ClientDelegate()
        }

        let request = Request(path: "/domain.tld", query: [("query", "value1+value2")])

        // WHEN
        let urlRequest = try await client.makeURLRequest(for: request)

        // THEN "+" is percent encoded
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.github.com/domain.tld?query=value1%2Bvalue2")
    }
}

private extension CharacterSet {
     /// Creates a CharacterSet according to RFC 3986 allowed characters and W3C recommendations
     ///
     /// See also [https://developer.apple.com/documentation/foundation/nsurlcomponents/1407752-queryitems](https://developer.apple.com/documentation/foundation/nsurlcomponents/1407752-queryitems).
     static let nonReservedURLQueryAllowed: CharacterSet = {
         let encodableCharacters = CharacterSet(charactersIn: ":#[]@!$&'()*+,;=")
         return CharacterSet.urlQueryAllowed.subtracting(encodableCharacters)
     }()
 }

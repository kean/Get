// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import Get

// Making sure that code samples compile.

enum API {}

extension API {
    static func users(_ name: String) -> UsersResource {
        UsersResource(path: "/users/\(name)")
    }

    struct UsersResource {
        /// `/users/{username}`
        let path: String

        var get: Request<User> { .get(path) }
    }
}

extension API.UsersResource {
    var repos: ReposResource { ReposResource(path: path + "/repos") }

    struct ReposResource {
        let path: String

        var get: Request<[Repo]> { .get(path) }
    }
}

struct Repo: Decodable {}

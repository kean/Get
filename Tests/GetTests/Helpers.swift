// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker

func json(named name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json")
    return try! Data(contentsOf: url!)
}

extension Mock {
    static func get(url: URL, json name: String) -> Mock {
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: json(named: name)
        ])
    }
}

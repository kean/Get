// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker

func json(named name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json")
    return try! Data(contentsOf: url!)
}

extension Mock {
    static func get(url: URL, statusCode: Int = 200, json name: String) -> Mock {
        Mock(url: url, dataType: .json, statusCode: statusCode, data: [
            .get: json(named: name)
        ])
    }

    static func get(url: URL, statusCode: Int = 200, message: String) -> Mock {
        Mock(url: url, dataType: .json, statusCode: statusCode, data: [
            .get: message.data(using: .utf8)!
        ])
    }
}

extension InputStream {
    var data: Data {
        open()
        let bufferSize: Int = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()
        while hasBytesAvailable {
            let readDat = read(buffer, maxLength: bufferSize)
            data.append(buffer, count: readDat)
        }
        buffer.deallocate()
        close()
        return data
    }
}

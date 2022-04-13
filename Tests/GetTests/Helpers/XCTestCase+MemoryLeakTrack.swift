//
//  XCTestCase+MemoryLeakTrack.swift
//  
//
//  Created by Onur Yörük on 13.04.22.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, file: file, line: line)
        }
    }

}

//
//  GlobTests.swift
//  WatchIt
//
//  Created by Alec Thomas on 7/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import XCTest
@testable import WatchIt

class GlobTests: XCTestCase {
    func testGlob() {
        XCTAssertTrue(glob("**/*.go", path: "foo/bar/waz.go"))
        XCTAssertFalse(glob("*/*.go", path: "foo/bar/waz.go"))
        XCTAssertTrue(glob("*/*.go", path: "bar/waz.go"))
        XCTAssertTrue(glob("*/*/*.go", path: "foo/bar/waz.go"))
        XCTAssertTrue(glob("*.go", path: "waz.go"))
        XCTAssertFalse(glob("*.go", path: "bar/waz.go"))
        XCTAssertTrue(glob("*.g?", path: "waz.go"))
        XCTAssertTrue(glob("*.g?", path: "waz.gp"))
    }
}
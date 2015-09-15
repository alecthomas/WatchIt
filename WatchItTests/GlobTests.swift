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
        must(glob("**/*.go", path: "foo/bar/waz.go"))
        must(!glob("*/*.go", path: "foo/bar/waz.go"))
        must(glob("*/*.go", path: "bar/waz.go"))
        must(glob("*/*/*.go", path: "foo/bar/waz.go"))
        must(glob("*.go", path: "waz.go"))
        must(!glob("*.go", path: "bar/waz.go"))
        must(glob("*.g?", path: "waz.go"))
        must(glob("*.g?", path: "waz.gp"))
    }
}
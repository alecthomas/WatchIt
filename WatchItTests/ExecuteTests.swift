//
//  ExecuteTests.swift
//  WatchIt
//
//  Created by Alec Thomas on 16/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import XCTest
@testable import WatchIt

class ExecuteTests: XCTestCase {
    func testExecuteSuccessWithOutput() {
        guard let (status, output) = must(try execute(["/bin/echo", "-n", "hello"])) else { return }
        require(status == 0)
        require(output == "hello")
    }

    func testExecuteNonZeroStatus() {
        guard let (status, _) = must(try execute(["/bin/cat", "/nonexistent/file"])) else { return }
        require(status != 0)
    }

    func testExecuteNonexistentBinary() {
        mustnt(try execute(["/nonexistent/file"]))
    }
}

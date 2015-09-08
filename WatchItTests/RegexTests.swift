//
//  RegexTests.swift
//  WatchIt
//
//  Created by Alec Thomas on 7/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import XCTest
@testable import WatchIt

class RegexTests: XCTestCase {
    func testCompileValidRegex() {
        var failed = false
        do {
            let _ = try Regex(pattern: ".*")
        } catch {
            failed = true
        }
        XCTAssertFalse(failed)
    }

    func testCompileInvalidRegex() {
        var failed = false
        do {
            let _ = try Regex(pattern: "*")
        } catch {
            failed = true
        }
        XCTAssertTrue(failed)
    }

    func testMatch() {
        let re = try! Regex(pattern: "^(\\D+)(\\d+)(\\D+)(\\d+)$")
        guard let match = try! re.match("abc123def456") else { XCTFail("expected match to succeed"); return }
        XCTAssertEqual(match.count, 5)
        XCTAssertEqual(match[1], "abc")
        XCTAssertEqual(match[2], "123")
        XCTAssertEqual(match[3], "def")
        XCTAssertEqual(match[4], "456")
    }

    func testSearch() {
        let re = try! Regex(pattern: "def(\\d+)")
        let text = "abc123def456"
        let range = text.rangeOfString("def456")
        guard let match = try! re.search(text) else { XCTFail("expected match to succeed"); return }
        XCTAssertEqual(match.ranges.count, 2)
        XCTAssertEqual(match.ranges[0], range)
        XCTAssertEqual(match[0], "def456")
        XCTAssertEqual(match[1], "456")
    }

    func testNamedSubmatch() {
        let re = try! Regex(pattern: "^(?<a>\\D+)(?<b>\\d+)$")
        guard let match = try! re.match("abc123") else { XCTFail("expected match to succeed"); return }
        XCTAssertEqual(match.count, 3)
        XCTAssertEqual(match[1], "abc")
        XCTAssertEqual(match[2], "123")
        XCTAssertEqual(match["a"], "abc")
        XCTAssertEqual(match["b"], "123")
    }

    func testReplace() {
        let re = try! Regex(pattern: "(\\d+)")
        XCTAssertEqual("abc(123)def(456)", try! re.replace("abc123def456", with: "(\\1)"))
    }

    func testReplaceWithCount() {
        let re = try! Regex(pattern: "(\\d+)")
        XCTAssertEqual("abc(123)def456", try! re.replace("abc123def456", with: "(\\1)", count: 1))
    }
    func testFindAll() {
        let re = try! Regex(pattern: "(\\d+)|(\\D+)")
        let matches = try! re.findAll("abc123def456")
        XCTAssertEqual(4, matches.count)
        XCTAssertEqual(matches[0][0], "abc")
        XCTAssertEqual(matches[1][0], "123")
        XCTAssertEqual(matches[2][0], "def")
        XCTAssertEqual(matches[3][0], "456")
    }
}
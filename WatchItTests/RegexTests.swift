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
        must(try Regex(pattern: ".*"))
    }

    func testCompileInvalidRegex() {
        mustnt(try Regex(pattern: "*"))
    }

    func testMatch() {
        let re = try! Regex(pattern: "^(\\D+)(\\d+)(\\D+)(\\d+)$")
        guard let match = must(try re.match("abc123def456")) else { return }
        require(match.count == 5)
        require(match[1] == "abc")
        require(match[2] == "123")
        require(match[3] == "def")
        require(match[4] == "456")
    }

    func testSearch() {
        let re = try! Regex(pattern: "def(\\d+)")
        let text = "abc123def456"
        guard let match = must(try re.search(text)) else { return }
        require(match.count == 2)
        require(match[0] == "def456")
        require(match[1] == "456")
    }

    func testNamedSubmatch() {
        guard let re = must(try Regex(pattern: "^(?<a>\\D+)(?<b>\\d+)$")) else { return }
        guard let match = must(try re.match("abc123")) else { return }
        require(match.count == 3)
        require(match[1] == "abc")
        require(match[2] == "123")
        require(match["a"] == "abc")
        require(match["b"] == "123")
    }

    func testReplace() {
        guard let re = must(try Regex(pattern: "(\\d+)")) else { return }
        require("abc(123)def(456)" == must(try re.replace("abc123def456", with: "(\\1)")))
    }

    func testReplaceWithCount() {
        let re = try! Regex(pattern: "(\\d+)")
        require("abc(123)def456" == must(try re.replace("abc123def456", with: "(\\1)", count: 1)))
    }

    func testMatchReplace() {
        let re = try! Regex(pattern: "(\\d+)")
        let match = try! re.search("abc123def456")!
        require(match.replace("(\\1)") == "abc(123)def456")
    }

    func testFindAll() {
        let re = try! Regex(pattern: "(\\d+)|(\\D+)")
        let matches = try! re.findAll("abc123def456")
        require(4 == matches.count)
        require(matches[0][0] == "abc")
        require(matches[1][0] == "123")
        require(matches[2][0] == "def")
        require(matches[3][0] == "456")
    }

    func testFindAllMultiline() {
        let text =  "        Location:            parser_test.go:23\n" +
                    "        Error:               Expected not to be nil.\n" +
                    "        Messages:            An error is expected but got nil.\n" +
                    "\n" +
                    "        Location:            parser_test.go:24\n" +
                    "        Error:               Not equal: \"ello\" (expected)\n" +
                    "                             != \"hello\" (actual)\n"

        let re = try! Regex(pattern: "Location:\\s+(?<path>[^:]+):(?<line>\\d+)$\\s+Error:\\s+(?<message>[^\\n]+)", options: RegexOptions.MULTILINE)
        guard let matches = must(try re.findAll(text)) else { return }
        require(matches.count == 2)

        require(matches[0]["path"] == "parser_test.go")
        require(matches[0]["line"] == "23")
        require(matches[0]["message"] == "Expected not to be nil.")

        require(matches[1]["path"] == "parser_test.go")
        require(matches[1]["line"] == "24")
        require(matches[1]["message"] == "Not equal: \"ello\" (expected)")
    }

    func testUTFFindAll() {
        let text =  "Sîne klâwen durh die wolken sint geslagen,\n" +
                    "er stîget ûf mit grôzer kraft,\n" +
                    "ich sih in grâwen tägelîch als er wil tagen,\n" +
                    "den tac, der im geselleschaft\n" +
                    "erwenden wil, dem werden man,\n" +
                    "den ich mit sorgen în verliez.\n" +
                    "ich bringe in hinnen, ob ich kan.\n" +
                    "sîn vil manegiu tugent michz leisten hiez.\n"
        let re = try! Regex(pattern: "de[nrm]")
        guard let matches = must(try re.findAll(text)) else { return }
        require(matches.count == 6)
        let groups = matches.map({$0[0]!})
        require(groups == ["den", "der", "den", "dem", "den", "den"])
    }
}
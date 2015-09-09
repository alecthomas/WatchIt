//
//  ModelTest.swift
//  WatchIt
//
//  Created by Alec Thomas on 9/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Bond
import XCTest
@testable import WatchIt

class ModelTests: XCTestCase {
    func testWatchPropertyChanged() {
        let watch = Watch()
        var properties: [String] = []
        watch.propertyChanged.observeNew({n in properties.append(n)})
        watch.name.value = ""
        watch.command.value = ""
        watch.directory.value = ""
        watch.glob.value = ""
        watch.pattern.value = ""
        XCTAssertEqual(properties, ["name", "command", "directory", "glob", "pattern"])
    }

    func testPresetPropertyChanged() {
        let preset = Preset()
        var properties: [String] = []
        preset.propertyChanged.observeNew({n in properties.append(n)})
        preset.name.value = ""
        preset.command.value = ""
        preset.glob.value = ""
        preset.pattern.value = ""
        XCTAssertEqual(properties, ["name", "command", "glob", "pattern"])
    }

    func testElementChanged() {
        let watches = ObservableArray<Watch>([])
        var actual: [(Int, String)] = []
        watches.elementChanged.observeNew({i in actual.append(i)})
        let a = Watch()
        let b = Watch()
        watches.append(a)
        watches.append(b)
        a.name.value = "aname"
        b.name.value = "bname"
        a.command.value = "acommand"
        b.command.value = "bname"
        let expected  = ["0.name", "1.name", "0.command", "1.command"]
        XCTAssertEqual(actual.map({(i, n) in "\(i).\(n)"}), expected)
    }
}

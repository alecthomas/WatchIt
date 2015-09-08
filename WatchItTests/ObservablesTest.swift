//
//  ObservablesTest.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import XCTest
@testable import WatchIt

class ObservableTests: XCTestCase {
    func testObservableCollection() {
        let collection = ObservableCollection<Int>()
        var actual: [ObservableCollectionChangedEvent<Int>] = []
        collection.collectionChanged += {e in actual.append(e)}
        collection.append(1)
        collection.append(2)
        collection.insert(0, atIndex: 0)
        collection[0] = 3
        collection.removeAtIndex(0)
        let zeroRange = Range(start: 0, end: 0)
        XCTAssertTrue(ObservableCollectionChangedEvent.Added(range: zeroRange, elements: [1]) == actual[0])
        XCTAssertTrue(ObservableCollectionChangedEvent.Added(range: Range(start: 1, end: 1), elements: [2]) == actual[1])
        XCTAssertTrue(ObservableCollectionChangedEvent.Added(range: zeroRange, elements: [0]) == actual[2])
        XCTAssertTrue(ObservableCollectionChangedEvent.Removed(range: zeroRange, elements: [0]) == actual[3])
        XCTAssertTrue(ObservableCollectionChangedEvent.Added(range: zeroRange, elements: [3]) == actual[4])
        XCTAssertTrue(ObservableCollectionChangedEvent.Removed(range: zeroRange, elements: [3]) == actual[5])
    }
}
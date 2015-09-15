//
//  ObservablesTest.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RxBlocking
@testable import WatchIt

class ObservableTests: XCTestCase {
    func testObservableCollection() {
        let collection = ObservableCollection<Int>()
        var actual: [ObservableCollectionEvent<Int>] = []
        collection.collectionChanged.subscribeNext({e in actual.append(e)})
        collection.append(1)
        collection.append(2)
        collection.insert(0, atIndex: 0)
        collection[0] = 3
        collection.removeAtIndex(0)
        let zeroRange = Range(start: 0, end: 0)
        must(ObservableCollectionEvent.Added(range: zeroRange, elements: [1]) == actual[0])
        must(ObservableCollectionEvent.Added(range: Range(start: 1, end: 1), elements: [2]) == actual[1])
        must(ObservableCollectionEvent.Added(range: zeroRange, elements: [0]) == actual[2])
        must(ObservableCollectionEvent.Removed(range: zeroRange, elements: [0]) == actual[3])
        must(ObservableCollectionEvent.Added(range: zeroRange, elements: [3]) == actual[4])
        must(ObservableCollectionEvent.Removed(range: zeroRange, elements: [3]) == actual[5])
    }

    func testObservableFlatten() {
        let a = try! [[1, 2, 3, 4]].asObservable().toArray()
        XCTAssertEqual([[1, 2, 3, 4]], a)
        let b = try! [[1, 2, 3, 4]].asObservable().flatMap({e in e.asObservable()}).toArray()
        XCTAssertEqual([1, 2, 3, 4], b)
    }
}
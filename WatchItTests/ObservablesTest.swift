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
        collection.collectionChanged += {e in
            print(e)
        }
        collection.append(1)
        collection.append(2)
        collection.insert(0, atIndex: 0)
        collection[0] = 3
        collection.removeAtIndex(0)
        for v in collection {
            print(v)
        }
    }
}
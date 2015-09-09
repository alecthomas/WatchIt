//
//  Extensions.swift
//  WatchIt
//
//  Created by Alec Thomas on 3/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import Bond

extension String {
    public var stringByExpandingTildeInPath: String {
        return (self as NSString).stringByExpandingTildeInPath
    }

    public var stringByReplacingHomeWithTilde: String {
        let home = NSHomeDirectory()
        if self.hasPrefix(home) {
            return "~" + self.substringFromIndex(home.endIndex)
        }
        return self
    }
}

public func == <T: Equatable>(a: Observable<T>, b: Observable<T>) -> Bool {
    return a.value == b.value
}

public func == <T: Equatable>(a: Observable<T>, b: T) -> Bool {
    return a.value == b
}

public func == <T: Equatable>(a: T, b: Observable<T>) -> Bool {
    return a == b.value
}
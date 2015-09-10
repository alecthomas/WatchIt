//
//  Extensions.swift
//  WatchIt
//
//  Created by Alec Thomas on 3/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift
import Cocoa

extension String {
    public var stringByExpandingTildeInPath: String {
        return (self as NSString).stringByExpandingTildeInPath
    }

    public var stringByResolvingSymlinksInPath: String {
        return (self as NSString).stringByResolvingSymlinksInPath
    }

    public var stringByReplacingHomeWithTilde: String {
        let home = NSHomeDirectory()
        if self.hasPrefix(home) {
            return "~" + self.substringFromIndex(home.endIndex)
        }
        return self
    }
}

public func == <T: Equatable>(a: Value<T>, b: Value<T>) -> Bool {
    return a.value == b.value
}

public func == <T: Equatable>(a: Value<T>, b: T) -> Bool {
    return a.value == b
}

public func == <T: Equatable>(a: T, b: Value<T>) -> Bool {
    return a == b.value
}


extension NSView {
    var enabledSubViews: Bool {
        get {
            for view in subviews {
                if let control = view as? NSControl {
                    return control.enabled
                }
            }
            return true
        }
        set(value) {
            for view in subviews {
                if let control = view as? NSControl {
                    control.enabled = value
                }
                view.enabledSubViews = value
            }
        }
    }
}
//
//  Extensions.swift
//  WatchIt
//
//  Created by Alec Thomas on 3/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import Bond
import Cocoa

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

// An ObservableStructure emits events whenever a property is changed.
public protocol ObservableStructure {
    var propertyChanged: Observable<String> { get }
}

// Extend ObservableArray to provide an elementChanged observable.
public extension ObservableArray where ElementType: ObservableStructure {
    public var elementChanged: EventProducer<(Int, String)> {
        let producer = EventProducer<(Int, String)>()
        for (i, element) in self.enumerate() {
            let o = element.propertyChanged
            o.skip(o.replayLength).map({n in (i, n)}).bindTo(producer)
        }
        observeNew({(event: ObservableArrayEvent<[ElementType]>) in
            switch event.operation {
            case let .Insert(elements, index):
                for (i, element) in elements.enumerate() {
                    let o = element.propertyChanged
                    o.skip(o.replayLength).map({n in (index + i, n)}).bindTo(producer)
                }
            case let .Update(elements, index):
                for (i, element) in elements.enumerate() {
                    let o = element.propertyChanged
                    o.skip(o.replayLength).map({n in (index + i, n)}).bindTo(producer)
                }
            default:
                break
            }
        })
        return producer
    }
}
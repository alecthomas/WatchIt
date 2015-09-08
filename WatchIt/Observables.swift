//
//  Observables.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation

public protocol ObservableEvent {}

public class Subscription<T: ObservableEvent> {
    private var handle: Int = 0
    private var observers: [Int:(T) -> ()] = [:]

    public func subscribe(observer: (T) -> ()) -> Int {
        let id = handle++
        observers[id] = observer
        return id
    }

    public func unsubscribe(id: Int) {
        observers.removeValueForKey(id)
    }

    public func emit(value: T) {
        for observer in observers.values {
            observer(value)
        }
    }
}

public func += <T>(subscription: Subscription<T>, observer: (T) -> ()) -> Int {
    return subscription.subscribe(observer)
}

public func -= <T>(subscription: Subscription<T>, id: Int) {
    subscription.unsubscribe(id)
}

public enum ObservableCollectionChangedEvent<Element>: ObservableEvent {
    case Added(index: Int, elements: [Element])
    case Removed(index: Int, elements: [Element])
    case Replaced(range: Range<Int>, old: [Element], new: [Element])
    case Reset(elements: [Element])
}

public func  == <T: Equatable>(a: ObservableCollectionChangedEvent<T>, b: ObservableCollectionChangedEvent<T>) -> Bool {
    switch a {
    case let .Added(ai, ae):
        if case let .Added(bi, be) = b { return ai == bi && ae == be }
    case let .Removed(ai, ae):
        if case let .Removed(bi, be) = b { return ai == bi && ae == be }
    case let .Replaced(ar, ao, an):
        if case let .Replaced(br, bo, bn) = b { return ar == br && ao == bo && an == bn }
    case let .Reset(ae):
        if case let .Reset(be) = b { return ae == be }
    }
    return false
}

// An Array-ish object that is observable.
public class ObservableCollection<Element>: CollectionType, ArrayLiteralConvertible {
    public let collectionChanged = Subscription<ObservableCollectionChangedEvent<Element>>()

    private var source: [Element]

    public var count: Int { return source.count }
    public var startIndex: Int { return source.startIndex }
    public var endIndex: Int { return source.endIndex }

    public init() {
        self.source = []
    }

    public init(source: [Element]) {
        self.source = source
    }

    public required init(arrayLiteral elements: Element...) {
        self.source = elements
    }

    public func append(element: Element) {
        source.append(element)
        collectionChanged.emit(.Added(index: source.count - 1, elements: [element]))
    }

    public func removeAll() {
        let elements = source
        source.removeAll()
        collectionChanged.emit(.Reset(elements: elements))
    }

    public func removeAtIndex(index: Int) -> Element {
        let element = source.removeAtIndex(index)
        collectionChanged.emit(.Removed(index: index, elements: [element]))
        return element
    }

    public func removeFirst() -> Element {
        let element = source.removeFirst()
        collectionChanged.emit(.Removed(index: 0, elements: [element]))
        return element
    }

    public func removeLast() -> Element {
        let element = source.removeLast()
        collectionChanged.emit(.Removed(index: source.count, elements: [element]))
        return element
    }

    public func insert(element: Element, atIndex i: Int) {
        source.insert(element, atIndex: i)
        collectionChanged.emit(.Added(index: i, elements: [element]))
    }

    public func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let index = source.count
        let elements = Array(newElements)
        source.appendContentsOf(newElements)
        collectionChanged.emit(.Added(index: index, elements: elements))
    }

    public func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with elements: C) {
        let old = Array(source[subRange])
        let new = Array(elements)
        source.replaceRange(subRange, with: elements)
        collectionChanged.emit(.Replaced(range: subRange, old: old, new: new))
    }

    public func popLast() -> Element? {
        return source.count == 0 ? nil : removeLast()
    }

    public subscript(index: Int) -> Element {
        get {
            return source[index]
        }
        set(value) {
            let old = source[index]
            source[index] = value
            collectionChanged.emit(.Replaced(range: Range<Int>(start: index, end: index), old: [old], new: [value]))
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        get {
            return source[range]
        }
        set(value) {
            let old = Array(source[range])
            source[range] = value
            collectionChanged.emit(.Replaced(range: range, old: old, new: Array(value)))
        }
    }
}
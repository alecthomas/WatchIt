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

public protocol ObservableProperty {}

public enum ObservablePropertyChangedEvent<Property: ObservableProperty>: ObservableEvent {
    case Changed(property: Property)
}

public enum ObservableCollectionChangedEvent<Element>: ObservableEvent {
    case Added(range: Range<Int>, elements: [Element])
    case Removed(range: Range<Int>, elements: [Element])
}

public func  == <T: Equatable>(a: ObservableCollectionChangedEvent<T>, b: ObservableCollectionChangedEvent<T>) -> Bool {
    switch a {
    case let .Added(ai, ae):
        if case let .Added(bi, be) = b { return ai == bi && ae == be }
    case let .Removed(ai, ae):
        if case let .Removed(bi, be) = b { return ai == bi && ae == be }
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
        let range = Range<Int>(start: source.count - 1, end: source.count - 1)
        collectionChanged.emit(.Added(range: range, elements: [element]))
    }

    public func removeAll() {
        let elements = source
        source.removeAll()
        collectionChanged.emit(.Removed(range: Range(start: source.startIndex, end: source.endIndex), elements: elements))
    }

    public func removeAtIndex(index: Int) -> Element {
        let element = source.removeAtIndex(index)
        collectionChanged.emit(.Removed(range: Range(start: index, end: index), elements: [element]))
        return element
    }

    public func removeFirst() -> Element {
        let element = source.removeFirst()
        collectionChanged.emit(.Removed(range: Range(start: 0, end: 0), elements: [element]))
        return element
    }

    public func removeLast() -> Element {
        let element = source.removeLast()
        collectionChanged.emit(.Removed(range: Range(start: count, end: count), elements: [element]))
        return element
    }

    public func insert(element: Element, atIndex i: Int) {
        source.insert(element, atIndex: i)
        collectionChanged.emit(.Added(range: Range(start: i, end: i), elements: [element]))
    }

    public func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let index = source.count
        let elements = Array(newElements)
        source.appendContentsOf(newElements)
        collectionChanged.emit(.Added(range: Range(start: index, end: index+elements.count), elements: elements))
    }

    public func replaceRange<C : CollectionType where C.Generator.Element == Element>(range: Range<Int>, with elements: C) {
        let old = Array(source[range])
        let new = Array(elements)
        source.replaceRange(range, with: elements)
        collectionChanged.emit(.Removed(range: range, elements: old))
        collectionChanged.emit(.Added(range: Range(start: range.startIndex, end: range.endIndex), elements: new))
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
            let range = Range<Int>(start: index, end: index)
            source[index] = value
            collectionChanged.emit(.Removed(range: range, elements: [old]))
            collectionChanged.emit(.Added(range: range, elements: [value]))
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        get {
            return source[range]
        }
        set(value) {
            let old = Array(source[range])
            source[range] = value
            collectionChanged.emit(.Removed(range: range, elements: old))
            collectionChanged.emit(.Added(range: Range(start: range.startIndex, end: range.startIndex), elements: Array(value)))
        }
    }
}
//
//  Observables.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public protocol ObservableEvent {}

public protocol ObservableStructure {
    var propertyChanged: Observable<String> { get }
}

public enum ObservableCollectionEvent<Element>: ObservableEvent {
    case Added(range: Range<Int>, elements: [Element])
    case Removed(range: Range<Int>, elements: [Element])
}

public func  == <T: Equatable>(a: ObservableCollectionEvent<T>, b: ObservableCollectionEvent<T>) -> Bool {
    switch a {
    case let .Added(ai, ae):
        if case let .Added(bi, be) = b { return ai == bi && ae == be }
    case let .Removed(ai, ae):
        if case let .Removed(bi, be) = b { return ai == bi && ae == be }
    }
    return false
}

// Extend ObservableCollection to allow observation of element changes
// iff the Element is an ObservableStructure.
public extension ObservableCollection where Element: ObservableStructure {
    public var elementChanged: Observable<(Element, String)> {
        let publisher = PublishSubject<(Element, String)>()
        for element in self {
            element.propertyChanged.map({n in (element, n)}).subscribe(publisher)
        }
        collectionChanged
            .subscribeNext({event in
                switch event {
                case let .Added(_, elements):
                    for element in elements {
                        element.propertyChanged.map({n in (element, n)}).subscribe(publisher)
                    }
                case .Removed:
                    break
                }
            })
        return publisher
    }

    public var anyChange: Observable<Void> {
        return sequenceOf(
            // Check changed elements for validity.
            elementChanged
                .map({(i, _) in
                    return true
                })
                .filter({$0})
                .map({_ in ()}),
            collectionChanged.map({_ in ()})
            ).merge()
    }
}

// An Array-ish object that is observable.
public class ObservableCollection<Element>: CollectionType, ArrayLiteralConvertible {
    public let collectionChanged = PublishSubject<ObservableCollectionEvent<Element>>()

    private(set) public var array: [Element]

    public var count: Int { return array.count }
    public var startIndex: Int { return array.startIndex }
    public var endIndex: Int { return array.endIndex }

    public init() {
        self.array = []
    }

    public init(source: [Element]) {
        self.array = source
    }

    deinit {
        collectionChanged.on(.Completed)
        collectionChanged.dispose()
    }

    public required init(arrayLiteral elements: Element...) {
        self.array = elements
    }

    public func append(element: Element) {
        array.append(element)
        let range = Range<Int>(start: array.count - 1, end: array.count - 1)
        collectionChanged.on(.Next(.Added(range: range, elements: [element])))
    }

    public func removeAll() {
        let elements = array
        array.removeAll()
        collectionChanged.on(.Next(.Removed(range: Range(start: array.startIndex, end: array.endIndex), elements: elements)))
    }

    public func removeAtIndex(index: Int) -> Element {
        let element = array.removeAtIndex(index)
        collectionChanged.on(.Next(.Removed(range: Range(start: index, end: index), elements: [element])))
        return element
    }

    public func removeFirst() -> Element {
        let element = array.removeFirst()
        collectionChanged.on(.Next(.Removed(range: Range(start: 0, end: 0), elements: [element])))
        return element
    }

    public func removeLast() -> Element {
        let element = array.removeLast()
        collectionChanged.on(.Next(.Removed(range: Range(start: count, end: count), elements: [element])))
        return element
    }

    public func insert(element: Element, atIndex i: Int) {
        array.insert(element, atIndex: i)
        collectionChanged.on(.Next(.Added(range: Range(start: i, end: i), elements: [element])))
    }

    public func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let index = array.count
        let elements = Array(newElements)
        array.appendContentsOf(newElements)
        collectionChanged.on(.Next(.Added(range: Range(start: index, end: index+elements.count), elements: elements)))
    }

    public func replaceRange<C : CollectionType where C.Generator.Element == Element>(range: Range<Int>, with elements: C) {
        let old = Array(array[range])
        let new = Array(elements)
        array.replaceRange(range, with: elements)
        collectionChanged.on(.Next(.Removed(range: range, elements: old)))
        collectionChanged.on(.Next(.Added(range: Range(start: range.startIndex, end: range.endIndex), elements: new)))
    }

    public func popLast() -> Element? {
        return array.count == 0 ? nil : removeLast()
    }

    public subscript(index: Int) -> Element {
        get {
            return array[index]
        }
        set(value) {
            let old = array[index]
            let range = Range<Int>(start: index, end: index)
            array[index] = value
            collectionChanged.on(.Next(.Removed(range: range, elements: [old])))
            collectionChanged.on(.Next(.Added(range: range, elements: [value])))
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        get {
            return array[range]
        }
        set(value) {
            let old = Array(array[range])
            array[range] = value
            collectionChanged.on(.Next(.Removed(range: range, elements: old)))
            collectionChanged.on(.Next(.Added(range: Range(start: range.startIndex, end: range.startIndex), elements: Array(value))))
        }
    }
}
//
//  Value.swift
//  WatchIt
//
//  Created by Alec Thomas on 10/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift
import Cocoa

public class Value<E>: SubjectType {
    let subject: BehaviorSubject<E>

    private var value_: E
    public var value: E {
        get {
            lock.lock()
            let v = value_
            lock.unlock()
            return v
        }
        set(value) {
            lock.lock()
            self.value_ = value
            lock.unlock()
            self.subject.on(.Next(value))
        }
    }

    private var lock = NSLock()

    public init(_ value: E) {
        self.value_ = value
        self.subject = BehaviorSubject(value: value)
        self.subject.on(.Next(value))
    }

    public func bidirectionalBindTo(field: NSTextField) -> Disposable {
        let disposable = CompositeDisposable()
        let s = value as! String
        field.stringValue = s
        field.rx_text.on(.Next(s))
        var setting = false
        disposable.addDisposable(subscribeNext({v in
            if !setting {
                setting = true
                let s = v as! String
                if field.stringValue != s {
                    field.stringValue = s
                    field.rx_text.on(.Next(s))
                }
                setting = false
            }
        }))
        disposable.addDisposable(field.rx_text.subscribeNext({v in
            if !setting {
                setting = true
                if self.value as! String != v {
                    self.value = v as! E
                }
                setting = false
            }
        }))
        return disposable
    }

    /// Subscribes `observer` to receive events from this observable
    public func subscribe<O: ObserverType where O.E == E>(observer: O) -> Disposable {
        return self.subject.subscribe(observer)
    }

    public func asObservable() -> Observable<E> {
        return self.subject
    }

    public func asObserver() -> BehaviorSubject<E> {
        return subject
    }

    deinit {
        self.subject.on(.Completed)
    }
}

public func bidirectionalBindTo<E: Equatable>(a: Value<E>, _ b: Value<E>) -> Disposable {
    let disposable = CompositeDisposable()
    var setting = false
    b.value = a.value
    disposable.addDisposable(b.subscribeNext({v in
        if !setting {
            setting = true
            if !(a == v) {
                a.value = v
            }
            setting = false
        }
    }))
    disposable.addDisposable(a.subscribeNext({v in
        if !setting {
            setting = true
            if !(b == v) {
                b.value = v
            }
            setting = false
        }
    }))
    return disposable
}

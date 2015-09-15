//
//  Require.swift
//  WatchIt
//
//  Created by Alec Thomas on 15/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import XCTest

protocol Testable {
    func runTest() -> Bool
}

// Require an expression to evaluate to true.
func require(result: Testable, file: String = __FILE__, line: UInt = __LINE__) -> String {
    if !result.runTest() {
        XCTFail("\(result)", file: file, line: line)
    }
    return ""
}

// A result must be true. It is suggested that a message be provided.
func must(result: Bool, message: String? = "", file: String = __FILE__, line: UInt = __LINE__) -> String {
    if !result {
        let m = message ?? "result must be true"
        XCTFail("\(m)", file: file, line: line)
    }
    return ""
}

// Closure must succeed.
func must<T>(@autoclosure result: () throws -> T?, message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) -> T? {
    do {
        return try result()
    } catch let e {
        let m = message ?? "unexpected error"
        XCTFail("\(m): \(e)", file: file, line: line)
    }
    return nil
}

// Closure must fail.
func mustnt<T>(@autoclosure result: () throws -> T?, message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let _ = try result()
        let m = message ?? "expected error"
        XCTFail("\(m)", file: file, line: line)
    } catch {
    }
}

class TestExpression: CustomStringConvertible, Testable {
    let test: () -> Bool
    let description: String

    init(test: () -> Bool, description: String) {
        self.test = test
        self.description = description
    }

    func runTest() -> Bool {
        return test()
    }
}

func == <T: Equatable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l == r}, description: "\(l) == \(r)")
}

func != <T: Equatable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l != r}, description: "\(l) != \(r)")
}

func < <T: Comparable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l < r}, description: "\(l) < \(r)")
}

func > <T: Comparable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l > r}, description: "\(l) > \(r)")
}

func <= <T: Comparable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l <= r}, description: "\(l) <= \(r)")
}

func >= <T: Comparable>(l: T, r: T) -> TestExpression {
    return TestExpression(test: {l >= r}, description: "\(l) >= \(r)")
}

func == <T: Equatable>(l: [T], r: [T]) -> TestExpression {
    return TestExpression(test: {l == r}, description: "\(l) == \(r)")
}

func != <T: Equatable>(l: [T], r: [T]) -> TestExpression {
    return TestExpression(test: {l != r}, description: "\(l) != \(r)")
}

func == <T: Equatable>(l: Set<T>, r: Set<T>) -> TestExpression {
    return TestExpression(test: {l == r}, description: "\(l) == \(r)")
}

func != <T: Equatable>(l: Set<T>, r: Set<T>) -> TestExpression {
    return TestExpression(test: {l != r}, description: "\(l) != \(r)")
}

func == <K: Equatable, V: Equatable>(l: [K:V], r: [K:V]) -> TestExpression {
    return TestExpression(test: {l == r}, description: "\(l) == \(r)")
}

func != <K: Equatable, V: Equatable>(l: [K:V], r: [K:V]) -> TestExpression {
    return TestExpression(test: {l != r}, description: "\(l) != \(r)")
}

func == <T: Equatable>(l: T?, r: T?) -> TestExpression {
    return TestExpression(test: {l == r}, description: "\(l) == \(r)")
}

func != <T: Equatable>(l: T?, r: T?) -> TestExpression {
    return TestExpression(test: {l != r}, description: "\(l) != \(r)")
}
//
//  Runner.swift
//  WatchIt
//
//  Created by Alec Thomas on 11/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public class WatchError: CustomStringConvertible {
    public let id: String
    public let watch: Watch
    public let path: String
    public let line: Int
    public let message: String

    public init(watch: Watch, path: String, line: Int, message: String) {
        self.id = NSUUID().UUIDString
        self.watch = watch
        self.path = path
        self.line = line
        self.message = message
    }

    public var description: String {
        let last = (path as NSString).lastPathComponent
        return "\(last):\(line): \(message)"
    }
}

public class WatchTask: CustomStringConvertible {
    private let pattern: Regex
    private var process: ProcessState!
    public let watch: Watch
    private(set) public var stdout = ""
    private(set) public var stderr = ""
    private(set) public var status: Int = -1
    private(set) public var errors: [WatchError] = []

    public init(watch: Watch) {
        self.watch = watch
        self.pattern = try! Regex(pattern: watch.pattern.value, options: RegexOptions.MULTILINE|RegexOptions.UTF8)
    }

    public func run() -> Int {
        do {
            process = try Process(command: ["/bin/sh", "-l", "-c", watch.command.value], cwd: watch.realPath).launch()
            let (status, output) = try process.wait()
            for match in try pattern.findAll(output) {
                if  let path = match["path"], let line = Int(match["line"] ?? "0"), let message = match["message"] {
                    errors.append(WatchError(watch: watch, path: path, line: line, message: message))
                }
            }
            return status
        } catch let err {
            log.error("exec of \(watch.command.value) failed: \(err)")
        }
        return -1
    }

    public func kill() {
        if let process = self.process {
            // Ignore any error from kill.
            do {
                try process.kill()
            } catch let err {
                log.error("failed to kill process: \(err)")
            }
        }
    }

    public var description: String {
        return "WatchTask(watch: \(watch))"
    }
}

public class Runner {
    private var lock = NSLock()
    private var running: [String: WatchTask] = [:]
    private var failurePublisher = PublishSubject<WatchError>()

    public var failures: Observable<WatchError> { return failurePublisher }

    public init(changes: Observable<Watch>) {
        changes.subscribeNext(self.start)
    }

    private func start(watch: Watch) {
        log.info("Starting watch: \(watch)")
        lock.performLocked {
            if let task = running[watch.name.value] {
                log.info("Terminating existing watch task: \(task)")
                task.kill()
            }
            let runner = WatchTask(watch: watch)
            running[watch.name.value] = runner

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { self.run(runner) })
        }
    }

    private func run(watch: WatchTask) {
        defer {
            log.info("Cleaning up task: \(watch.status)")
            lock.performLocked {
                running.removeValueForKey(watch.watch.name.value)
            }
        }


        log.info("Launching watch task: \(watch)")
        watch.run()
        for error in watch.errors {
            failurePublisher.on(.Next(error))
        }
    }
}
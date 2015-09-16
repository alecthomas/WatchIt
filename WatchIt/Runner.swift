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

public class WatchTask: Disposable, CustomStringConvertible {
    private var task: NSTask?
    private let pattern: Regex

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
        let stdoutPipe = NSPipe()
        let stderrPipe = NSPipe()
        defer {
            stdoutPipe.fileHandleForReading.closeFile()
            stderrPipe.fileHandleForReading.closeFile()
            stdoutPipe.fileHandleForWriting.closeFile()
            stderrPipe.fileHandleForWriting.closeFile()
        }
        task = NSTask()
        task?.currentDirectoryPath = watch.directory.value
        task?.standardOutput = stdoutPipe
        task?.standardError = stderrPipe
        task?.launchPath = "/bin/sh"
        task?.arguments = ["-l", "-c", watch.command.value]
        task?.launch()
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stdout = NSString(data: stdoutData, encoding: NSUTF8StringEncoding)! as String
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        stderr = NSString(data: stderrData, encoding: NSUTF8StringEncoding)! as String
        status = Int(task?.terminationStatus ?? -1)
        for match in (try? pattern.findAll(stdout + stderr)) ?? [] {
            if  let path = match["path"],
                let line = Int(match["line"] ?? "0"),
                let message = match["message"] {
                    errors.append(WatchError(watch: watch, path: path, line: line, message: message))
            }
        }
        return status
    }

    public func dispose() {
        task?.terminate()
    }

    public var description: String {
        return "WatchTask(watch: \(watch), task: '\(task?.launchPath) \(task?.arguments)')"
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
                task.dispose()
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
                watch.dispose()
            }
        }


        log.info("Launching watch task: \(watch)")
        watch.run()
        for error in watch.errors {
            failurePublisher.on(.Next(error))
        }
    }
}
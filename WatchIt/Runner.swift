//
//  Runner.swift
//  WatchIt
//
//  Created by Alec Thomas on 11/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public class WatchTask: Disposable, CustomStringConvertible {
    private var task: NSTask?
    private let pattern: Regex

    public let watch: Watch
    private(set) public var stdout = ""
    private(set) public var stderr = ""
    private(set) public var status: Int = -1

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
        task?.terminationHandler = {_ in
            print("finished")
        }
        task?.launch()
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stdout = NSString(data: stdoutData, encoding: NSUTF8StringEncoding)! as String
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        stderr = NSString(data: stderrData, encoding: NSUTF8StringEncoding)! as String
        status = Int(task?.terminationStatus ?? -1)
        return status
    }

    public func matches() -> [RegexMatch] {
        return (try? pattern.findAll(stdout + stderr)) ?? []
    }

    public func dispose() {
        task?.terminate()
    }

    public var description: String {
        return "RunningWatch(watch: \(watch), task: '\(task?.launchPath) \(task?.arguments)')"
    }
}

public struct Failure {
    public var path: String
    public var line: Int
    public var column: Int?
    public var message: String
}

public class Runner {
    private var lock = NSLock()
    private var running: [String: WatchTask] = [:]
    private var failurePublisher = PublishSubject<Failure>()
    private var completedPublisher = PublishSubject<WatchTask>()

    public var failures: Observable<Failure> { return failurePublisher }
    public var completed: Observable<WatchTask> { return completedPublisher }

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

        completedPublisher.on(.Next(watch))

        for match in watch.matches() {
            print(match["path"], match["line"], match["message"])
        }
    }
}
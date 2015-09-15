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
    private let task: NSTask
    private let stdoutPipe: NSPipe
    private let stderrPipe: NSPipe
    private let pattern: Regex

    public let watch: Watch
    private(set) public var stdout = NSData()
    private(set) public var stderr = NSData()
    private(set) public var status: Int = -1

    public init(watch: Watch, task: NSTask, stdout: NSPipe, stderr: NSPipe) {
        self.watch = watch
        self.task = task
        self.stdoutPipe = stdout
        self.stderrPipe = stderr
        self.pattern = try! Regex(pattern: watch.pattern.value, options: RegexOptions.MULTILINE|RegexOptions.UTF8)
    }

    public func run() -> Int {
        task.launch()
        stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        status = Int(task.terminationStatus)
        return self.status
    }

    public func matches() -> [RegexMatch] {
        return []
    }

    public func dispose() {
        task.terminate()
        stdoutPipe.fileHandleForReading.closeFile()
        stderrPipe.fileHandleForReading.closeFile()
    }

    public var description: String {
        return "RunningWatch(watch: \(watch), task: '\(task.launchPath) \(task.arguments)')"
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
            let task = NSTask()
            let stdout = NSPipe()
            let stderr = NSPipe()
            task.currentDirectoryPath = watch.directory.value
            task.standardOutput = stdout
            task.standardError = stderr
            task.launchPath = "/bin/sh"
            print(task.environment)
            task.arguments = ["-l", "-c", watch.command.value]

            let runner = WatchTask(watch: watch, task: task, stdout: stdout, stderr: stderr)
            running[watch.name.value] = runner

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { self.run(runner) })
        }
    }

    private func run(watch: WatchTask) {
        let stdoutFile = watch.stdoutPipe.fileHandleForReading
        let stderrFile = watch.stderrPipe.fileHandleForReading

        defer {
            log.info("Cleaning up task: \(watch.task.terminationStatus)")
            lock.performLocked {
                running.removeValueForKey(watch.watch.name.value)
                watch.dispose()
            }
        }


        log.info("Launching watch task: \(watch)")
        let status = watch.run()

        completedPublisher.on(.Next(watch))

        guard let stdout = NSString(data: watch.stdout, encoding: NSUTF8StringEncoding) as? String else { return }
        guard let stderr = NSString(data: watch.stderr, encoding: NSUTF8StringEncoding) as? String else { return }

        for match in try! watch.pattern.findAll(stdout + stderr) {
            print(match["path"], match["line"], match["message"])
        }
    }
}
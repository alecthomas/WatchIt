//
//  Runner.swift
//  WatchIt
//
//  Created by Alec Thomas on 11/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

class RunningWatch: Disposable, CustomStringConvertible {
    let watch: Watch
    let task: NSTask
    let stdout: NSPipe
    let stderr: NSPipe
    let pattern: Regex

    init(watch: Watch, task: NSTask, stdout: NSPipe, stderr: NSPipe) {
        self.watch = watch
        self.task = task
        self.stdout = stdout
        self.stderr = stderr
        self.pattern = try! Regex(pattern: watch.pattern.value, options: RegexOptions.MULTILINE|RegexOptions.UTF8)
    }

    func run() {
    }

    func dispose() {
        task.terminate()
        stdout.fileHandleForReading.closeFile()
        stderr.fileHandleForReading.closeFile()
    }

    var description: String {
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
    private var running: [String: RunningWatch] = [:]

    private var failurePublisher =  PublishSubject<Failure>()
    public var failures: Observable<Failure>

    public init(changes: Observable<Watch>) {
        failures = failurePublisher
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

            let runner = RunningWatch(watch: watch, task: task, stdout: stdout, stderr: stderr)
            running[watch.name.value] = runner

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { self.run(runner) })
        }
    }

    private func run(watch: RunningWatch) {
        let stdoutFile = watch.stdout.fileHandleForReading
        let stderrFile = watch.stderr.fileHandleForReading

        log.info("Launching watch task: \(watch)")
        watch.task.launch()

        defer {
            log.info("Cleaning up task: \(watch.task.terminationStatus)")
            lock.performLocked {
                running.removeValueForKey(watch.watch.name.value)
                watch.dispose()
            }
        }

        guard let stdout = NSString(data: stdoutFile.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) as? String else { return }
        guard let stderr = NSString(data: stderrFile.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) as? String else { return }

        for match in try! watch.pattern.findAll(stdout + stderr) {
            print(match["path"], match["line"], match["message"])
        }
    }
}
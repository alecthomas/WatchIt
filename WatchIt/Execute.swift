//
//  Exec.swift
//  WatchIt
//
//  Created by Alec Thomas on 16/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Darwin
import Foundation


public enum ExecuteError: ErrorType, CustomStringConvertible {
    case Error(Int32, String)

    public var description: String {
        switch self {
        case let .Error(errno, message):
            return "\(message) (errno=\(errno))"
        }
    }

}

private func throwIfError(@autoclosure f: () -> Int32, context: String = "") throws {
    while true {
        let errno = f()
        if errno == EINTR {
            continue
        }
        if errno < 0 {
            let message = String.fromCString(strerror(errno))!
            throw ExecuteError.Error(errno, "\(context): \(message)")
        }
        break
    }
}

private func throwIfGlobalError(@autoclosure f: () -> Int32, context: String = "error") throws {
    while true {
        if f() < 0 {
            let n = errno
            if n == EINTR {
                continue
            }
            let message = String.fromCString(strerror(n))!
            throw ExecuteError.Error(n, "\(context): \(message)")
        }
        break
    }
}

public class ProcessState {
    private let process: Process

    // The PID of the process.
    public var pid: Int { return process.pid }

    private init(process: Process) {
        self.process = process
    }

    public func wait() throws -> (Int, String) {
        return try process.wait()
    }

    public func kill() throws {
        return try process.kill()
    }
}

// Execute a Process.
public class Process {
    private let lock = NSLock()
    private let command: [String]
    private let environ: [String:String]
    private let cwd: String?

    private var outpipe: UnsafeMutablePointer<Int32>!
    private var action: UnsafeMutablePointer<posix_spawn_file_actions_t>!
    private var cpid: UnsafeMutablePointer<pid_t>!
    private var argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>!
    private var argvCStrings: [[CChar]]!
    private var env: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>!
    private var envCStrings: [[CChar]]!

    private var _output = ""
    private var _status = -1
    private var error: ErrorType?

    private func locked<T>(@noescape f: () throws -> T) throws -> T {
        lock.lock()
        let v = try f()
        lock.unlock()
        return v
    }

    private func locked<T>(@noescape f: () -> T) -> T {
        lock.lock()
        let v = f()
        lock.unlock()
        return v
    }

    public var pid: Int {
        return locked { Int(cpid[0]) }
    }

    // Execute a command and return its combined stdout and stderr.
    public init(command: [String], cwd: String? = nil) throws {
        self.command = command
        self.environ = NSProcessInfo().environment
        self.cwd = cwd

        outpipe = UnsafeMutablePointer.alloc(2)
        outpipe.initialize(-1)
        try throwIfGlobalError(pipe(outpipe), context: "pipe()")

        action = UnsafeMutablePointer.alloc(1)
        try throwIfError(posix_spawn_file_actions_init(action), context: "posix_spawn_file_actions_init()")
        try throwIfError(posix_spawn_file_actions_addclose(action, outpipe[0]), context: "close(pipe[0])")
        try throwIfError(posix_spawn_file_actions_adddup2(action, outpipe[1], 1), context: "dup2(pipe[1], 1)")
        try throwIfError(posix_spawn_file_actions_adddup2(action, outpipe[1], 2), context: "dup2(pipe[1], 2)")
        try throwIfError(posix_spawn_file_actions_addclose(action, outpipe[1]), context: "close(pipe[1])")

        cpid = UnsafeMutablePointer.alloc(1)

        argv = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(command.count + 1)
        argv[command.count] = nil
        argvCStrings = command.map({$0.cStringUsingEncoding(NSUTF8StringEncoding)!})
        for var i = 0; i < command.count; i++ {
            argv[i] = UnsafeMutablePointer<Int8>(argvCStrings[i])
        }

        env = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(environ.count + 1)
        env[environ.count] = nil
        envCStrings = environ.map({(k, v) in "\(k)=\(v)".cStringUsingEncoding(NSUTF8StringEncoding)!})
        for var i = 0; i < environ.count; i++ {
            env[i] = UnsafeMutablePointer<Int8>(envCStrings[i])
        }
    }

    deinit {
        guard let env = self.env else { return }
        env.dealloc(1)

        guard let argv = self.argv else { return }
        argv.dealloc(command.count + 1)

        guard let pid = self.cpid else { return }
        pid.dealloc(1)

        guard let action = self.action else { return }
        posix_spawn_file_actions_destroy(action)
        action.dealloc(1)

        close(outpipe[0])
        close(outpipe[1])
        outpipe.dealloc(2)
    }

    // Start the process in the background.
    public func launch() throws -> ProcessState {
        // TODO: Global lock around changing directory. Annoying.
        let oldwd = UnsafeMutablePointer<Int8>.alloc(8192)
        defer { oldwd.dealloc(8192) }
        getcwd(oldwd, 8192)
        if let cwd = self.cwd {
            chdir(cwd)
        }

        try throwIfError(posix_spawnp(cpid, argv[0], action, nil, argv, env), context: "posix_spawnp()")

        if cwd != nil {
            chdir(oldwd)
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                try self.run()
            } catch let e {
                self.locked { self.error = e }
            }
        })
        return ProcessState(process: self)
    }

    // Synchronously execute the task, wait for completion and return the exit status and output.
    public func execute() throws -> (Int, String) {
        return try launch().wait()
    }

    private func run() throws {
        var out = ""
        let buffer = UnsafeMutablePointer<Int8>.alloc(1025)
        defer { buffer.dealloc(1025) }
        close(outpipe[1])
        while true {
            let n = read(outpipe[0], buffer, 1024)
            if n < 0 {
                let err = errno
                if err == EINTR {
                    continue
                }
                try throwIfError(err, context: "read()")
            }
            if n == 0 {
                break
            }
            buffer[n] = 0 // Zero-terminate the string.
            let chunk = String.fromCString(buffer)
            out.appendContentsOf(chunk!)
        }
        locked {
            self._output = out
        }
    }

    private func kill() throws {
        try throwIfGlobalError(Darwin.kill(cpid[0], SIGTERM), context: "kill()")
    }

    private func wait() throws -> (Int, String) {
        let status = UnsafeMutablePointer<Int32>.alloc(1)
        defer { status.dealloc(1) }
        let pid = cpid[0]
        try throwIfGlobalError(waitpid(pid, status, 0), context: "waitpid()")
        return try locked {
            if let error = self.error {
                throw error
            }
            let rc = Int(status[0])
            let out = _output
            return (rc, out)
        }
    }
}

public func execute(command: [String], cwd: String? = nil) throws -> (Int, String) {
    let process = try Process(command: command, cwd: cwd)
    return try process.execute()
}
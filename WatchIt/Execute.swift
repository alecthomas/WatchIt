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

// Execute a command and return its combined stdout and stderr.
public func execute(command: [String], cwd: String? = nil) throws -> (Int, String) {
    let outpipe = UnsafeMutablePointer<Int32>.alloc(2)
    defer { outpipe.dealloc(2) }
    try throwIfGlobalError(pipe(outpipe), context: "pipe()")


    defer {
        close(outpipe[0])
        close(outpipe[1])
    }

    let action = UnsafeMutablePointer<posix_spawn_file_actions_t>.alloc(1)
    defer {
        posix_spawn_file_actions_destroy(action)
        action.dealloc(1)
    }
    try throwIfError(posix_spawn_file_actions_init(action), context: "posix_spawn_file_actions_init()")
    try throwIfError(posix_spawn_file_actions_addclose(action, outpipe[0]), context: "close(pipe[0])")
    try throwIfError(posix_spawn_file_actions_adddup2(action, outpipe[1], 1), context: "dup2(pipe[1], 1)")
    try throwIfError(posix_spawn_file_actions_adddup2(action, outpipe[1], 2), context: "dup2(pipe[1], 2)")
    try throwIfError(posix_spawn_file_actions_addclose(action, outpipe[1]), context: "close(pipe[1])")

    let pid = UnsafeMutablePointer<pid_t>.alloc(1)
    defer { pid.dealloc(1) }

    let argv = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(command.count + 1)
    defer { argv.dealloc(command.count + 1) }
    let argvCStrings = command.map({$0.cStringUsingEncoding(NSUTF8StringEncoding)!})
    for var i = 0; i < command.count; i++ {
        argv[i] = UnsafeMutablePointer<Int8>(argvCStrings[i])
    }
    argv[command.count] = nil

    let env = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(1)
    defer { env.dealloc(1) }
    env[0] = nil

    // TODO: Global lock around changing directory. Annoying.
    let oldwd = UnsafeMutablePointer<Int8>.alloc(8192)
    defer { oldwd.dealloc(8192) }
    getcwd(oldwd, 8192)
    if let cwd = cwd {
        chdir(cwd)
    }

    try throwIfError(posix_spawnp(pid, argv[0], action, nil, argv, env), context: "posix_spawnp()")

    if cwd != nil {
        chdir(oldwd)
    }

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
    let status = UnsafeMutablePointer<Int32>.alloc(1)
    defer { status.dealloc(1) }
    try throwIfGlobalError(waitpid(pid[0], status, 0), context: "waitpid()")
    return (Int(status[0]), out)
}
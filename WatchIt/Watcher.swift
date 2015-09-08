//
//  Watcher.swift
//  WatchIt
//
//  Created by Alec Thomas on 7/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import EonilFileSystemEvents

public class Watcher {
    private var model: Model
    private var monitor: FileSystemEventMonitor?

    public init(model: Model) {
        self.model = model
        self.update()
    }

    public func update() {
        let paths: [String] = self.model.watches.map({w in w.directory.stringByExpandingTildeInPath})
        log.info("Watching \(paths)")
        self.monitor = FileSystemEventMonitor(
            pathsToWatch: paths,
            latency: 5,
            watchRoot: true,
            queue: dispatch_get_main_queue(),
            callback: self.onFSEvents
            )
    }

    func onFSEvents(events:[FileSystemEvent]) {
        for event in events {
            print(event)
        }
    }
}
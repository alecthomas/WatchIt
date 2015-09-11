//
//  Watcher.swift
//  WatchIt
//
//  Created by Alec Thomas on 7/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import EonilFileSystemEvents
import RxSwift

// Monitors Watched directories for matching changes.
public class Watcher {
    private var model: Model
    private var monitor: FileSystemEventMonitor?

    private let changesPublisher = PublishSubject<[String:[String]]>()

    public let changes: RxSwift.Observable<[String:[String]]>

    public init(model: Model) {
        self.changes = changesPublisher.throttle(1.0, MainScheduler.sharedInstance)
        self.model = model
        self.model.watches.anyChange
            .throttle(1.0, MainScheduler.sharedInstance)
            .subscribeNext(self.update)
        self.update()
    }

    public func update() {
        let paths: [String] = self.model.watches.filter({$0.valid()}).map({$0.realPath})
        log.info("Watching \(paths)")
        self.monitor = FileSystemEventMonitor(
            pathsToWatch: paths,
            latency: 5,
            watchRoot: true,
            queue: dispatch_get_main_queue(),
            callback: self.onFSEvents
            )
    }

    private func onFSEvents(events:[FileSystemEvent]) {
        var triggered: [String:[String]] = [:]
        for event in events {
            for watch in self.model.watches {
                if event.path.hasPrefix(watch.realPath) &&  glob(watch.glob.value, path: event.path) {
                    var paths = triggered[watch.name.value] ?? [String]()
                    paths.append(event.path)
                    triggered[watch.name.value] = paths
                }
            }
        }
        if !triggered.isEmpty {
            changesPublisher.on(.Next(triggered))
        }
    }
}
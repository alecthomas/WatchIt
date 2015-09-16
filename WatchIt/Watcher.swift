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
    private var watches: [Watch] = []

    private let changesPublisher = PublishSubject<Watch>()
    private let filesystemEventsPublisher = PublishSubject<FileSystemEvent>()

    public let changes: Observable<Watch>
    public let filesystemEvents: Observable<FileSystemEvent>

    public init(model: Model) {
        self.changes = changesPublisher
            .throttle(2.0, MainScheduler.sharedInstance)
        self.filesystemEvents = filesystemEventsPublisher
        self.model = model

        // Trigger changes when the collection changes.
        // Invalid watches are ignored.
        sequenceOf(
            // Trigger whenever an existing field is changed (ignoring .name)
            self.model.watches.elementChanged
                .filter({(_, f) in f != "name"})
                .map({(w, _) in w}),
            // Trigger whenever new watches are added.
            self.model.watches.collectionChanged
                .map({event -> [Watch] in
                    if case let .Added(_, elements) = event {
                        return elements
                    }
                    return []
                })
                .flatMap({elements in elements.asObservable()})
            )
            .merge()
            .filter({w in w.valid()})
            .bindTo(changesPublisher)

        // Update the file system monitor when the collection changes.
        self.model.watches.anyChange
            .throttle(1.0, MainScheduler.sharedInstance)
            .subscribeNext(self.onModelChange)

        self.onModelChange()
    }

    public func onModelChange() {
        watches = self.model.watches.filter({$0.valid()})
        let paths: [String] = watches.map({$0.realPath})
        if paths.isEmpty {
            log.warning("nothing to watch")
            self.monitor = nil
        } else {
            log.info("Watching \(paths)")
            self.monitor = FileSystemEventMonitor(
                pathsToWatch: paths,
                latency: 1,
                watchRoot: true,
                queue: dispatch_get_main_queue(),
                callback: self.onFSEvents
            )
        }
    }

    private func onFSEvents(events:[FileSystemEvent]) {
        for watch in watches {
            for event in events {
                filesystemEventsPublisher.on(.Next(event))
                if event.path.hasPrefix(watch.realPath) &&  glob(watch.glob.value, path: event.path) {
                    changesPublisher.on(.Next(watch))
                    break
                }
            }
        }
    }
}
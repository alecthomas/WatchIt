//
//  PreferencesWindowViewModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 9/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import Cocoa
import Bond


// ViewModel for the preferences window detail view.
public class PreferencesDetailViewModel: NSObject, NSTableViewDataSource {
    public let watch = Watch()
    // Selected preset changed.
    public let preset = Observable<Preset?>(nil)
    // Watch fields that correspond to preset fields.
    public let presetFields: EventProducer<(String, String, String)>

    public override init() {
        presetFields = combineLatest(watch.glob, watch.command, watch.pattern)
        super.init()
        preset
            .filter({p in p != nil})
            .map({p in p!})
            .observeNew({preset in
                self.watch.glob.value = preset.glob.value
                self.watch.command.value = preset.command.value
                self.watch.pattern.value = preset.pattern.value
            })
        presetFields
            .observeNew({(glob, command, pattern) in
                let selected = model.presetForWatch(self.watch)
                if self.preset.value != selected {
                    self.preset.value = selected
                }
            })
    }

    private let disposable = DisposeBag()

    public func bind(watchIndex: Int) {
        disposable.dispose()
        let watch = model.watches[watchIndex]
        watch.name.bidirectionalBindTo(self.watch.name).disposeIn(disposable)
        watch.directory.bidirectionalBindTo(self.watch.directory).disposeIn(disposable)
        watch.glob.bidirectionalBindTo(self.watch.glob).disposeIn(disposable)
        watch.command.bidirectionalBindTo(self.watch.command).disposeIn(disposable)
        watch.pattern.bidirectionalBindTo(self.watch.pattern).disposeIn(disposable)
    }

    public func unbind() {
        disposable.dispose()
        self.watch.reset()
    }

    public func addWatch() {
        let watch = Watch()
        watch.name.value = "Name"
        model.watches.append(watch)
    }

    public func removeWatch(index: Int) {
        model.watches.removeAtIndex(index)
    }

    public func hasPresets() -> Bool {
        return !model.presets.isEmpty
    }

    // NSTableViewDataSource implementation.
    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return model.watches.count
    }

    public func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch tableColumn!.identifier {
        case "name":
            return model.watches[row].name.value
        default:
            return "?"
        }
    }

    public func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        switch tableColumn!.identifier {
        case "name":
            model.watches[row].name.value = object as! String
        default:
            break
        }
    }
}

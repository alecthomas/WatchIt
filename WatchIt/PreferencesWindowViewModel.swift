//
//  PreferencesWindowViewModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 9/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift


// ViewModel for the preferences window detail view.
public class PreferencesDetailViewModel: NSObject, NSTableViewDataSource {
    public let watch = Watch()
    // Selected preset changed.
    public let preset = Value<Preset?>(nil)
    // Watch fields that correspond to preset fields.
    public let presetFields: Observable<(String, String, String)>

    public override init() {
        presetFields = combineLatest(watch.glob.asObservable(), watch.command.asObservable(), watch.pattern.asObservable(), {($0, $1, $2)})
        super.init()
        preset
            .filter({p in p != nil})
            .map({p in p!})
            .subscribeNext({preset in
                self.watch.glob.value = preset.glob.value
                self.watch.command.value = preset.command.value
                self.watch.pattern.value = preset.pattern.value
            })
        presetFields
            .throttle(0.1, MainScheduler.sharedInstance)
            .subscribeNext({(glob, command, pattern) in
                let selected = model.presetForWatch(self.watch)
                if self.preset.value != selected {
                    self.preset.value = selected
                }
            })
    }

    private var bag = DisposeBag()

    // Bind to the nth watch.
    public func bind(watchIndex: Int) {
        bag = DisposeBag()
        let watch = model.watches[watchIndex]
        watch.name.bidirectionalBindTo(self.watch.name).addDisposableTo(bag)
        watch.directory.bidirectionalBindTo(self.watch.directory).addDisposableTo(bag)
        watch.glob.bidirectionalBindTo(self.watch.glob).addDisposableTo(bag)
        watch.command.bidirectionalBindTo(self.watch.command).addDisposableTo(bag)
        watch.pattern.bidirectionalBindTo(self.watch.pattern).addDisposableTo(bag)
    }

    public func unbind() {
        bag = DisposeBag()
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

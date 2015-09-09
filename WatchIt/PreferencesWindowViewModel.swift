//
//  PreferencesWindowViewModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 9/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import Bond


// ViewModel for the preferences window detail view.
class PreferencesDetailViewModel {
    var watch = Watch()
    // Selected preset changed.
    var preset = Observable<Preset?>(nil)
    // Watch fields that correspond to preset fields.
    var presetFields: EventProducer<(String, String, String)>

    init() {
        presetFields = combineLatest(watch.glob, watch.command, watch.pattern)
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

    private var disposable = DisposeBag()

    func bind(watch: Watch) {
        disposable.dispose()
        watch.name.bidirectionalBindTo(self.watch.name).disposeIn(disposable)
        watch.directory.bidirectionalBindTo(self.watch.directory).disposeIn(disposable)
        watch.glob.bidirectionalBindTo(self.watch.glob).disposeIn(disposable)
        watch.command.bidirectionalBindTo(self.watch.command).disposeIn(disposable)
        watch.pattern.bidirectionalBindTo(self.watch.pattern).disposeIn(disposable)
    }

    func unbind() {
        disposable.dispose()
        self.watch.reset()
    }
}

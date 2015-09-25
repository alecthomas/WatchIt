//
//  WatcherSettingsController.swift
//  WatchIt
//
//  Created by Wes Billman on 9/23/15.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class WatcherSettingsController: NSWindowController {

    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var directoryTextField: NSTextField!
    @IBOutlet weak var globTextField: NSTextField!
    @IBOutlet weak var commandTextField: NSTextField!
    @IBOutlet weak var patternTextField: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var browseButton: NSButton!
    @IBOutlet weak var presetPopUp: NSPopUpButton!
    
    private let disposeBag = DisposeBag()
    var newWatch = false
    var watch:Watch!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if watch == nil {
            watch = Watch()
            newWatch = true
        }
        
        watch.valid.subscribeNext { valid in self.okButton.enabled = valid }

        nameTextField.becomeFirstResponder()
        watch.name.bidirectionalBindTo(nameTextField).addDisposableTo(disposeBag)
        watch.directory.bidirectionalBindTo(directoryTextField).addDisposableTo(disposeBag)
        watch.glob.bidirectionalBindTo(globTextField).addDisposableTo(disposeBag)
        watch.command.bidirectionalBindTo(commandTextField).addDisposableTo(disposeBag)
        watch.pattern.bidirectionalBindTo(patternTextField).addDisposableTo(disposeBag)
        
        //for handling "return" key
        commandTextField.delegate = self
        patternTextField.delegate = self
        
        watch.directory
            .subscribeNext({text in
                self.directoryTextField.textColor = self.watch.validPath() ? NSColor.textColor() : NSColor.redColor()
            })
            .addDisposableTo(disposeBag)
        
        presetPopUp.rx_controlEvents
            .map {self.presetPopUp.indexOfSelectedItem}
            .filter {i in i > 0}
            .map {i in model.presets[i - 1]}
            .subscribeNext { preset in
                print(preset)
                self.watch.setPreset(preset)
            }
            .addDisposableTo(disposeBag)
        
        okButton.rx_tap.subscribeNext {
                self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
            }
        cancelButton.rx_tap.subscribeNext {
                self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseCancel)
            }
        browseButton.rx_tap.subscribeNext { self.browseDirectory() }
        
        updatePresets()
        if let preset = model.presetForId(watch.preset.value) {
            for item in presetPopUp.itemArray {
                if item.title == preset.name.value {
                    presetPopUp.selectItem(item)
                }
            }
        }

    }

    private func browseDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.directoryURL = NSURL(fileURLWithPath: self.directoryTextField.stringValue.stringByExpandingTildeInPath)
        openPanel.title = "Directory to watch"
        openPanel.resolvesAliases = false
        openPanel.beginSheetModalForWindow(self.window!, completionHandler: {v in
            if v == NSModalResponseOK, let path: String = openPanel.URL?.path {
                self.watch.directory.value = path.stringByReplacingHomeWithTilde
            }
        })
    }
    
    private func updatePresets() {
        presetPopUp.removeAllItems()
        let titles = [""] + model.presets.map({p in p.name.value})
        presetPopUp.addItemsWithTitles(titles)
        presetPopUp.autoenablesItems = false
        presetPopUp.itemAtIndex(0)?.enabled = false
    }
    
    private func confirmPreset(preset: Preset) {
        let alert = NSAlert()
        alert.addButtonWithTitle("Cancel")
        alert.addButtonWithTitle("Ok")
        alert.messageText = "Replace existing configuration with preset?"
        alert.informativeText = "This will replace your existing glob, command and pattern."
        alert.alertStyle = .WarningAlertStyle
        alert.beginSheetModalForWindow(window!, completionHandler: {response in
            if response == NSAlertSecondButtonReturn {
//                self.viewModel.preset.value = preset
            } else {
//                self.viewModel.preset.value = nil
                //                self.presetField.selectItemAtIndex(0)
            }
        })
    }

}

extension WatcherSettingsController : NSTextFieldDelegate {
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        var result = false
        if commandSelector == Selector("insertNewline:") {
            textView.insertNewlineIgnoringFieldEditor(self)
            result = true
        }
        return result
    }
}


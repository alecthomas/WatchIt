//
//  PreferencesWindow.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Cocoa
import Bond

class WatchesTableDataSource: NSObject, NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return model.watches.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch tableColumn!.identifier {
        case "name":
            return model.watches[row].name.value
        default:
            return "?"
        }
    }

    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        switch tableColumn!.identifier {
        case "name":
            model.watches[row].name.value = object as! String
        default:
            break
        }
    }
}


class PreferencesWindow: NSWindowController, NSTableViewDelegate, NSMenuDelegate, NSTextFieldDelegate  {
    var dataSource = WatchesTableDataSource()

    @IBOutlet weak var controlGroup: NSView!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var dirField: NSTextField!
    @IBOutlet weak var dirDialog: NSButton!
    @IBOutlet weak var presetField: NSPopUpButton!
    @IBOutlet weak var globField: NSTextField!
    @IBOutlet weak var commandField: NSTextField!
    @IBOutlet weak var patternField: NSTextField!

    @IBOutlet weak var tableView: NSTableView!

    var detail = PreferencesDetailViewModel()
    var presetTextColor = Observable<NSColor>(NSColor.textColor())

    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.setDelegate(self)
        tableView.setDataSource(dataSource)

        // Tab cycle order.
        window?.initialFirstResponder = nameField
        nameField.nextKeyView = dirField
        dirField.nextKeyView = presetField
        presetField.nextKeyView = globField
        globField.nextKeyView = commandField
        commandField.nextKeyView = patternField
        patternField.nextKeyView = nameField

        // Allow insertion of newlines
        commandField.delegate = self
        patternField.delegate = self

        updatePresets()

        self.enabled = false

        window?.center()

        // Update preset field color when this is set...
        // It's surprising that Bond doesn't have a way to one-way bind to non-Observables.
        presetTextColor.observeNew({color in
            self.globField.textColor = color
            self.commandField.textColor = color
            self.patternField.textColor = color
        })

        model.watches.observeNew(onWatchesChanged)
        model.presets.observeNew(onPresetsChanged)

        detail.watch.name.bidirectionalBindTo(nameField.bnd_text)
        detail.watch.directory.bidirectionalBindTo(dirField.bnd_text)
        detail.watch.glob.bidirectionalBindTo(globField.bnd_text)
        detail.watch.command.bidirectionalBindTo(commandField.bnd_text)
        detail.watch.pattern.bidirectionalBindTo(patternField.bnd_text)

        nameField.bnd_text
            .observeNew({_ in
                self.tableView.reloadData()
            })

        dirField.bnd_text
            .observeNew({text in
                var isDir: ObjCBool = false
                if NSFileManager.defaultManager().fileExistsAtPath(text.stringByExpandingTildeInPath, isDirectory: &isDir) && isDir {
                    self.dirField.textColor = NSColor.textColor()
                } else {
                    self.dirField.textColor = NSColor.redColor()
                }
            })

        // Update preset drop-down when preset fields change.
        detail.presetFields
            .observeNew({(glob, command, pattern) in
                if let preset = model.presetForWatch(self.detail.watch) {
                    self.presetField.selectItemWithTitle(preset.name.value)
                    self.presetTextColor.value = NSColor.grayColor()
                } else {
                    self.presetField.selectItemAtIndex(0)
                    self.presetTextColor.value = NSColor.textColor()
                }
                if !Regex.valid(pattern) {
                    self.patternField.textColor = NSColor.redColor()
                }
            })

        // Update model when preset changes.
        presetField.bnd_controlEvent
            .map({event in (event as! Int) - 1})
            .filter({index in index >= 0})
            .observeNew({index in
                if self.detail.preset.value == nil {
                    self.confirmPreset(model.presets[index])
                } else {
                    self.detail.preset.value = model.presets[index]
                }
            })
    }

    func updatePresets() {
        let selected = presetField.indexOfSelectedItem
        presetField.removeAllItems()
        let titles = [""] + model.presets.map({p in p.name.value})
        presetField.addItemsWithTitles(titles)
        presetField.menu?.delegate = self
        presetField.autoenablesItems = false
        presetField.itemAtIndex(0)?.enabled = false
        if selected < 0 || selected >= presetField.numberOfItems {
            presetField.selectItemAtIndex(0)
        } else {
            presetField.selectItemAtIndex(selected)
        }
    }

    func onPresetsChanged(event: ObservableArrayEvent<[Preset]>) {
        updatePresets()
    }

    func onWatchesChanged(event: ObservableArrayEvent<[Watch]>) {
        tableView.reloadData()
        switch event.operation {
        case let .Insert(elements, index):
            tableView.selectRowIndexes(NSIndexSet(index: index + elements.count - 1), byExtendingSelection: false)
        case let .Remove(range):
            if range.contains(tableView.selectedRow) {
                tableView.deselectAll(self)
            }
        default:
            log.error("watches should be added and removed")
        }
    }

    @IBAction func onClose(sender: AnyObject) {
        self.close()
    }

    @IBAction func onAdd(sender: AnyObject) {
        let watch = Watch()
        watch.name.value = "Name"
        model.watches.append(watch)
    }

    @IBAction func onRemove(sender: AnyObject) {
        for (offset, row) in tableView.selectedRowIndexes.enumerate() {
            model.watches.removeAtIndex(row - offset)
        }
    }

    @IBAction func onDirDialog(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.directoryURL = NSURL(fileURLWithPath: self.dirField.stringValue.stringByExpandingTildeInPath)
        openPanel.title = "Directory to watch"
        openPanel.resolvesAliases = false
        openPanel.beginSheetModalForWindow(self.window!, completionHandler: {v in
            if v == NSModalResponseOK, let path: String = openPanel.URL?.path {
                self.detail.watch.directory.value = path.stringByReplacingHomeWithTilde
            }
        })
    }

    var enabled: Bool {
        get { return controlGroup.enabledSubViews }
        set(enable) {
            controlGroup.enabledSubViews = enable
            presetField.enabled = model.presets.isEmpty ? false : enable
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        let index = tableView.selectedRow
        if index != -1 {
            detail.bind(model.watches[index])
        } else {
            detail.unbind()
        }
        self.enabled = index != -1
        if self.enabled {
            nameField.becomeFirstResponder()
        }
    }

    func confirmPreset(preset: Preset) {
        let alert = NSAlert()
        alert.addButtonWithTitle("Cancel")
        alert.addButtonWithTitle("Ok")
        alert.messageText = "Replace existing configuration with preset?"
        alert.informativeText = "This will replace your existing glob, command and pattern."
        alert.alertStyle = .WarningAlertStyle
        alert.beginSheetModalForWindow(window!, completionHandler: {response in
            if response == NSAlertSecondButtonReturn {
                self.detail.preset.value = preset
            } else {
                self.detail.preset.value = nil
                self.presetField.selectItemAtIndex(0)
            }
        })
    }

    // Override enter key so it actually inserts a newline...
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        var result = false
        if commandSelector == Selector("insertNewline:") {
            textView.insertNewlineIgnoringFieldEditor(self)
            result = true
//        } else if commandSelector == Selector("insertTab:") {
//            textView.insertTabIgnoringFieldEditor(self)
//            result = true
        }
        return result
    }
}

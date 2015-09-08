//
//  PreferencesWindow.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Cocoa

class WatchesTableDataSource: NSObject, NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return model.watches.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch tableColumn!.identifier {
        case "name":
            return model.watches[row].name
        default:
            return "?"
        }
    }

    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        switch tableColumn!.identifier {
        case "name":
            model.watches[row].name = object as! String
        default:
            break
        }
    }
}

class PreferencesWindow: NSWindowController, NSTableViewDelegate, NSTextFieldDelegate, NSMenuDelegate  {
    var dataSource = WatchesTableDataSource()

    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var dirField: NSTextField!
    @IBOutlet weak var dirDialog: NSButton!
    @IBOutlet weak var presetField: NSPopUpButton!
    @IBOutlet weak var globField: NSTextField!
    @IBOutlet weak var commandField: NSTextField!
    @IBOutlet weak var patternField: NSTextField!

    @IBOutlet weak var tableView: NSTableView!

    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.setDelegate(self)
        tableView.setDataSource(dataSource)

        nameField.delegate = self
        dirField.delegate = self
        globField.delegate = self
        commandField.delegate = self
        patternField.delegate = self

        // Tab cycle order.
        window?.initialFirstResponder = nameField
        nameField.nextKeyView = dirField
        dirField.nextKeyView = presetField
        presetField.nextKeyView = globField
        globField.nextKeyView = commandField
        commandField.nextKeyView = patternField
        patternField.nextKeyView = nameField

        updatePresets()

        self.enabled = false

        window?.center()

        model.watches.collectionChanged.subscribe(onWatchesChanged)
        model.presets.collectionChanged.subscribe(onPresetsChanged)
    }

    func updatePresets() {
        let selected = presetField.indexOfSelectedItem
        presetField.removeAllItems()
        let titles = [""] + model.presets.map({p in p.name})
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

    func onPresetsChanged(event: ObservableCollectionChangedEvent<Preset>) {
        updatePresets()
    }

    func onWatchesChanged(event: ObservableCollectionChangedEvent<Watch>) {
        onChange()
        switch event {
        case let .Added(range, _):
            tableView.selectRowIndexes(NSIndexSet(index: range.startIndex), byExtendingSelection: false)
        case let .Removed(range, _):
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
        watch.name = "Name"
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
                self.selectedWatch?.directory = path.stringByReplacingHomeWithTilde
                self.dirField.stringValue = path.stringByReplacingHomeWithTilde
                self.onChange()
            }
        })
    }

    var selectedWatch: Watch? {
        if tableView.selectedRow == -1 || tableView.selectedRow >= model.watches.count {
            return nil
        }
        return model.watches[tableView.selectedRow]
    }

    var enabled: Bool {
        get { return nameField.enabled }
        set(enable) {
            nameField.enabled = enable
            dirField.enabled = enable
            presetField.enabled = model.presets.isEmpty ? false : enable
            globField.enabled = enable
            commandField.enabled = enable
            patternField.enabled = enable
            dirDialog.enabled = enable
        }
    }

    func onChange() {
        tableView.reloadData()
        let watch = selectedWatch ?? Watch()
        nameField.stringValue = watch.name
        dirField.stringValue = watch.directory
        globField.stringValue = watch.glob
        commandField.stringValue = watch.command
        patternField.stringValue = watch.pattern
        if let preset = model.presetForWatch(watch) {
            presetField.selectItemWithTitle(preset.name)
            globField.textColor = NSColor.grayColor()
            commandField.textColor = NSColor.grayColor()
            patternField.textColor = NSColor.grayColor()
        } else {
            presetField.selectItemAtIndex(0)
            globField.textColor = NSColor.textColor()
            commandField.textColor = NSColor.textColor()
            patternField.textColor = NSColor.textColor()
        }
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(dirField.stringValue.stringByExpandingTildeInPath, isDirectory: &isDir) && isDir {
            dirField.textColor = NSColor.textColor()
        } else {
            dirField.textColor = NSColor.redColor()
        }
        if !Regex.valid(watch.pattern) {
            patternField.textColor = NSColor.redColor()
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        let index = tableView.selectedRow
        onChange()
        self.enabled = index != -1
        if self.enabled {
            nameField.becomeFirstResponder()
        }
    }

    override func controlTextDidChange(obj: NSNotification) {
        guard let watch = selectedWatch else { return }
        guard let field = obj.object as? NSTextField else { return }
        switch field.identifier! {
        case "name":
            watch.name = field.stringValue
        case "directory":
            watch.directory = field.stringValue
        case "glob":
            watch.glob = field.stringValue
        case "command":
            watch.command = field.stringValue
        case "pattern":
            watch.pattern = field.stringValue
        default:
            break
        }
        onChange()
    }

    @IBAction func onPreset(sender: AnyObject) {
        if model.presets.isEmpty {
            return
        } else if let watch = selectedWatch {
            if presetField.indexOfSelectedItem == 0 {
                if let index = model.presets.indexOf({p in p ~= watch}) {
                    presetField.selectItemAtIndex(index+1)
                } else {
                    presetField.selectItemAtIndex(0)
                }
                return
            }
            let preset = model.presets[presetField.indexOfSelectedItem - 1]
            // Matches an existing preset, just replace it without notifying.
            if watch.emptyPreset || model.presetForWatch(watch) != nil {
                updateWithPreset(preset)
            } else {
                confirmPreset(preset)
            }
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
                self.updateWithPreset(preset)
            } else {
                self.presetField.selectItemAtIndex(0)
            }
        })
    }

    func updateWithPreset(preset: Preset) {
        if let watch = selectedWatch {
            watch.glob = preset.glob
            watch.command = preset.command
            watch.pattern = preset.pattern
            onChange()
        }
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

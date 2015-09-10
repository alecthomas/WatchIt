//
//  PreferencesWindow.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class PreferencesWindow: NSWindowController, NSTableViewDelegate, NSMenuDelegate, NSTextFieldDelegate  {
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
    var presetTextColor = Value<NSColor>(NSColor.textColor())
    var bag = DisposeBag()

    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.setDelegate(self)
        tableView.setDataSource(detail)

        // Tab cycle order.
        window?.initialFirstResponder = nameField
        nameField.nextKeyView = dirField
        dirField.nextKeyView = presetField
        presetField.nextKeyView = globField
        globField.nextKeyView = commandField
        commandField.nextKeyView = patternField
        patternField.nextKeyView = nameField

        // Allow insertion of newlines
        nameField.delegate = self
        dirField.delegate = self
        globField.delegate = self
        commandField.delegate = self
        patternField.delegate = self

        updatePresets()

        self.enabled = false

        window?.center()

        // Update preset field color when this is set...
        presetTextColor
            .subscribeNext({color in
                self.globField.textColor = color
                self.commandField.textColor = color
                self.patternField.textColor = color
            })
            .addDisposableTo(bag)

        model.watches.collectionChanged.subscribeNext(onWatchesChanged).addDisposableTo(bag)
        model.presets.collectionChanged.subscribeNext(onPresetsChanged).addDisposableTo(bag)

        detail.watch.name.bidirectionalBindTo(nameField).addDisposableTo(bag)
        detail.watch.directory.bidirectionalBindTo(dirField).addDisposableTo(bag)
        detail.watch.glob.bidirectionalBindTo(globField).addDisposableTo(bag)
        detail.watch.command.bidirectionalBindTo(commandField).addDisposableTo(bag)
        detail.watch.pattern.bidirectionalBindTo(patternField).addDisposableTo(bag)

        nameField.rx_text
            .subscribeNext({_ in
                self.tableView.reloadData()
            })
            .addDisposableTo(bag)

        dirField.rx_text
            .subscribeNext({text in
                var isDir: ObjCBool = false
                let dir = text.stringByExpandingTildeInPath
                if dir == "" || (NSFileManager.defaultManager().fileExistsAtPath(dir, isDirectory: &isDir) && isDir) {
                    self.dirField.textColor = NSColor.textColor()
                } else {
                    self.dirField.textColor = NSColor.redColor()
                }
            })
            .addDisposableTo(bag)

        // Update preset drop-down when preset fields change.
        detail.presetFields
            .subscribeNext({(glob, command, pattern) in
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
            .addDisposableTo(bag)

        // Update model when preset changes.
        presetField.rx_controlEvents
            .map({self.presetField.indexOfSelectedItem})
            .filter({i in i > 0})
            .map({i in model.presets[i - 1]})
            .subscribeNext({preset in
                if self.detail.preset.value == nil {
                    self.confirmPreset(preset)
                } else {
                    self.detail.preset.value = preset
                }
            })
            .addDisposableTo(bag)
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

    func onPresetsChanged(event: ObservableCollectionEvent<Preset>) {
        updatePresets()
    }

    func onWatchesChanged(event: ObservableCollectionEvent<Watch>) {
        tableView.reloadData()
        switch event {
        case let .Added(range, _):
            tableView.selectRowIndexes(NSIndexSet(index: range.endIndex), byExtendingSelection: false)
        case let .Removed(range, _):
            if range.contains(tableView.selectedRow) {
                tableView.deselectAll(self)
            }
        }
    }

    @IBAction func onClose(sender: AnyObject) {
        self.close()
    }

    @IBAction func onAdd(sender: AnyObject) {
        detail.addWatch()
    }

    @IBAction func onRemove(sender: AnyObject) {
        for (offset, row) in tableView.selectedRowIndexes.enumerate() {
            detail.removeWatch(row - offset)
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
            presetField.enabled = !detail.hasPresets() ? false : enable
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        let index = tableView.selectedRow
        if index != -1 {
            detail.bind(index)
        } else {
            detail.unbind()
        }
        self.enabled = index != -1
        if self.enabled {
            nameField.becomeFirstResponder()
        }
    }

    override func controlTextDidChange(obj: NSNotification) {
        guard let field = obj.object as? NSTextField else { return }
        switch field.identifier! {
        case "name":
            detail.watch.name.value = field.stringValue
        case "directory":
            detail.watch.directory.value = field.stringValue
        case "glob":
            detail.watch.glob.value = field.stringValue
        case "command":
            detail.watch.command.value = field.stringValue
        case "pattern":
            detail.watch.pattern.value = field.stringValue
        default:
            break
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

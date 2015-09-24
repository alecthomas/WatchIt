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

class PreferencesWindow: NSWindowController, NSMenuDelegate  {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var controlsView: NSView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    
    var viewModel = PreferencesDetailViewModel()
    var presetTextColor = Value(NSColor.textColor())
    var bag = DisposeBag()

    override func windowDidLoad() {
        super.windowDidLoad()

        tableView.setDelegate(self)
        tableView.setDataSource(viewModel)

        window?.center()

        model.watches.collectionChanged.subscribeNext(onWatchesChanged).addDisposableTo(bag)

        viewModel.watch.name
            .subscribeNext({name in
                self.nameLabel.stringValue = name
            })
            .addDisposableTo(bag)
        viewModel.watch.output
            .subscribeNext({output in
                // Smart Scrolling
                let scroll = NSMaxY(self.outputTextView.visibleRect) == NSMaxY(self.outputTextView.bounds)
                self.outputTextView.string = output
                if scroll {
                    self.outputTextView.scrollRangeToVisible(NSMakeRange(self.outputTextView.string!.characters.count, 0))
                }
            })
            .addDisposableTo(bag)
        viewModel.watch.running
            .subscribeNext { running in
                self.statusLabel.stringValue = running ? "Running" : "Idle"
            }
            .addDisposableTo(bag)
        addButton.rx_tap.subscribeNext{ self.addWatch() }
        removeButton.rx_tap.subscribeNext{ self.removeWatch() }
        editButton.rx_tap.subscribeNext{ self.editWatch() }
        tableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
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

    private func addWatch() {
        showWatchSettings()
    }

    private func removeWatch() {
        for (offset, row) in tableView.selectedRowIndexes.enumerate() {
            model.watches.removeAtIndex(row - offset)
        }
        
        tableView.selectRowIndexes(NSIndexSet(index: model.watches.count - 1), byExtendingSelection: false)
    }
    
    private func editWatch() {
        for (offset, row) in tableView.selectedRowIndexes.enumerate() {
            let watch = model.watches[(row - offset)]
            showWatchSettings(watch)
            break
        }
    }
    
    private func showWatchSettings(watch:Watch? = nil) {
        let settings = WatcherSettingsController(windowNibName: "WatcherSettings")
        if watch != nil {
            settings.watch = watch
        }
        self.window?.beginSheet(settings.window!) { response in
            if response == NSModalResponseOK {
                if settings.newWatch {
                    model.watches.append(settings.watch)
                } else {
                    
                }
            }
            settings.close()
        }
    }
}

extension PreferencesWindow : NSTableViewDelegate {
    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        let index = tableView.selectedRow
        if index != -1 {
            viewModel.bind(index)
            controlsView.hidden = false
            editButton.enabled = true
        } else {
            viewModel.unbind()
            controlsView.hidden = true
            editButton.enabled = false
        }
    }
    
    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        let tcell = cell as! NSTextFieldCell
        let watch = model.watches[row]
        tcell.textColor = watch.valid.value ? NSColor.textColor() : NSColor.redColor()
    }
}

//
//  AppDelegate.swift
//  WatchIt
//
//  Created by Alec Thomas on 1/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Cocoa
import AppKit
import EonilFileSystemEvents
import XCGLogger
import RxSwift

let log = XCGLogger()
var model = Model.deserialize()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var preferencesWindow = PreferencesWindow(windowNibName: "PreferencesWindow")
    var monitors: FileSystemEventMonitor?

    var statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    var watcher = Watcher(model: model)
    var runner: Runner

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var watchesMenu: NSMenu!

    override init() {
        runner = Runner(changes: watcher.changes)
        super.init()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let icon = NSImage(named: "eye-icon")
        icon?.template = true
        statusItem.image = icon
        statusItem.menu = menu
//        preferencesWindow.showWindow(self)
        updateMenu()
        // Monitor model for changes.
        sequenceOf(model.watches.anyChange, model.presets.anyChange)
            .merge()
            .throttle(0.25, MainScheduler.sharedInstance)
            .subscribeNext(saveAndUpdateMenu)
    }

    func saveAndUpdateMenu() {
        save()
        updateMenu()
    }

    func save() {
        do {
            try model.serialize()
        } catch let e {
            log.error("failed to serialize model: \(e)")
        }
    }

    func updateMenu() {
        watchesMenu.removeAllItems()
        for (i, watch) in model.watches.enumerate() {
            watchesMenu.insertItemWithTitle(watch.name.value, action: nil, keyEquivalent: "", atIndex: i)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        save()
    }

    @IBAction func onPreferences(sender: NSMenuItem) {
        NSApp.activateIgnoringOtherApps(true)
        preferencesWindow.showWindow(self)
        preferencesWindow.becomeFirstResponder()
        preferencesWindow.window?.makeKeyAndOrderFront(nil)
    }

    @IBAction func onQuit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(nil)
    }
}


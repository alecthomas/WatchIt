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

let log = XCGLogger()
var model = Model.deserialize()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var preferencesWindow = PreferencesWindow(windowNibName: "PreferencesWindow")
    var monitors: FileSystemEventMonitor?

    var statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var mainMenu: NSMenu!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSApplication.sharedApplication().mainMenu = mainMenu
        monitors = FileSystemEventMonitor(pathsToWatch: ["~/Documents".stringByExpandingTildeInPath], latency: 1, watchRoot: true, queue: dispatch_get_main_queue()) {events in
            print(events)
        }
        let icon = NSImage(named: "eye-icon")
        icon?.template = true
        statusItem.image = icon
        statusItem.menu = menu
        preferencesWindow.showWindow(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        do {
            try model.serialize()
        } catch let e {
            log.error("failed to serialize model: \(e)")
        }
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


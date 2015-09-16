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

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    var preferencesWindow = PreferencesWindow(windowNibName: "PreferencesWindow")
    var monitors: FileSystemEventMonitor?

    var statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    var watcher = Watcher(model: model)
    var runner: Runner
    var notificationCenter: NSUserNotificationCenter!

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var watchesMenu: NSMenu!

    private var notifications: [String:WatchError] = [:]

    override init() {
        runner = Runner(changes: watcher.changes)
        super.init()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        notificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.delegate = self

        let icon = NSImage(named: "eye-icon")
        icon?.template = true
        statusItem.image = icon
        statusItem.menu = menu
        if model.watches.isEmpty {
            preferencesWindow.showWindow(self)
        }
        updateMenu()
        // Monitor model for changes.
        sequenceOf(model.watches.anyChange, model.presets.anyChange)
            .merge()
            .throttle(0.25, MainScheduler.sharedInstance)
            .subscribeNext(saveAndUpdateMenu)
        runner.failures
            .subscribeNext(sendNotification)
    }

    func sendNotification(error: WatchError) {
        let notification = NSUserNotification()
        notification.title = "\(error.watch.name) failed"
        notification.informativeText = error.description
        notification.identifier = error.id
        notifications[error.id] = error
        notificationCenter.deliverNotification(notification)
        // Remove notification after 10 seconds.
        delay(10.0) {
            self.notifications.removeValueForKey(error.id)
            self.notificationCenter.removeDeliveredNotification(notification)
        }
    }

    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if let error = notifications[notification.identifier!] {
            let task = NSTask()
            var path = error.path
            if !path.hasPrefix("/") {
                path = NSURL(fileURLWithPath: error.watch.realPath).URLByAppendingPathComponent(path).path!
            }
            task.launchPath = "/Users/alec/bin/subl"
            task.arguments = ["\(path):\(error.line)"]
            task.launch()
        }
        notifications.removeAll()
        center.removeDeliveredNotification(notification)
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


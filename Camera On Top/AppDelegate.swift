//
//  AppDelegate.swift
//  Camera On Top
//
//  Created by Philippe Casgrain on 2020-10-04.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .mainMenu
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.makeKeyAndOrderFront(nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        self.window.standardWindowButton(.closeButton)?.superview?.alphaValue = 0
        self.window.titlebarAppearsTransparent = false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        self.window.standardWindowButton(.closeButton)?.superview?.animator().alphaValue = 1
        self.window.titlebarAppearsTransparent = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


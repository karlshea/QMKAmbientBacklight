//
//  AppDelegate.swift
//  QMKAmbientBacklight
//
//  Created by Karl Shea on 4/12/21.
//

import Cocoa
import SwiftUI
import QMKAmbientBacklightCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    let settings = QABSettings()
    
    lazy var updater: QABKeyboardBacklightUpdater = {
        QABKeyboardBacklightUpdater(settings: settings)
    }()
    
    private var shouldShowUI: Bool {
        !settings.hasLaunchedAppBefore || UserDefaults.standard.bool(forKey: "ShowSettings")
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "UseRegularActivationPolicy") {
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if shouldShowUI {
            settings.hasLaunchedAppBefore = true
            showSettingsWindow(nil)
        }
        
        updater.activate()
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(receivedShutdownNotification),
            name: NSWorkspace.willPowerOffNotification,
            object: nil
        )
    }

    @IBAction func showSettingsWindow(_ sender: Any?) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Settings")
        window.titlebarAppearsTransparent = true
        window.title = "QMK Ambient Backlight Settings"
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        let view = SettingsView()
            .environmentObject(QABAmbientLightSensorReader(frequency: .realtime))
            .environmentObject(settings)
        
        window.contentView = NSHostingView(rootView: view)
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private var isShowingSettingsWindow: Bool {
        guard let window = window else { return false }
        return window.isVisible
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !isShowingSettingsWindow else { return true }
        
        showSettingsWindow(nil)
        
        return true
    }
    
    private var shouldSkipTerminationConfirmation = false
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !shouldSkipTerminationConfirmation else { return .terminateNow }
        
        let alert = NSAlert()
        alert.messageText = "Quit QMK Ambient Backlight?"
        alert.informativeText = "If you quit QMK Ambient Backlight, it won't be able to monitor your ambient light level and update your keyboard backlight automatically. Would you like to hide QMK Ambient Backlight instead?"
        alert.addButton(withTitle: "Hide QMK Ambient Backlight")
        alert.addButton(withTitle: "Quit")
        
        let result = alert.runModal()
        
        if result == .alertSecondButtonReturn {
            return .terminateNow
        } else {
            window?.close()
            
            return .terminateCancel
        }
    }

    @objc func receivedShutdownNotification(_ note: Notification) {
        shouldSkipTerminationConfirmation = true
    }

}

extension AppDelegate: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
    
}

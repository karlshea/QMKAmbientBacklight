//
//  QABKeyboardMonitor.swift
//  QMKAmbientBacklightCore
//
//  Created by Karl Shea on 4/14/21.
//

import Cocoa
import Combine
import os.log
import USBDeviceSwift

open class QABKeyboardMonitor: NSObject {
    
    private let vendorId: UInt16
    private let productId: UInt16
    private let usagePage: UInt16
    private let usage: UInt8
    
    private var ioManagerRef: IOHIDManager!
    private var keyboard: QABKeyboard?
    
    private let log = OSLog(subsystem: kQMKAmbientBacklightCoreSubsystemName, category: String(describing: QABKeyboardMonitor.self))
    
    public var requestedBacklightLevel: UInt8 = 0 {
        didSet {
            guard let keyboard = keyboard else {
                return
            }
            DispatchQueue.global().async {
                keyboard.setBacklightLevel(self.requestedBacklightLevel)
            }
        }
    }
    
    public init(vendorId: UInt16, productId: UInt16, usagePage: UInt16, usage: UInt8)
    {
        self.vendorId = vendorId
        self.productId = productId
        self.usagePage = usagePage
        self.usage = usage
    }
    
    func start() {
        initializeMonitor()
    }
    
    func stop() {
        os_log("Stopping monitor for %02X %02X", log: log, type: .debug, vendorId, productId)

        let rl = RunLoop.current.getCFRunLoop()
        IOHIDManagerUnscheduleFromRunLoop(ioManagerRef, rl, CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(ioManagerRef, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    @objc open func initializeMonitor() {
        let rl = RunLoop.current.getCFRunLoop()
        
        let match: [String: Any] = [
            kIOHIDVendorIDKey: vendorId,
            kIOHIDProductIDKey: productId,
            kIOHIDDeviceUsagePageKey: usagePage,
            kIOHIDDeviceUsageKey: usage,
        ]

        os_log("Initializing keyboard monitor for %02X %02X", log: log, type: .debug, vendorId, productId)

        ioManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        IOHIDManagerSetDeviceMatching(ioManagerRef, match as CFDictionary)
        IOHIDManagerScheduleWithRunLoop(ioManagerRef, rl, CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(ioManagerRef, IOOptionBits(kIOHIDOptionsTypeNone))

        let matchingCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this: QABKeyboardMonitor = unsafeBitCast(inContext, to: QABKeyboardMonitor.self)
            this.rawDeviceAdded(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }

        IOHIDManagerRegisterDeviceMatchingCallback(ioManagerRef, matchingCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
    }
    
    open func rawDeviceAdded(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let device = HIDDevice(device: inIOHIDDeviceRef)
        os_log("Keyboard %{public}@ found", log: log, type: .debug, device.name)
        
        DispatchQueue.global().async {
            self.keyboard = QABKeyboard(device)
            self.keyboard?.setBacklightLevel(self.requestedBacklightLevel)
        }
    }
    
    open func rawDeviceRemoved(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let device = HIDDevice(device: inIOHIDDeviceRef)
        keyboard = nil
        
        os_log("Keyboard %{public}@ removed", log: log, type: .debug, device.name)
    }
    
}

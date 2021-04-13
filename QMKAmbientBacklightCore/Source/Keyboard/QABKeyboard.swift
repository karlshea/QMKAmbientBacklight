//
//  QABSetKeyboardBacklight.swift
//  QMKAmbientBacklightCore
//
//  Created by Karl Shea on 4/12/21.
//

import USBDeviceSwift
import os.log

public final class QABKeyboard {
    
    private let log = OSLog(subsystem: kQMKAmbientBacklightCoreSubsystemName, category: String(describing: QABKeyboard.self))
    
    let device: HIDDevice
    
    public init(_ device: HIDDevice) {
        self.device = device
    }
    
    public func setBacklightLevel(_ level: UInt8) {
        let commandSetLighting: UInt8 = 0x07
        let lightingBrightness: UInt8 = 0x09
        
        let commandData = Data([
            lightingBrightness,
            level
        ])
        
        var byteArray = [UInt8](commandData)
        let reportId: UInt8 = commandSetLighting
        byteArray.insert(reportId, at: 0)
        byteArray.append(0)
        
        if (byteArray.count > device.reportSize) {
            os_log("Output data too large for USB report (count: %{public}d)", log: self.log, type: .fault, byteArray.count)
            return
        }
        
        let correctData = byteArray.withUnsafeBufferPointer { byteArray in
            Data(bytes: byteArray.baseAddress!, count: device.reportSize)
        }
        
        let retVal = IOHIDDeviceSetReport(
            device.device,
            kIOHIDReportTypeOutput,
            CFIndex(reportId),
            (correctData as NSData).bytes.bindMemory(to: UInt8.self, capacity: correctData.count),
            correctData.count
        )
        
        if (retVal == kIOReturnSuccess) {
            os_log("Set keyboard brightness to %{public}d", log: self.log, type: .debug, level)
        } else {
            os_log("Failed updating keyboard brightness", log: self.log, type: .debug)
        }
    }
    
}

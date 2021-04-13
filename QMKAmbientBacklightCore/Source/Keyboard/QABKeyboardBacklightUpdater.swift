//
//  QABKeyboardBacklightUpdater.swift
//  QMKAmbientBacklightCore
//
//  Created by Karl Shea on 4/12/21.
//

import Cocoa
import Combine
import os.log

public final class QABKeyboardBacklightUpdater: ObservableObject {
    
    private let log = OSLog(subsystem: kQMKAmbientBacklightCoreSubsystemName, category: String(describing: QABKeyboardBacklightUpdater.self))
    
    let settings: QABSettings
    let reader: QABAmbientLightSensorReader
    var keyboardMonitor: QABKeyboardMonitor?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(settings: QABSettings,
                reader: QABAmbientLightSensorReader = QABAmbientLightSensorReader(frequency: .fast))
    {
        self.settings = settings
        self.reader = reader
    }
    
    public func activate() {
        reader.$ambientLightValue.sink { [weak self] newValue in
            self?.ambientLightChanged(to: newValue)
        }.store(in: &cancellables)
    
        settings.$currentKeyboardSettings.sink { [weak self] newValue in
            self?.initializeKeyboardMonitor(keyboardSettings: newValue)
        }.store(in: &cancellables)
        
        settings.$minimumLevel.sink { [weak self] _ in
            self?.reset()
        }.store(in: &cancellables)
        
        reader.activate()
    }

    private func initializeKeyboardMonitor(keyboardSettings: QABKeyboardSettings) {
        guard let vendorId = UInt16(keyboardSettings.vendorId, radix: 16), let productId = UInt16(keyboardSettings.productId, radix: 16) else {
            return
        }
        
        keyboardMonitor = QABKeyboardMonitor(vendorId: vendorId, productId: productId, usagePage: settings.keyboardUsagePage, usage: settings.keyboardUsage)
        
        let monitorDaemon = Thread(target: self.keyboardMonitor!, selector: #selector(self.keyboardMonitor!.initializeMonitor), object: nil)
        monitorDaemon.start()
    }
    
    private func setupUpdateBacklightOnWake() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.attemptBacklightChangeOnWake()
            }
        }
    }
    
    private func attemptBacklightChangeOnWake() {
        reader.update()
        
        os_log("%{public}@ %.2f", log: log, type: .debug, #function, reader.ambientLightValue)
        
        self.evaluateAmbientLight(with: reader.ambientLightValue)
    }
    
    private func reset() {
        evaluateAmbientLight(with: reader.ambientLightValue)
    }
    
    private func ambientLightChanged(to value: Double) {
        os_log("%{public}@ %.2f", log: log, type: .debug, #function, value)
        
        self.evaluateAmbientLight(with: value)
    }
    
    private func evaluateAmbientLight(with value: Double) {
    
        // Max seems to be around 2,000 but it'll never be that bright.
        // Reasonable seems to be around 300 for max brightness?
        // Levels are 255 (8 bits)
        
        let clamped = min(max(value, 0), 300)
        let ratio = round((clamped / 300) * 255)
        let newLevel = UInt8(ratio > Double(UInt8.max) ? Double(UInt8.max) : ratio)
        let adjustedLevel = newLevel < settings.minimumLevel ? UInt8(settings.minimumLevel) : newLevel
        
        setKeyboardBacklightLevel(adjustedLevel)
    }
    
    private func setKeyboardBacklightLevel(_ value: UInt8) {
        guard let monitor = self.keyboardMonitor else {
            os_log("No current keyboard monitor", log: log, type: .debug)
            return
        }
        
        monitor.requestedBacklightLevel = value
    }
}

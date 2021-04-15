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
    
    private var currentKeyboardSettings: QABKeyboardSettings
    private var currentKeyboardAdjustments: QABKeyboardAdjustments
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(settings: QABSettings,
                reader: QABAmbientLightSensorReader = QABAmbientLightSensorReader(frequency: .fast))
    {
        self.settings = settings
        self.reader = reader
        
        self.currentKeyboardSettings = settings.currentKeyboardSettings
        self.currentKeyboardAdjustments = settings.currentKeyboardAdjustments
    }
    
    public func activate() {
        reader.$ambientLightValue.sink { [weak self] newValue in
            self?.ambientLightChanged(to: newValue)
        }.store(in: &cancellables)
    
        settings.$currentKeyboardSettings.sink { [weak self] newValue in
            self?.currentKeyboardSettings = newValue
            self?.initializeKeyboardMonitor()
        }.store(in: &cancellables)
        
        settings.$currentKeyboardAdjustments.sink { [weak self] newValue in
            self?.currentKeyboardAdjustments = newValue
            self?.reset()
        }.store(in: &cancellables)
        
        reader.activate()
    }

    private func initializeKeyboardMonitor() {
        let keyboardSettings = self.currentKeyboardSettings
        
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
        let evaluator = QABBacklightLevelEvaluator(adjustments: self.currentKeyboardAdjustments)
        
        setKeyboardBacklightLevel(evaluator.determineLevelForLux(value))
    }
    
    private func setKeyboardBacklightLevel(_ value: UInt8) {
        guard let monitor = self.keyboardMonitor else {
            os_log("No current keyboard monitor", log: log, type: .debug)
            return
        }
        
        monitor.requestedBacklightLevel = value
    }
}

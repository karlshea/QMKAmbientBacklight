//
//  QABSettings.swift
//  QMKAmbientBacklightCore
//
//  Created by Karl Shea on 4/12/21.
//

import Foundation
import SwiftUI

public final class QABSettings: ObservableObject {
    
    public let keyboardUsagePage: UInt16 = 0xFF60
    public let keyboardUsage: UInt8 = 0x61
    
    @Published public var currentKeyboardSettings: QABKeyboardSettings
    @Published public var currentKeyboardAdjustments: QABKeyboardAdjustments
    
    private struct Keys {
        static let hasLaunchedAppBefore = "hasLaunchedAppBefore"
        static let keyboardVendorId = "keyboardVendorId"
        static let keyboardProductId = "keyboardProductId"
        static let minimumLevel = "minimumLevel"
        static let maximumLevel = "maximumLevel"
        static let luxValueConsideredMaximum = "luxValueConsideredMaximum"
    }
    
    private let defaults: UserDefaults
    
    let isPreviewing: Bool
    
    public init(forPreview isPreviewing: Bool = false, defaults: UserDefaults = .standard) {
        self.isPreviewing = isPreviewing
        self.defaults = defaults
        
        defaults.register(defaults: [
            Keys.keyboardVendorId: String(0x4B42, radix: 16),
            Keys.keyboardProductId: String(0x6061, radix: 16),
            Keys.minimumLevel: 20,
            Keys.maximumLevel: 255,
            Keys.luxValueConsideredMaximum: 500,
        ])
        
        self.hasLaunchedAppBefore = defaults.bool(forKey: Keys.hasLaunchedAppBefore)
        
        let minimumLevel = UInt8(defaults.integer(forKey: Keys.minimumLevel))
        self.minimumLevel = minimumLevel
        
        let maximumLevel = UInt8(defaults.integer(forKey: Keys.maximumLevel))
        self.maximumLevel = maximumLevel
        
        let luxValueConsideredMaximum = defaults.integer(forKey: Keys.luxValueConsideredMaximum)
        self.luxValueConsideredMaximum = luxValueConsideredMaximum
        
        let vendorId = defaults.string(forKey: Keys.keyboardVendorId) ?? ""
        self.keyboardVendorId = vendorId
        
        let productId = defaults.string(forKey: Keys.keyboardProductId) ?? ""
        self.keyboardProductId = productId
        
        self.currentKeyboardSettings = QABKeyboardSettings(vendorId: vendorId, productId: productId)
        self.currentKeyboardAdjustments = QABKeyboardAdjustments(minimumLevel: minimumLevel, maximumLevel: maximumLevel, luxValueConsideredMaximum: luxValueConsideredMaximum)
        
        if isPreviewing {
            self.isLaunchAtLoginEnabled = false
        } else {
            self.isLaunchAtLoginEnabled = Self.isAppInLoginItems
            
            SharedFileList.sessionLoginItems().changeHandler = { [weak self] _ in
                self?.updateLaunchAtLoginEnabled()
            }
        }
    }
    
    @Published public var hasLaunchedAppBefore: Bool {
        didSet {
            defaults.set(
                hasLaunchedAppBefore,
                forKey: Keys.hasLaunchedAppBefore
            )
        }
    }
    
    @Published public var minimumLevel: UInt8 {
        didSet {
            defaults.set(
                minimumLevel,
                forKey: Keys.minimumLevel
            )
            currentKeyboardAdjustments.minimumLevel = minimumLevel
        }
    }
    
    @Published public var maximumLevel: UInt8 {
        didSet {
            defaults.set(
                maximumLevel,
                forKey: Keys.maximumLevel
            )
            currentKeyboardAdjustments.maximumLevel = maximumLevel
        }
    }
    
    @Published public var luxValueConsideredMaximum: Int {
        didSet {
            defaults.set(
                luxValueConsideredMaximum,
                forKey: Keys.luxValueConsideredMaximum
            )
            currentKeyboardAdjustments.luxValueConsideredMaximum = luxValueConsideredMaximum
        }
    }
    
    @Published public var keyboardVendorId: String {
        didSet {
            defaults.set(
                keyboardVendorId,
                forKey: Keys.keyboardVendorId
            )
            currentKeyboardSettings.vendorId = keyboardVendorId
        }
    }
    
    @Published public var keyboardProductId: String {
        didSet {
            defaults.set(
                keyboardProductId,
                forKey: Keys.keyboardProductId
            )
            currentKeyboardSettings.productId = keyboardVendorId
        }
    }
    
    // MARK: - Launch at login
    
    private static var isAppInLoginItems: Bool {
        SharedFileList.sessionLoginItems().containsItem(Self.appURL)
    }
    
    private func updateLaunchAtLoginEnabled() {
        isLaunchAtLoginEnabled = Self.isAppInLoginItems
    }
    
    private static var appURL: URL { Bundle.main.bundleURL }
    
    @Published public var isLaunchAtLoginEnabled: Bool {
        didSet {
            guard !isPreviewing else { return }

            guard isLaunchAtLoginEnabled != oldValue else { return }

            if isLaunchAtLoginEnabled {
                SharedFileList.sessionLoginItems().addItem(Self.appURL)
            } else {
                SharedFileList.sessionLoginItems().removeItem(Self.appURL)
            }
        }
    }

}

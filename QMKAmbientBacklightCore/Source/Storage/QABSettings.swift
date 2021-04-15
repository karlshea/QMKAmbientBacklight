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
    
    private struct Keys {
        static let hasLaunchedAppBefore = "hasLaunchedAppBefore"
        static let keyboardVendorId = "keyboardVendorId"
        static let keyboardProductId = "keyboardProductId"
        static let minimumLevel = "minimumLevel"
    }
    
    private let defaults: UserDefaults
    
    let isPreviewing: Bool
    
    public init(forPreview isPreviewing: Bool = false, defaults: UserDefaults = .standard) {
        self.isPreviewing = isPreviewing
        self.defaults = defaults
        
        defaults.register(defaults: [
            Keys.keyboardVendorId: String(0x4B42, radix: 16),
            Keys.keyboardProductId: String(0x6061, radix: 16),
            Keys.minimumLevel: 20
        ])
        
        self.hasLaunchedAppBefore = defaults.bool(forKey: Keys.hasLaunchedAppBefore)
        self.minimumLevel = UInt8(defaults.integer(forKey: Keys.minimumLevel))
        
        let vendorId = defaults.string(forKey: Keys.keyboardVendorId) ?? ""
        self.keyboardVendorId = vendorId
        
        let productId = defaults.string(forKey: Keys.keyboardProductId) ?? ""
        self.keyboardProductId = productId
        
        self.currentKeyboardSettings = QABKeyboardSettings(vendorId: vendorId, productId: productId)
        
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

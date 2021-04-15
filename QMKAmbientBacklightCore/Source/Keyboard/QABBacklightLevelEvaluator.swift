//
//  BacklightLevelEvaluator.swift
//  QMKAmbientBacklightCore
//
//  Created by Karl Shea on 4/15/21.
//

import Foundation

public struct QABBacklightLevelEvaluator {
    let adjustments: QABKeyboardAdjustments
    
    public init(adjustments: QABKeyboardAdjustments) {
        self.adjustments = adjustments
    }
    
    public func determineLevelForLux(_ lux: Double) -> UInt8 {
        let maxLux = Double(adjustments.luxValueConsideredMaximum)
    
        // Max seems to be around 2,000 but it'll never be that bright unless in direct sunlight.
        // Reasonable seems to be around 500 for max brightness?
        // Levels are 255 (8 bits)
        
        let clamped = min(max(lux, 0), maxLux)
        let ratio = round((clamped / maxLux) * Double(adjustments.maximumLevel))
        let newLevel = UInt8(ratio > Double(UInt8.max) ? Double(UInt8.max) : ratio)
        
        return UInt8(newLevel < adjustments.minimumLevel ? adjustments.minimumLevel : newLevel)
    }
    
}

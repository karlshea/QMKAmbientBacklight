//
//  SettingsView.swift
//  QMKAmbientBacklight
//
//  Created by Karl Shea on 4/12/21.
//

import SwiftUI
import QMKAmbientBacklightCore

struct SettingsView: View {
    @EnvironmentObject var reader: QABAmbientLightSensorReader
    @EnvironmentObject var settings: QABSettings
    
    var body: some View {
        Group {
            if reader.isSensorReady {
                settingsControls
            } else {
                UnsupportedMacView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding([.top, .bottom])
        .padding([.leading, .trailing], 22)
        .onAppear { reader.activate() }
    }
    
    private var settingsControls: some View {
        var minLevelProxy: Binding<Float> {
                Binding<Float>(
                    get: { Float(settings.minimumLevel) },
                    set: {
                        settings.minimumLevel = UInt8($0)
                    }
                )
            }
        
        return VStack(alignment: .leading, spacing: 32) {
            Toggle(
                "Launch at Login",
                isOn: $settings.isLaunchAtLoginEnabled
            )
            
            Group {
                HStack(alignment: .firstTextBaseline) {
                    Text("Vendor ID")
                    TextField("Vendor ID", text: $settings.keyboardVendorId)
                        
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Product ID")
                    TextField("Product ID", text: $settings.keyboardProductId)
                }
            }
            
            Group {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Minimum backlight level:")
                    
                
                    HStack(alignment: .firstTextBaseline) {
                        Slider(value: minLevelProxy, in: 0...255, step: 1)
                            .frame(maxWidth: 300)
                        Text("\(settings.minimumLevel)")
                            .font(Font.system(size: 12, weight: .medium).monospacedDigit())
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("Current Ambient Light Level:")
                    Text("\(reader.ambientLightValue.formattedNoFractionDigits)")
                        .font(Font.system(size: 12).monospacedDigit())
                }
                .font(.system(size: 12))
                .foregroundColor(Color(NSColor.secondaryLabelColor))
            }
        }
    }
}

extension NumberFormatter {
    static let noFractionDigits: NumberFormatter = {
        let f = NumberFormatter()
        
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        
        return f
    }()
}

extension Double {
    var formattedNoFractionDigits: String {
        NumberFormatter.noFractionDigits.string(from: NSNumber(value: self)) ?? "!!!"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .frame(maxWidth: 385)
            .environmentObject(QABAmbientLightSensorReader(frequency: .realtime))
            .environmentObject(QABSettings(forPreview: true))
            .previewLayout(.sizeThatFits)
    }
}

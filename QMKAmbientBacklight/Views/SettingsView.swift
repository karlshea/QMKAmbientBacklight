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
        var luxMaxProxy: Binding<Float> {
                Binding<Float>(
                    get: { Float(settings.luxValueConsideredMaximum) },
                    set: {
                        settings.luxValueConsideredMaximum = Int($0)
                    }
                )
            }
        
        var minLevelProxy: Binding<Float> {
                Binding<Float>(
                    get: { Float(settings.minimumLevel) },
                    set: {
                        settings.minimumLevel = UInt8($0)
                    }
                )
            }
        
        var maxLevelProxy: Binding<Float> {
                Binding<Float>(
                    get: { Float(settings.maximumLevel) },
                    set: {
                        settings.maximumLevel = UInt8($0)
                    }
                )
            }
        
        let evaluator = QABBacklightLevelEvaluator(adjustments: settings.currentKeyboardAdjustments)
        
        return VStack(alignment: .leading, spacing: 12) {
            
            Toggle(
                "Launch at Login",
                isOn: $settings.isLaunchAtLoginEnabled
            )
            
            GroupBox(label: Text("Keyboard")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Vendor ID")
                        TextField("Vendor ID", text: $settings.keyboardVendorId)
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Product ID")
                        TextField("Product ID", text: $settings.keyboardProductId)
                    }
                }.padding()
            }.frame(maxWidth: .infinity)
            
            
            GroupBox(label: Text("Ambient Light")) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lux considered maximum:")

                    HStack(alignment: .firstTextBaseline) {
                        Slider(value: luxMaxProxy, in: 0...2000)
                            .frame(maxWidth: 300)
                        Text("\(settings.luxValueConsideredMaximum)")
                            .font(Font.system(size: 12, weight: .medium).monospacedDigit())
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Current Ambient Light Lux:")
                        Text("\(reader.ambientLightValue.formattedNoFractionDigits)")
                            .font(Font.system(size: 12).monospacedDigit())
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                }.padding()
            }
            
                
            GroupBox(label: Text("Backlight")) {
                VStack(alignment: .leading, spacing: 2) {
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Minimum backlight level:")
                        HStack(alignment: .firstTextBaseline) {
                            Slider(value: minLevelProxy, in: 0...255)
                                .frame(maxWidth: 300)
                            Text("\(settings.minimumLevel)")
                                .font(Font.system(size: 12, weight: .medium).monospacedDigit())
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maximum backlight level:")

                        HStack(alignment: .firstTextBaseline) {
                            Slider(value: maxLevelProxy, in: 0...255)
                                .frame(maxWidth: 300)
                            Text("\(settings.maximumLevel)")
                                .font(Font.system(size: 12, weight: .medium).monospacedDigit())
                        }
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Current Keyboard Level:")
                        Text("\(evaluator.determineLevelForLux(reader.ambientLightValue))")
                            .font(Font.system(size: 12).monospacedDigit())
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                }.padding()
            }.frame(maxWidth: .infinity)
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
            .frame(maxWidth: 400, minHeight: 520)
            .environmentObject(QABAmbientLightSensorReader(frequency: .realtime))
            .environmentObject(QABSettings(forPreview: true))
            .previewLayout(.sizeThatFits)
    }
}

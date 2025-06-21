//
//  HapticConfiguration.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Foundation

/// Configuration values for haptic patterns
public struct HapticConfiguration {
    public var defaultIntensity: Float
    public var defaultSharpness: Float
    public var continuousDuration: TimeInterval
    public var respectSystemSettings: Bool

    public init(
        defaultIntensity: Float = 1.0,
        defaultSharpness: Float = 0.5,
        continuousDuration: TimeInterval = 10.0,
        respectSystemSettings: Bool = true
    ) {
        self.defaultIntensity = defaultIntensity
        self.defaultSharpness = defaultSharpness
        self.continuousDuration = continuousDuration
        self.respectSystemSettings = respectSystemSettings
    }
}

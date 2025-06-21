//
//  HapticPatternBuilder 2.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import CoreHaptics

/// Factory methods for common CHHapticPattern types
public enum HapticPatternBuilder {
    
    /// A single, continuous haptic event
    public static func continuous(
        intensity: Float = 1.0,
        sharpness: Float = 0.5,
    ) throws -> CHHapticPattern {
        let params = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ]
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: params,
            relativeTime: 0,
            duration: 9999,
        )
        do {
            return try CHHapticPattern(events: [event], parameters: [])
        } catch {
            throw HapticError.patternCreationFailed(error)
        }
    }

    /// A repeating pulse pattern
    public static func pulse(
        intensity: Float = 1.0,
        sharpness: Float = 0.8,
        interval: TimeInterval = 0.2,
        count: Int = 1000,
    ) throws -> CHHapticPattern {
        var events = [CHHapticEvent]()
        for i in 0..<count {
            let params = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ]
            let rt = Double(i) * interval
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: params,
                relativeTime: rt,
                duration: 0.1
            )
            events.append(event)
        }
        do {
            return try CHHapticPattern(events: events, parameters: [])
        } catch {
            throw HapticError.patternCreationFailed(error)
        }
    }
}

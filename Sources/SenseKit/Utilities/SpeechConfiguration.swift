//
//  SpeechConfiguration.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Foundation
import AVFAudio

/// Configuration for speech triggers and behaviors
public struct SpeechConfiguration {
    public struct Trigger {
        public let text: String
        public let caseSensitive: Bool
        public let action: @MainActor () -> Void
        
        public init(
            text: String,
            caseSensitive: Bool = false,
            action: @escaping @MainActor () -> Void
        ) {
            self.text = text
            self.caseSensitive = caseSensitive
            self.action = action
        }
    }
    
    public var triggers: [Trigger]
    public var voice: String
    public var volume: Float
    public var rate: Float
    
    public init(
        triggers: [Trigger] = [],
        voice: String = "en-US",
        volume: Float = 1.0,
        rate: Float = AVSpeechUtteranceDefaultSpeechRate
    ) {
        self.triggers = triggers
        self.voice = voice
        self.volume = volume
        self.rate = rate
    }
}

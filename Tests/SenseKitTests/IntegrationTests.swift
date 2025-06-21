//
//  IntegrationTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Testing
import Foundation
import AVFoundation
@testable import SenseKit

@Suite("Integration Tests")
@MainActor
struct IntegrationTests {
    
    @Test("Speech and haptics work together")
    func speechAndHapticsIntegration() async throws {
        let mockHapticEngine = MockHapticEngine()
        let hapticController = try HapticController(engine: mockHapticEngine)
        let speechController = SpeechController()
        
        // Add trigger to play haptic when saying "vibrate"
        speechController.addTrigger(
            SpeechConfiguration.Trigger(text: "vibrate") { [hapticController] in
                try? hapticController.prepare()
                try? hapticController.playPulse()
            }
        )
        
        speechController.speak("Please vibrate now")
        
        // Wait for trigger to execute
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockHapticEngine.startCallCount == 1)
        #expect(mockHapticEngine.createdPlayers.count == 1)
    }
    
    @Test("Multiple controllers can coexist")
    func multipleControllersCoexist() async throws {
        let speechController1 = SpeechController()
        let speechController2 = SpeechController()
        
        let mockHapticEngine1 = MockHapticEngine()
        let mockHapticEngine2 = MockHapticEngine()
        let hapticController1 = try HapticController(engine: mockHapticEngine1)
        let hapticController2 = try HapticController(engine: mockHapticEngine2)
        
        speechController1.speak("Controller 1")
        speechController2.speak("Controller 2")
        
        try hapticController1.prepare()
        try hapticController2.prepare()
        
        _ = try hapticController1.playContinuous()
        _ = try hapticController2.playPulse()
        
        #expect(speechController1.currentText == "Controller 1")
        #expect(speechController2.currentText == "Controller 2")
        #expect(mockHapticEngine1.createdPlayers.count == 1)
        #expect(mockHapticEngine2.createdPlayers.count == 1)
    }
}
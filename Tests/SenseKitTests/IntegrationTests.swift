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
    func speechAndHapticsIntegration() throws {
        let mockHapticEngine = MockHapticEngine()
        let hapticController = try HapticController(engine: mockHapticEngine)
        let speechController = SpeechController(synthesizer: MockSpeechSynthesizer())

        // Play a haptic pulse whenever the spoken text contains "vibrate".
        speechController.addTrigger(
            SpeechConfiguration.Trigger(text: "vibrate") {
                try? hapticController.prepare()
                _ = try? hapticController.playPulse()
            }
        )

        // Triggers run synchronously within speak(), so no waiting is required.
        speechController.speak("Please vibrate now")

        #expect(mockHapticEngine.startCallCount == 1)
        #expect(mockHapticEngine.createdPlayers.count == 1)
    }

    @Test("Multiple controllers can coexist")
    func multipleControllersCoexist() throws {
        let speechController1 = SpeechController(synthesizer: MockSpeechSynthesizer())
        let speechController2 = SpeechController(synthesizer: MockSpeechSynthesizer())

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

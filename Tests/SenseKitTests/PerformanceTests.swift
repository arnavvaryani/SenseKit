//
//  PerformanceTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Testing
import Foundation
@testable import SenseKit

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Speech controller handles many utterances efficiently")
    @MainActor
    func speechPerformance() {
        let mock = MockSpeechSynthesizer()
        let controller = SpeechController(synthesizer: mock, audioSession: MockAudioSession(), config: SpeechConfiguration(voice: ""))

        // Each speak() builds a real AVSpeechSynthesisVoice (~100ms on CI), so
        // keep the count low; this verifies throughput/state, not micro-timing.
        let iterations = 20
        let startTime = Date()
        for i in 0..<iterations {
            controller.speak("Message \(i)")
        }
        let duration = Date().timeIntervalSince(startTime)

        #expect(mock.spokenUtterances.count == iterations)
        #expect(controller.isSpeaking)
        // Generous upper bound so the assertion is meaningful without being flaky in CI.
        #expect(duration < 10.0)
    }

    @Test("Haptic pattern creation is fast")
    func hapticPatternPerformance() throws {
        let startTime = Date()

        for _ in 0..<100 {
            _ = try HapticPatternBuilder.pulse(
                intensity: 0.8,
                sharpness: 0.6,
                interval: 0.1,
                count: 20
            )
        }

        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 1.0)
    }
}

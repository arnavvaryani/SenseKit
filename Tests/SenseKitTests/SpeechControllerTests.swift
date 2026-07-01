//
//  SpeechControllerTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/23/25.
//

import Testing
import Foundation
import AVFoundation
@testable import SenseKit

@Suite("SpeechController Tests")
@MainActor
struct SpeechControllerTests {

    /// Builds a controller backed entirely by mocks (no real audio session or
    /// synthesizer), so tests are deterministic and never block on the simulator.
    private func makeController(
        config: SpeechConfiguration = SpeechConfiguration(voice: "")
    ) -> (SpeechController, MockSpeechSynthesizer) {
        let mock = MockSpeechSynthesizer()
        let controller = SpeechController(
            synthesizer: mock,
            audioSession: MockAudioSession(),
            config: config
        )
        return (controller, mock)
    }

    @Test("Initialize with defaults")
    func initializeWithDefaults() {
        let (controller, _) = makeController()

        #expect(controller.isSpeaking == false)
        #expect(controller.currentText == nil)
    }

    @Test("Speak sets state correctly")
    func speakSetsState() {
        let (controller, mock) = makeController()

        let task = controller.speak("Hello, world!")

        #expect(controller.isSpeaking)
        #expect(controller.currentText == "Hello, world!")
        #expect(mock.spokenUtterances.count == 1)
        #expect(task != nil)
    }

    @Test("Speak respects repetition control")
    func speakRespectsRepetition() {
        let (controller, mock) = makeController()

        let task1 = controller.speak("Hello")
        let task2 = controller.speak("Hello")                 // duplicate -> ignored
        let task3 = controller.speak("Hello", allowRepeat: true)

        #expect(task1 != nil)
        #expect(task2 == nil)
        #expect(task3 != nil)
        #expect(mock.spokenUtterances.count == 2)
    }

    @Test("Triggers execute on matching text")
    func triggersExecute() {
        var triggerExecuted = false
        let trigger = SpeechConfiguration.Trigger(text: "navigate") {
            triggerExecuted = true
        }
        let (controller, _) = makeController(config: SpeechConfiguration(triggers: [trigger], voice: ""))

        controller.speak("Please navigate to the map")

        #expect(triggerExecuted)
    }

    @Test("Case insensitive triggers")
    func caseInsensitiveTriggers() {
        var triggerCount = 0
        let trigger = SpeechConfiguration.Trigger(text: "HELP", caseSensitive: false) {
            triggerCount += 1
        }
        let (controller, _) = makeController(config: SpeechConfiguration(triggers: [trigger], voice: ""))

        controller.speak("I need help")
        controller.speak("HELP me")
        controller.speak("Help!")

        #expect(triggerCount == 3)
    }

    @Test("Stop speaking cancels current task")
    func stopSpeakingCancels() {
        let (controller, mock) = makeController()

        _ = controller.speak("Long text")
        controller.stopSpeaking()

        #expect(controller.isSpeaking == false)
        #expect(controller.currentText == nil)
        #expect(mock.stopCallCount == 1)
    }

    @Test("Task controls forward to the synthesizer")
    func taskControls() throws {
        let (controller, mock) = makeController()

        let task = try #require(controller.speak("Test"))

        task.pause()
        #expect(mock.pauseCallCount == 1)

        task.resume()
        #expect(mock.continueCallCount == 1)

        task.cancel()
        #expect(mock.stopCallCount == 1)
    }

    @Test("Clear cache allows repetition")
    func clearCacheAllowsRepetition() {
        let (controller, mock) = makeController()

        _ = controller.speak("Hello")
        let task1 = controller.speak("Hello")   // duplicate -> nil

        controller.clearSpokenCache()
        let task2 = controller.speak("Hello")   // allowed again

        #expect(task1 == nil)
        #expect(task2 != nil)
        #expect(mock.spokenUtterances.count == 2)
    }
}

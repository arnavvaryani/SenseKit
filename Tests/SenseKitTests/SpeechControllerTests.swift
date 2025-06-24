//
//  SpeechControllerTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


//import Testing
//import Foundation
//import AVFoundation
//@testable import SenseKit
//
//@Suite("SpeechController Tests")
//@MainActor
//struct SpeechControllerTests {
//    
//    @Test("Initialize with defaults")
//    func initializeWithDefaults() {
//        let controller = SpeechController()
//        
//        #expect(controller.isSpeaking == false)
//        #expect(controller.currentText == nil)
//    }
//    
//    @Test("Speak sets state correctly")
//    func speakSetsState() async throws {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let controller = SpeechController(synthesizer: mockSynthesizer)
//        
//        let task = controller.speak("Hello, world!")
//        
//        #expect(controller.isSpeaking == true)
//        #expect(controller.currentText == "Hello, world!")
//        #expect(mockSynthesizer.spokenUtterances.count == 1)
//        #expect(task != nil)
//    }
//    
//    @Test("Speak respects repetition control")
//    func speakRespectsRepetition() {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let controller = SpeechController(synthesizer: mockSynthesizer)
//        
//        let task1 = controller.speak("Hello")
//        let task2 = controller.speak("Hello") // Should be ignored
//        let task3 = controller.speak("Hello", allowRepeat: true) // Should work
//        
//        #expect(task1 != nil)
//        #expect(task2 == nil)
//        #expect(task3 != nil)
//        #expect(mockSynthesizer.spokenUtterances.count == 2)
//    }
//    
//    @Test("Triggers execute on matching text")
//    func triggersExecute() async throws {
//        var triggerExecuted = false
//        let trigger = SpeechConfiguration.Trigger(text: "navigate") {
//            triggerExecuted = true
//        }
//        
//        let config = SpeechConfiguration(triggers: [trigger])
//        let controller = SpeechController(config: config)
//        
//        controller.speak("Please navigate to the map")
//        
//        #expect(triggerExecuted == true)
//    }
//    
//    @Test("Case insensitive triggers")
//    func caseInsensitiveTriggers() {
//        var triggerCount = 0
//        let trigger = SpeechConfiguration.Trigger(
//            text: "HELP",
//            caseSensitive: false
//        ) {
//            triggerCount += 1
//        }
//        
//        let config = SpeechConfiguration(triggers: [trigger])
//        let controller = SpeechController(config: config)
//        
//        controller.speak("I need help")
//        controller.speak("HELP me")
//        controller.speak("Help!")
//        
//        #expect(triggerCount == 3)
//    }
//    
//    @Test("Stop speaking cancels current task")
//    func stopSpeakingCancels() {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let controller = SpeechController(synthesizer: mockSynthesizer)
//        
//        _ = controller.speak("Long text")
//        controller.stopSpeaking()
//        
//        #expect(controller.isSpeaking == false)
//        #expect(controller.currentText == nil)
//        #expect(mockSynthesizer.stopCallCount == 1)
//    }
//    
//    @Test("Task controls work correctly")
//    func taskControls() {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let controller = SpeechController(synthesizer: mockSynthesizer)
//        
//        let task = controller.speak("Test")!
//        
//        task.pause()
//        #expect(mockSynthesizer.pauseCallCount == 1)
//        
//        task.resume()
//        #expect(mockSynthesizer.continueCallCount == 1)
//        
//        task.cancel()
//        #expect(mockSynthesizer.stopCallCount == 1)
//    }
//    
//    @Test("Clear cache allows repetition")
//    func clearCacheAllowsRepetition() {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let controller = SpeechController(synthesizer: mockSynthesizer)
//        
//        _ = controller.speak("Hello")
//        let task1 = controller.speak("Hello") // Should be nil
//        
//        controller.clearSpokenCache()
//        
//        let task2 = controller.speak("Hello") // Should work
//        
//        #expect(task1 == nil)
//        #expect(task2 != nil)
//        #expect(mockSynthesizer.spokenUtterances.count == 2)
//    }
//    
//    @Test("Completion callback updates state")
//    func completionUpdatesState() async throws {
//        let mockSynthesizer = MockSpeechSynthesizer()
//        let coordinator = SpeechCoordinator()
//        let controller = SpeechController(
//            synthesizer: mockSynthesizer,
//            coordinator: coordinator
//        )
//        
//        _ = controller.speak("Test")
//        #expect(controller.isSpeaking == true)
//        
//        // Wait for simulated completion
//        try await Task.sleep(nanoseconds: 200_000_000)
//        
//        #expect(controller.isSpeaking == false)
//        #expect(controller.currentText == nil)
//    }
//}

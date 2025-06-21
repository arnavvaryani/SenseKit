//
//  EdgeCaseTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Testing
import Foundation
import AVFoundation
@testable import SenseKit

@Suite("Edge Case Tests")
@MainActor
struct EdgeCaseTests {
    
    @Test("Empty speech text handling")
    func emptySpeechText() {
        let controller = SpeechController()
        
        let task1 = controller.speak("")
        let task2 = controller.speak("   ")
        
        #expect(task1 != nil) // Empty strings are still spoken
        #expect(task2 != nil)
    }
    
    @Test("Very long speech text")
    func veryLongSpeechText() {
        let controller = SpeechController()
        let longText = String(repeating: "Hello ", count: 1000)
        
        let task = controller.speak(longText)
        
        #expect(task != nil)
        #expect(controller.currentText == longText)
    }
    
//    @Test("Rapid start/stop cycles")
//    func rapidStartStop() async throws {
//        let mockEngine = MockAudioEngine()
//        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
//        
//        for _ in 0..<10 {
//            try generator.start()
//            generator.stop()
//        }
//        
//        #expect(mockEngine.startCallCount == 10)
//        #expect(mockEngine.stopCallCount == 10)
//    }
//    
    @Test("Nil callbacks don't crash")
    func nilCallbacksHandling() async throws {
        let coordinator = SpeechCoordinator()
        coordinator.onUtteranceCompleted = nil
        
        // This should not crash
        coordinator.speechSynthesizer(
            AVSpeechSynthesizer(),
            didFinish: AVSpeechUtterance(string: "Test")
        )
        
        #expect(true) // If we get here, no crash occurred
    }
}

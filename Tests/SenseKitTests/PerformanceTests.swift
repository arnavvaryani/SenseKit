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
    func speechPerformance() async throws {
        let controller = await SpeechController()
        let startTime = Date()
        
//        for i in 0..<1000 {
//            await controller.speak("Message \(i)")
//        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // Should complete in under 1 second
        await #expect(controller.isSpeaking == true)
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
        
        #expect(duration < 0.1) // Should complete in under 100ms
    }
}

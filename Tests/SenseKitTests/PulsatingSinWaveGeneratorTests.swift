//
//  PulsatingSinWaveGeneratorTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


//import Testing
//import Foundation
//import AVFoundation
//@testable import SenseKit
//
//@Suite("PulsatingSinWaveGenerator Tests")
//struct PulsatingSinWaveGeneratorTests {
//    
//    @Test("Initialize creates audio buffer and haptic pattern")
//    func initializeCreatesResources() throws {
//        let mockAudioEngine = MockAudioEngine()
//        let mockPlayer = MockAudioPlayerNode()
//        let mockHapticEngine = MockHapticEngine()
//        
//        let generator = try PulsatingSinWaveGenerator(
//            frequency: 400,
//            sampleRate: 44100,
//            amplitude: 1.0,
//            pulseInterval: 0.2,
//            pulseDuration: 0.1,
//            audioEngine: mockAudioEngine,
//            player: mockPlayer,
//            hapticEngine: mockHapticEngine
//        )
//        
//        #expect(generator != nil)
//        #expect(mockAudioEngine.attachedNodes.count == 1)
//        #expect(mockHapticEngine.startCallCount == 1)
//    }
//    
//    @Test("Start begins pulsing")
//    func startBeginsPulsing() async throws {
//        let mockAudioEngine = MockAudioEngine()
//        let mockPlayer = MockAudioPlayerNode()
//        let mockHapticEngine = MockHapticEngine()
//        
//        let generator = try PulsatingSinWaveGenerator(
//            pulseInterval: 0.1,
//            pulseDuration: 0.05,
//            audioEngine: mockAudioEngine,
//            player: mockPlayer,
//            hapticEngine: mockHapticEngine
//        )
//        
//        try generator.start()
//        
//        // Wait for at least one pulse
//        try await Task.sleep(nanoseconds: 150_000_000)
//        
//        #expect(mockPlayer.playCallCount >= 1)
//        #expect(mockPlayer.scheduledBuffers.count >= 1)
//        #expect(mockHapticEngine.createdPlayers.first?.startCallCount ?? 0 >= 1)
//    }
//    
//    @Test("Stop cancels pulsing")
//    func stopCancelsPulsing() async throws {
//        let mockAudioEngine = MockAudioEngine()
//        let mockPlayer = MockAudioPlayerNode()
//        let mockHapticEngine = MockHapticEngine()
//        
//        let generator = try PulsatingSinWaveGenerator(
//            pulseInterval: 0.1,
//            audioEngine: mockAudioEngine,
//            player: mockPlayer,
//            hapticEngine: mockHapticEngine
//        )
//        
//        try generator.start()
//        
//        // Let it pulse once
//        try await Task.sleep(nanoseconds: 150_000_000)
//        
//        let playCountBefore = mockPlayer.playCallCount
//        
//        generator.stop()
//        
//        // Wait to ensure no more pulses
//        try await Task.sleep(nanoseconds: 200_000_000)
//        
//        #expect(mockPlayer.playCallCount == playCountBefore)
//        #expect(mockHapticEngine.stopCallCount == 1)
//    }
//}

//
//  SinWaveGeneratorTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Testing
import Foundation
import AVFoundation
@testable import SenseKit

@Suite("SinWaveGenerator Tests")
struct SinWaveGeneratorTests {
    
    @Test("Initialize with parameters")
    func initializeWithParameters() {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(
            frequency: 440,
            sampleRate: 44100,
            audioEngine: mockEngine
        )
        
        #expect(generator != nil)
        #expect(mockEngine.attachedNodes.count == 1)
        #expect(mockEngine.connections.count == 1)
    }
    
    @Test("Start begins audio engine")
    func startBeginsEngine() throws {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
        
        try generator.start()
        
        #expect(mockEngine.isStarted == true)
        #expect(mockEngine.startCallCount == 1)
    }
    
    @Test("Stop stops audio engine")
    func stopStopsEngine() throws {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
        
        try generator.start()
        generator.stop()
        
        #expect(mockEngine.isStarted == false)
        #expect(mockEngine.stopCallCount == 1)
    }
    
    @Test("Multiple start calls are idempotent")
    func multipleStartsIdempotent() throws {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
        
        try generator.start()
        try generator.start()
        try generator.start()
        
        #expect(mockEngine.startCallCount == 1)
    }
    
    @Test("Deinit cleans up nodes")
    func deinitCleansUpNodes() throws {
        let mockEngine = MockAudioEngine()
        
        do {
            let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
            try generator.start()
            #expect(mockEngine.attachedNodes.count == 1)
        }
        
        // Generator should be deallocated, nodes cleaned up
        #expect(mockEngine.attachedNodes.count == 0)
        #expect(mockEngine.connections.count == 0)
    }
}

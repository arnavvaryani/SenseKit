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

    @Test("Initialize attaches and connects a source node")
    func initializeWithParameters() {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, sampleRate: 44_100, audioEngine: mockEngine)

        // Keep the generator alive across the assertions; otherwise deinit would
        // detach/disconnect the node before we check.
        withExtendedLifetime(generator) {
            #expect(mockEngine.attachedNodes.count == 1)
            #expect(mockEngine.connections.count == 1)
        }
    }

    @Test("Start begins audio engine")
    func startBeginsEngine() throws {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)

        try generator.start()

        #expect(mockEngine.isStarted)
        #expect(mockEngine.startCallCount == 1)
    }

    @Test("Stop stops audio engine")
    func stopStopsEngine() throws {
        let mockEngine = MockAudioEngine()
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)

        try generator.start()
        generator.stop()

        #expect(!mockEngine.isStarted)
        #expect(mockEngine.stopCallCount == 1)
    }

    @Test("Start propagates engine errors")
    func startPropagatesErrors() {
        let mockEngine = MockAudioEngine()
        mockEngine.shouldThrowOnStart = true
        let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)

        #expect(throws: (any Error).self) {
            try generator.start()
        }
    }

    @Test("Deinit detaches and disconnects nodes")
    func deinitCleansUpNodes() throws {
        let mockEngine = MockAudioEngine()

        do {
            let generator = SinWaveGenerator(frequency: 440, audioEngine: mockEngine)
            try generator.start()
            #expect(mockEngine.attachedNodes.count == 1)
        }

        // Generator deallocated -> nodes detached and disconnected.
        #expect(mockEngine.attachedNodes.isEmpty)
        #expect(mockEngine.connections.isEmpty)
    }
}

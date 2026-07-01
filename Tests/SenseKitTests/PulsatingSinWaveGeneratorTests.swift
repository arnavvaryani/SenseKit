//
//  PulsatingSinWaveGeneratorTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Testing
import Foundation
import AVFoundation
@testable import SenseKit

@Suite("PulsatingSinWaveGenerator Tests")
struct PulsatingSinWaveGeneratorTests {

    private func makeGenerator(
        pulseInterval: TimeInterval = 0.2,
        pulseDuration: TimeInterval = 0.1
    ) throws -> (PulsatingSinWaveGenerator, MockAudioEngine, MockAudioPlayerNode, MockHapticEngine) {
        let audioEngine = MockAudioEngine()
        let player = MockAudioPlayerNode()
        let hapticEngine = MockHapticEngine()
        let generator = try PulsatingSinWaveGenerator(
            frequency: 400,
            sampleRate: 44_100,
            amplitude: 1.0,
            pulseInterval: pulseInterval,
            pulseDuration: pulseDuration,
            audioEngine: audioEngine,
            player: player,
            hapticEngine: hapticEngine
        )
        return (generator, audioEngine, player, hapticEngine)
    }

    @Test("Initialize creates audio buffer and haptic player")
    func initializeCreatesResources() throws {
        let (_, audioEngine, _, hapticEngine) = try makeGenerator()

        #expect(audioEngine.attachedNodes.count == 1)
        #expect(audioEngine.connections.count == 1)
        #expect(hapticEngine.createdPlayers.count == 1)
    }

    @Test("Start fires an immediate audio + haptic pulse")
    func startFiresImmediatePulse() throws {
        let (generator, _, player, hapticEngine) = try makeGenerator()

        try generator.start()

        // The first pulse is dispatched synchronously before any timer is scheduled.
        #expect(player.playCallCount >= 1)
        #expect(player.scheduledBuffers.count >= 1)
        #expect((hapticEngine.createdPlayers.first?.startCallCount ?? 0) >= 1)

        generator.stop()
    }

    @Test("Stop tears down audio and haptic engines")
    func stopTearsDown() throws {
        let (generator, audioEngine, player, hapticEngine) = try makeGenerator()

        try generator.start()
        generator.stop()

        #expect(!audioEngine.isStarted)
        #expect(player.stopCallCount >= 1)
        #expect(hapticEngine.stopCallCount == 1)
    }
}

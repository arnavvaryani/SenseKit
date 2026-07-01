//
//  HapticControllerTests.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Testing
import Foundation
import CoreHaptics
@testable import SenseKit

@Suite("HapticController Tests")
struct HapticControllerTests {

    @Test("Initialize with custom engine does not start it")
    func initializeWithCustomEngine() throws {
        let mockEngine = MockHapticEngine()
        _ = try HapticController(engine: mockEngine)

        #expect(mockEngine.startCallCount == 0)
    }

    @Test("Prepare starts engine")
    func prepareStartsEngine() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)

        try controller.prepare()

        #expect(mockEngine.startCallCount == 1)
        #expect(mockEngine.isStarted)
    }

    @Test("Prepare throws when engine unavailable")
    func prepareThrowsWhenEngineUnavailable() throws {
        let mockEngine = MockHapticEngine()
        mockEngine.shouldThrowOnStart = true
        let controller = try HapticController(engine: mockEngine)

        #expect(throws: HapticError.self) {
            try controller.prepare()
        }
    }

    @Test("Play continuous creates a pattern player")
    func playContinuousCreatesPattern() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(
            engine: mockEngine,
            config: HapticConfiguration(
                defaultIntensity: 0.8,
                defaultSharpness: 0.6,
                continuousDuration: 5.0
            )
        )

        try controller.prepare()
        _ = try controller.playContinuous()

        #expect(mockEngine.createdPlayers.count == 1)
        #expect(mockEngine.createdPlayers.first?.startCallCount == 1)
    }

    @Test("Play without prepare throws engineNotPrepared")
    func playWithoutPrepareThrows() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)

        #expect(throws: HapticError.self) {
            _ = try controller.playContinuous()
        }
    }

    @Test("Task cancellation stops player")
    func taskCancellationStopsPlayer() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)

        try controller.prepare()
        let task = try controller.playContinuous()

        let player = mockEngine.createdPlayers.first
        #expect(player?.isPlaying == true)

        task.cancel()

        #expect(player?.stopCallCount == 1)
    }

    @Test("Stop cleans up all players")
    func stopCleansUpPlayers() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)

        try controller.prepare()
        _ = try controller.playContinuous()
        _ = try controller.playPulse()

        #expect(mockEngine.createdPlayers.count == 2)

        controller.stop()

        #expect(mockEngine.stopCallCount == 1)
        #expect(mockEngine.createdPlayers.allSatisfy { $0.stopCallCount >= 1 })
    }

    @Test("Deinit cleans up")
    func deinitCleansUp() throws {
        let mockEngine = MockHapticEngine()

        do {
            let controller = try HapticController(engine: mockEngine)
            try controller.prepare()
            _ = try controller.playContinuous()
        }

        // Controller deallocated here -> stop() called from deinit.
        #expect(mockEngine.stopCallCount == 1)
    }
}

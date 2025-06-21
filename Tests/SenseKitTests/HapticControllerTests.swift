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
    
    @Test("Initialize with custom engine")
    func initializeWithCustomEngine() throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)
        
        #expect(controller != nil)
    }
    
    @Test("Prepare starts engine")
    func prepareStartsEngine() async throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)
        
        try controller.prepare()
        
        #expect(mockEngine.startCallCount == 1)
        #expect(mockEngine.isStarted == true)
    }
    
    @Test("Prepare throws when engine unavailable")
    func prepareThrowsWhenEngineUnavailable() async throws {
        let mockEngine = MockHapticEngine()
        mockEngine.shouldThrowOnStart = true
        let controller = try HapticController(engine: mockEngine)
        
        #expect(throws: HapticError.self) {
            try controller.prepare()
        }
    }
    
    @Test("Play continuous creates correct pattern")
    func playContinuousCreatesPattern() async throws {
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
        let task = try controller.playContinuous()
        
        #expect(mockEngine.createdPlayers.count == 1)
        #expect(mockEngine.createdPlayers.first?.startCallCount == 1)
        #expect(task != nil)
    }
    
    @Test("Play without prepare throws")
    func playWithoutPrepareThrows() async throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)
        
      //  #expect(throws: HapticError.engineNotPrepared.self) {
            try controller.playContinuous()
        }
    }
    
    @Test("Task cancellation stops player")
    func taskCancellationStopsPlayer() async throws {
        let mockEngine = MockHapticEngine()
        let controller = try HapticController(engine: mockEngine)
        
        try controller.prepare()
        let task = try controller.playContinuous()
        
        let player = mockEngine.createdPlayers.first
        #expect(player?.isPlaying == true)
        
        task.cancel()
        
        // Give time for async cancellation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(player?.stopCallCount == 1)
    }
    
    @Test("Stop cleans up all players")
    func stopCleansUpPlayers() async throws {
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
    func deinitCleansUp() async throws {
        let mockEngine = MockHapticEngine()
        
        do {
            let controller = try HapticController(engine: mockEngine)
            try controller.prepare()
            _ = try controller.playContinuous()
        }
        
        // Controller should be deallocated here
        #expect(mockEngine.stopCallCount == 1)
    }
//}

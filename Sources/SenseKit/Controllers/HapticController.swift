//
//  HapticController 2.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import CoreHaptics
import Foundation

/// Represents a haptic playback task that can be cancelled
public class HapticTask {
    private let player: HapticPatternPlayerProtocol
    private var isCancelled = false
    
    init(player: HapticPatternPlayerProtocol) {
        self.player = player
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        try? player.stop(atTime: CHHapticTimeImmediate)
    }
}

/// Main public API for playing haptic patterns
public class HapticController {
    private let engine: HapticEngineProtocol
    private let config: HapticConfiguration
    private var players: [HapticPatternPlayerProtocol] = []
    private var isPrepared = false
    private var currentContinuousTask: HapticTask?
    private var currentPulseTask: HapticTask?
    
    /// Initialize with optional custom engine
    public init(
        engine: HapticEngineProtocol? = nil,
        config: HapticConfiguration = .init()
    ) throws {
        if let engine = engine {
            self.engine = engine
        } else {
            self.engine = try CHHapticEngineWrapper()
        }
        self.config = config
    }
    
    deinit {
        stop()
    }
    
    /// Must be called before any play methods
    public func prepare() throws {
        guard !isPrepared else { return }
        try engine.start()
        isPrepared = true
    }
    
    /// Play a continuous haptic
    @discardableResult
    public func playContinuous() throws -> HapticTask {
        stopActiveHaptics()
        guard isPrepared else { throw HapticError.engineNotPrepared }
        
        // Cancel any existing continuous haptic
        currentContinuousTask?.cancel()
        currentContinuousTask = nil
        
        let pattern = try HapticPatternBuilder.continuous(
            intensity: adjustedIntensity,
            sharpness: config.defaultSharpness,
        )
        
        let task = try play(pattern: pattern)
        currentContinuousTask = task
        return task
    }
    
    /// Play a pulse pattern
    @discardableResult
    public func playPulse() throws -> HapticTask {
        stopActiveHaptics()
        guard isPrepared else { throw HapticError.engineNotPrepared }
        
        // Cancel any existing pulse haptic
        currentPulseTask?.cancel()
        currentPulseTask = nil
        
        let pattern = try HapticPatternBuilder.pulse(
            intensity: 1.0,
            sharpness: 0.8,
            count: 1000,
        )
        
        let task = try play(pattern: pattern)
        currentPulseTask = task
        return task
    }
    
    /// Stop all haptics and the engine
    public func stop() {
        currentContinuousTask?.cancel()
        currentPulseTask?.cancel()
        currentContinuousTask = nil
        currentPulseTask = nil
        
        players.forEach { try? $0.stop(atTime: CHHapticTimeImmediate) }
        players.removeAll()
        isPrepared = false
        engine.stop(completionHandler: nil)
    }
    
    /// Stop only the active haptics, keep engine running
    public func stopActiveHaptics() {
        currentContinuousTask?.cancel()
        currentPulseTask?.cancel()
        currentContinuousTask = nil
        currentPulseTask = nil
        
        // Clean up finished players
        players.removeAll { player in
            do {
                try player.stop(atTime: CHHapticTimeImmediate)
                return true
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Private
    
    private var adjustedIntensity: Float {
        guard config.respectSystemSettings else { return config.defaultIntensity }
        // In real app, check system haptic settings
        return config.defaultIntensity
    }
    
    private func play(pattern: CHHapticPattern) throws -> HapticTask {
        let player = try engine.makePlayer(with: pattern)
        players.append(player)
        
        do {
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Remove the player if start failed
            players.removeAll { $0 === player }
            throw HapticError.playbackFailed(error)
        }
        
        return HapticTask(player: player)
    }
}

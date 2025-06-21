//
//  AudioEngineProtocol.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import AVFoundation
import CoreHaptics

/// Abstraction over AVAudioEngine
public protocol AudioEngineProtocol: AnyObject {
    var mainMixerNode: AVAudioMixerNode { get }
    func attach(_ node: AVAudioNode)
    func connect(_ node: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat?)
    func start() throws
    func stop()
    func disconnectNodeOutput(_ node: AVAudioNode)
    func detach(_ node: AVAudioNode)
}

/// Abstraction over AVAudioPlayerNode
public protocol AudioPlayerNodeProtocol: AnyObject {
    var avAudioNode: AVAudioNode { get }
    func scheduleBuffer(_ buffer: AVAudioPCMBuffer,
                        at when: AVAudioTime?,
                        options: AVAudioPlayerNodeBufferOptions,
                        completionHandler: (() -> Void)?)
    func play()
    func stop()
}

/// Abstraction over CHHapticEngine
public protocol HapticEngineProtocol: AnyObject {
    func start() throws
    func stop(completionHandler: CHHapticEngine.CompletionHandler?)
    func makePlayer(with pattern: CHHapticPattern) throws -> HapticPatternPlayerProtocol
}

/// Abstraction over CHHapticPatternPlayer
public protocol HapticPatternPlayerProtocol: AnyObject {
    func start(atTime time: TimeInterval) throws
    func stop(atTime time: TimeInterval) throws
}

/// A simple public API for any "wave generator"
public protocol WaveGeneratorProtocol: AnyObject {
    func start() throws
    func stop()
}

// MARK: - Conformances

extension AVAudioEngine: AudioEngineProtocol {}
extension AVAudioPlayerNode: AudioPlayerNodeProtocol {
    public var avAudioNode: AVAudioNode { self }
}

// MARK: - Wrappers for Apple Types

/// Wrapper to make CHHapticEngine conform to HapticEngineProtocol
public final class CHHapticEngineWrapper: HapticEngineProtocol {
    private let engine: CHHapticEngine
    
    public init() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw HapticError.engineUnavailable
        }
        self.engine = try CHHapticEngine()
    }
    
    public func start() throws {
        try engine.start()
    }
    
    public func stop(completionHandler: CHHapticEngine.CompletionHandler?) {
        engine.stop(completionHandler: completionHandler)
    }
    
    public func makePlayer(with pattern: CHHapticPattern) throws -> HapticPatternPlayerProtocol {
        return try CHHapticPatternPlayerWrapper(player: engine.makePlayer(with: pattern))
    }
}

/// Wrapper to make CHHapticPatternPlayer conform to HapticPatternPlayerProtocol
public final class CHHapticPatternPlayerWrapper: HapticPatternPlayerProtocol {
    private let player: CHHapticPatternPlayer
    
    init(player: CHHapticPatternPlayer) {
        self.player = player
    }
    
    public func start(atTime time: TimeInterval) throws {
        try player.start(atTime: time)
    }
    
    public func stop(atTime time: TimeInterval) throws {
        try player.stop(atTime: time)
    }
}






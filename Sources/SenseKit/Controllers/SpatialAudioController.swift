//
//  SpatialAudioController.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Foundation
import AVFoundation
import AVFAudio

// MARK: - Spatial Audio Configuration
public struct SpatialAudioConfiguration {
    public var sampleRate: Double
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm
    public var reverbPreset: AVAudioUnitReverbPreset
    public var reverbLevel: Float
    public var distanceAttenuationModel: AVAudioEnvironmentDistanceAttenuationModel
    
    public init(
        sampleRate: Double = 22050.0,
        renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .HRTFHQ,
        reverbPreset: AVAudioUnitReverbPreset = .smallRoom,
        reverbLevel: Float = 0.5,
        distanceAttenuationModel: AVAudioEnvironmentDistanceAttenuationModel = .exponential
    ) {
        self.sampleRate = sampleRate
        self.renderingAlgorithm = renderingAlgorithm
        self.reverbPreset = reverbPreset
        self.reverbLevel = reverbLevel
        self.distanceAttenuationModel = distanceAttenuationModel
    }
}

// MARK: - Spatial Audio Error
public enum SpatialAudioError: LocalizedError {
    case engineNotPrepared
    case engineStartFailed(Error)
    case bufferCreationFailed
    case invalidFormat
    
    public var errorDescription: String? {
        switch self {
        case .engineNotPrepared:
            return "Spatial audio engine must be prepared before use"
        case .engineStartFailed(let error):
            return "Failed to start spatial audio engine: \(error.localizedDescription)"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .invalidFormat:
            return "Invalid audio format"
        }
    }
}

// MARK: - Direction Enum
public enum SpatialDirection: String, CaseIterable {
    case left = "Left"
    case right = "Right"
    case up = "Up"
    case down = "Down"
    case center = "Center"
    
    public var position: AVAudio3DPoint {
        switch self {
        case .left: return AVAudio3DPoint(x: -5, y: 0, z: 0)
        case .right: return AVAudio3DPoint(x: 5, y: 0, z: 0)
        case .up: return AVAudio3DPoint(x: 0, y: 0, z: -7)
        case .down: return AVAudio3DPoint(x: 0, y: 0, z: 3)
        case .center: return AVAudio3DPoint(x: 0, y: 0, z: 0)
        }
    }
}

// MARK: - Spatial Audio Task
public class SpatialAudioTask {
    private weak var playerNode: AudioPlayerNodeProtocol?
    private var isCancelled = false
    
    init(playerNode: AudioPlayerNodeProtocol) {
        self.playerNode = playerNode
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        playerNode?.stop()
    }
}

// MARK: - Spatial Audio Controller Protocol
public protocol SpatialAudioControllerProtocol: AnyObject {
    func prepare() throws
    func stop()
    func playBeep(direction: SpatialDirection, frequency: Double, duration: Double) throws -> SpatialAudioTask
    func playBeep(at position: AVAudio3DPoint, frequency: Double, duration: Double) throws -> SpatialAudioTask
    func setPlayerPosition(_ position: AVAudio3DPoint)
    func playSpatializedBuffer(_ buffer: AVAudioPCMBuffer, at position: AVAudio3DPoint?) throws -> SpatialAudioTask
}

// MARK: - Spatial Audio Controller
public class SpatialAudioController: SpatialAudioControllerProtocol {
    // MARK: - Properties
    private let audioEngine: AudioEngineProtocol
    private let environment: AVAudioEnvironmentNode
    private let audioPlayerNode: AudioPlayerNodeProtocol
    private let audioSession: AVAudioSession
    private let config: SpatialAudioConfiguration
    private var isPrepared = false
    
    // MARK: - Initialization
    public init(
        audioEngine: AudioEngineProtocol? = nil,
        audioPlayerNode: AudioPlayerNodeProtocol? = nil,
        audioSession: AVAudioSession? = nil,
        config: SpatialAudioConfiguration = .init()
    ) {
        self.audioEngine = audioEngine ?? AVAudioEngine()
        self.audioPlayerNode = audioPlayerNode ?? AVAudioPlayerNode()
        self.audioSession = audioSession ?? (AVAudioSession.sharedInstance())
        self.environment = AVAudioEnvironmentNode()
        self.config = config
        
        setupAudioEngine()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    public func prepare() throws {
        guard !isPrepared else { return }
        
        // Configure audio session
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)
        
        // Start engine
        do {
            try audioEngine.start()
            isPrepared = true
        } catch {
            throw SpatialAudioError.engineStartFailed(error)
        }
    }
    
    public func stop() {
        audioPlayerNode.stop()
        audioEngine.stop()
        isPrepared = false
    }
    
    @discardableResult
    public func playBeep(direction: SpatialDirection, frequency: Double = 440, duration: Double = 0.2) throws -> SpatialAudioTask {
        return try playBeep(at: direction.position, frequency: frequency, duration: duration)
    }
    
    @discardableResult
    public func playBeep(at position: AVAudio3DPoint, frequency: Double = 440, duration: Double = 0.2) throws -> SpatialAudioTask {
        guard isPrepared else { throw SpatialAudioError.engineNotPrepared }
        
        guard let buffer = createBeepBuffer(frequency: frequency, duration: duration) else {
            throw SpatialAudioError.bufferCreationFailed
        }
        
        return try playSpatializedBuffer(buffer, at: position)
    }
    
    public func setPlayerPosition(_ position: AVAudio3DPoint) {
        if let playerNode = audioPlayerNode as? AVAudioPlayerNode {
            playerNode.position = position
        }
    }
    
    @discardableResult
    public func playSpatializedBuffer(_ buffer: AVAudioPCMBuffer, at position: AVAudio3DPoint? = nil) throws -> SpatialAudioTask {
        guard isPrepared else { throw SpatialAudioError.engineNotPrepared }
        
        if let position = position {
            setPlayerPosition(position)
        }
        
        audioPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        audioPlayerNode.play()
        
        return SpatialAudioTask(playerNode: audioPlayerNode)
    }
    
    // MARK: - Private Methods
    private func setupAudioEngine() {
        // Attach nodes
        audioEngine.attach(environment)
        audioEngine.attach(audioPlayerNode.avAudioNode)
        
        // Configure player node
        if let playerNode = audioPlayerNode as? AVAudioPlayerNode {
            playerNode.renderingAlgorithm = config.renderingAlgorithm
            playerNode.sourceMode = .spatializeIfMono
        }
        
        // Configure environment
        environment.renderingAlgorithm = config.renderingAlgorithm
        environment.sourceMode = .spatializeIfMono
        environment.distanceAttenuationParameters.distanceAttenuationModel = config.distanceAttenuationModel
        environment.reverbParameters.enable = true
        environment.reverbParameters.loadFactoryReverbPreset(config.reverbPreset)
        environment.reverbParameters.level = config.reverbLevel
        
        // Create audio format
        let monoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: config.sampleRate,
            channels: 1,
            interleaved: false
        )!
        
        // Connect nodes
        audioEngine.connect(audioPlayerNode.avAudioNode, to: environment, format: monoFormat)
        audioEngine.connect(environment, to: audioEngine.mainMixerNode, format: nil)
        
        // Set listener position
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
    }
    
    private func createBeepBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: config.sampleRate,
            channels: 1,
            interleaved: false
        )
        
        guard let format = format else { return nil }
        
        let frameCount = AVAudioFrameCount(config.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        
        buffer.frameLength = frameCount
        
        let thetaIncrement = 2.0 * Double.pi * frequency / config.sampleRate
        var theta = 0.0
        
        guard let channels = buffer.floatChannelData else { return nil }
        
        for frame in 0..<Int(frameCount) {
            channels[0][frame] = Float(sin(theta))
            theta += thetaIncrement
        }
        
        return buffer
    }
}

// MARK: - Helper Extensions for CommonMapViewModel
public extension SpatialAudioController {
    
    func playBeep(for direction: String, frequency: Double = 440, duration: Double = 0.2) throws -> SpatialAudioTask {
        if let spatialDirection = SpatialDirection(rawValue: direction) {
            return try playBeep(direction: spatialDirection, frequency: frequency, duration: duration)
        } else {
            // Fallback to center for unknown directions
            return try playBeep(direction: .center, frequency: frequency, duration: duration)
        }
    }
    
    func setPlayerPosition(for direction: String) {
        if let spatialDirection = SpatialDirection(rawValue: direction) {
            setPlayerPosition(spatialDirection.position)
        } else {
            setPlayerPosition(SpatialDirection.center.position)
        }
    }
}

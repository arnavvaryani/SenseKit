//
//  SpatialSpeechController.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/23/25.
//

import AVFoundation
import simd
import Observation

/// Represents a 3D position in space
public struct SpatialPosition: Sendable {
    public let x: Float  // Left(-) to Right(+)
    public let y: Float  // Down(-) to Up(+)
    public let z: Float  // Behind(-) to Front(+)
    
    public init(x: Float = 0, y: Float = 0, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    // Convenience positions
    public nonisolated(unsafe) static let center = SpatialPosition(x: 0, y: 0, z: 0)
    public nonisolated(unsafe) static let left = SpatialPosition(x: -1, y: 0, z: 0)
    public nonisolated(unsafe) static let right = SpatialPosition(x: 1, y: 0, z: 0)
    public nonisolated(unsafe) static let front = SpatialPosition(x: 0, y: 0, z: 1)
    public nonisolated(unsafe) static let back = SpatialPosition(x: 0, y: 0, z: -1)
    public nonisolated(unsafe) static let above = SpatialPosition(x: 0, y: 1, z: 0)
    public nonisolated(unsafe) static let below = SpatialPosition(x: 0, y: -1, z: 0)
}

/// Speech item with spatial positioning
public struct SpatialSpeechItem: Sendable {
    public let text: String
    public let position: SpatialPosition
    public let priority: Int
    public let allowRepeat: Bool
    
    public init(
        text: String,
        position: SpatialPosition = .center,
        priority: Int = 0,
        allowRepeat: Bool = false
    ) {
        self.text = text
        self.position = position
        self.priority = priority
        self.allowRepeat = allowRepeat
    }
}

@MainActor
@Observable
public class SpatialSpeechController {
    // Dependencies
    private nonisolated(unsafe) let audioEngine: AVAudioEngine
    private nonisolated(unsafe) let speechSynthesizer: AVSpeechSynthesizer
    private let spatialMixer: AVAudioEnvironmentNode
    
    // Queue management
    private var speechQueue: [SpatialSpeechItem] = []
    private var spokenTexts = Set<String>()
    private var isProcessing = false
    
    // Audio nodes for spatial positioning (not main actor isolated for cleanup)
    private nonisolated(unsafe) var playerNodes: [AVAudioPlayerNode] = []
    private var availableNodes: [AVAudioPlayerNode] = []
    private var activeNodes: [String: AVAudioPlayerNode] = [:]
    
    // Public state
    public private(set) var isPlaying = false
    public private(set) var currentItem: SpatialSpeechItem?
    public private(set) var queueCount: Int = 0
    
    // Configuration
    public var maxConcurrentSpeech: Int = 3
    public var spatialDistance: Float = 1.0
    
    public init(maxNodes: Int = 5) {
        self.audioEngine = AVAudioEngine()
        self.speechSynthesizer = AVSpeechSynthesizer()
        self.spatialMixer = AVAudioEnvironmentNode()
        
        setupAudioEngine(maxNodes: maxNodes)
        setupSpatialEnvironment()
    }
    
    deinit {
        // Can't call MainActor methods from deinit
        // Clean up synchronously available resources
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Stop audio nodes - playerNodes is nonisolated(unsafe) so accessible here
        playerNodes.forEach { node in
            node.stop()
            node.reset()
        }
        
        audioEngine.stop()
    }
    
    // MARK: - Public API
    
    /// Add a speech item to the spatial queue
    public func enqueue(_ item: SpatialSpeechItem) {
        // Check if we should skip repeated text
        if !item.allowRepeat && spokenTexts.contains(item.text) {
            return
        }
        
        // Insert based on priority (higher priority first)
        let insertIndex = speechQueue.firstIndex { $0.priority < item.priority } ?? speechQueue.count
        speechQueue.insert(item, at: insertIndex)
        
        queueCount = speechQueue.count
        processQueue()
    }
    
    /// Convenience method to add speech with position
    public func speak(
        _ text: String,
        at position: SpatialPosition = .center,
        priority: Int = 0,
        allowRepeat: Bool = false
    ) {
        let item = SpatialSpeechItem(
            text: text,
            position: position,
            priority: priority,
            allowRepeat: allowRepeat
        )
        enqueue(item)
    }
    
    /// Clear all queued speech
    public func clearQueue() {
        speechQueue.removeAll()
        queueCount = 0
    }
    
    /// Stop all speech immediately
    public func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Stop all active nodes
        activeNodes.values.forEach { node in
            node.stop()
            node.reset()
        }
        
        // Return nodes to available pool
        availableNodes.append(contentsOf: activeNodes.values)
        activeNodes.removeAll()
        
        clearQueue()
        isPlaying = false
        isProcessing = false
        currentItem = nil
        
        audioEngine.stop()
    }
    
    /// Update listener position (for spatial audio)
    public func updateListenerPosition(
        position: SpatialPosition = .center,
        orientation: simd_float3 = [0, 0, 1]
    ) {
        spatialMixer.listenerPosition = AVAudio3DPoint(
            x: position.x,
            y: position.y,
            z: position.z
        )
        spatialMixer.listenerVectorOrientation = AVAudio3DVectorOrientation(
            forward: AVAudio3DVector(x: orientation.x, y: orientation.y, z: orientation.z),
            up: AVAudio3DVector(x: 0, y: 1, z: 0)
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine(maxNodes: Int) {
        // Create player nodes
        for _ in 0..<maxNodes {
            let node = AVAudioPlayerNode()
            playerNodes.append(node)
            availableNodes.append(node)
            audioEngine.attach(node)
        }
        
        // Connect spatial mixer
        audioEngine.attach(spatialMixer)
        audioEngine.connect(spatialMixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            try audioEngine.start()
        } catch {
            print("Failed to setup audio engine: \(error)")
        }
    }
    
    private func setupSpatialEnvironment() {
        // Configure spatial audio environment
        spatialMixer.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        spatialMixer.listenerVectorOrientation = AVAudio3DVectorOrientation(
            forward: AVAudio3DVector(x: 0, y: 0, z: 1),
            up: AVAudio3DVector(x: 0, y: 1, z: 0)
        )
        
        // Set distance attenuation
        spatialMixer.distanceAttenuationParameters.maximumDistance = 10.0
        spatialMixer.distanceAttenuationParameters.referenceDistance = 1.0
        spatialMixer.distanceAttenuationParameters.rolloffFactor = 1.0
        
        // Enable reverb for spatial realism
        spatialMixer.reverbParameters.enable = true
        spatialMixer.reverbParameters.level = 20
    }
    
    private func processQueue() {
        guard !isProcessing,
              !speechQueue.isEmpty,
              activeNodes.count < maxConcurrentSpeech,
              let availableNode = availableNodes.first else {
            return
        }
        
        isProcessing = true
        let item = speechQueue.removeFirst()
        queueCount = speechQueue.count
        
        // Mark as spoken
        spokenTexts.insert(item.text)
        currentItem = item
        isPlaying = true
        
        // Remove from available and add to active
        availableNodes.removeFirst()
        activeNodes[item.text] = availableNode
        
        synthesizeSpatialSpeech(item, using: availableNode)
    }
    
    private func synthesizeSpatialSpeech(_ item: SpatialSpeechItem, using node: AVAudioPlayerNode) {
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        // Position the node in 3D space
        positionNode(node, at: item.position)
        
        // Synthesize to PCM buffer
        speechSynthesizer.write(utterance) { [weak self] buffer in
            guard let self = self,
                  let pcmBuffer = buffer as? AVAudioPCMBuffer,
                  pcmBuffer.frameLength > 0 else { return }
            
            Task { @MainActor in
                // Schedule buffer for spatial playback
                node.scheduleBuffer(pcmBuffer) {
                    Task { @MainActor in
                        self.handleSpeechCompletion(for: item, node: node)
                    }
                }
                
                if !node.isPlaying {
                    node.play()
                }
            }
        }
    }
    
    private func positionNode(_ node: AVAudioPlayerNode, at position: SpatialPosition) {
        // Connect node to spatial mixer if not already connected
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        
        if !audioEngine.attachedNodes.contains(node) {
            audioEngine.attach(node)
        }
        
        // Disconnect and reconnect to update spatial position
        audioEngine.disconnectNodeInput(node)
        audioEngine.connect(node, to: spatialMixer, format: format)
        
        // Set 3D position using AVAudio3DMixing protocol
        if let mixingNode = node as? AVAudio3DMixing {
            mixingNode.position = AVAudio3DPoint(
                x: position.x * spatialDistance,
                y: position.y * spatialDistance,
                z: position.z * spatialDistance
            )
            
            // Configure 3D mixing parameters
            mixingNode.renderingAlgorithm = .sphericalHead
            mixingNode.rate = 1.0
            mixingNode.reverbBlend = 0.2
        }
    }
    
    private func handleSpeechCompletion(for item: SpatialSpeechItem, node: AVAudioPlayerNode) {
        // Return node to available pool
        if let nodeKey = activeNodes.first(where: { $0.value === node })?.key {
            activeNodes.removeValue(forKey: nodeKey)
            availableNodes.append(node)
        }
        
        // Reset node
        node.stop()
        node.reset()
        
        // Update state
        if activeNodes.isEmpty {
            isPlaying = false
            currentItem = nil
        }
        
        isProcessing = false
        
        // Process next item in queue
        if !speechQueue.isEmpty {
            processQueue()
        }
    }
}

// MARK: - Convenience Extensions

extension SpatialSpeechController {
    /// Speak text at specific coordinates
    public func speak(_ text: String, x: Float, y: Float, z: Float, priority: Int = 0) {
        speak(text, at: SpatialPosition(x: x, y: y, z: z), priority: priority)
    }
    
    /// Create a speech queue with multiple items
    public func enqueueBatch(_ items: [SpatialSpeechItem]) {
        items.forEach { enqueue($0) }
    }
    
    /// Clear spoken text cache
    public func clearSpokenCache() {
        spokenTexts.removeAll()
    }
}

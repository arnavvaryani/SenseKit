//
//  SpatialSpeechController.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/23/25.
//


import AVFoundation
import simd

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
    public static let center = SpatialPosition(x: 0, y: 0, z: 0)
    public static let left = SpatialPosition(x: -1, y: 0, z: 0)
    public static let right = SpatialPosition(x: 1, y: 0, z: 0)
    public static let front = SpatialPosition(x: 0, y: 0, z: 1)
    public static let back = SpatialPosition(x: 0, y: 0, z: -1)
    public static let above = SpatialPosition(x: 0, y: 1, z: 0)
    public static let below = SpatialPosition(x: 0, y: -1, z: 0)
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

// Simple, main-thread only spatial speech controller
public class SpatialSpeechController: ObservableObject {
    // Dependencies
    private let audioEngine: AVAudioEngine
    private let speechSynthesizer: AVSpeechSynthesizer
    private let spatialMixer: AVAudioEnvironmentNode
    private let delegate: SpatialSpeechDelegate
    
    // Queue management
    private var speechQueue: [SpatialSpeechItem] = []
    private var spokenTexts = Set<String>()
    private var isProcessing = false
    
    // Audio nodes for spatial positioning
    private var playerNodes: [AVAudioPlayerNode] = []
    private var availableNodes: [AVAudioPlayerNode] = []
    private var activeNodes: [String: AVAudioPlayerNode] = [:]
    
    // Engine state management
    private var isEngineStarted = false
    
    // Public state
    @Published public private(set) var isPlaying = false
    @Published public private(set) var currentItem: SpatialSpeechItem?
    @Published public private(set) var queueCount: Int = 0
    
    // Configuration
    public var maxConcurrentSpeech: Int = 3
    public var spatialDistance: Float = 1.0
    
    public init(maxNodes: Int = 5) {
        self.audioEngine = AVAudioEngine()
        self.speechSynthesizer = AVSpeechSynthesizer()
        self.spatialMixer = AVAudioEnvironmentNode()
        self.delegate = SpatialSpeechDelegate()
        
        setupAudioEngine(maxNodes: maxNodes)
        setupSpatialEnvironment()
        setupSpeechSynthesizer()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public API
    
    /// Add a speech item to the spatial queue
    public func enqueue(_ item: SpatialSpeechItem) {
        ensureEngineIsRunning()
        
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
        isEngineStarted = false
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
        configureAudioSession()
        
        // Start the engine initially
        startAudioEngine()
    }
    
    private func setupSpeechSynthesizer() {
            speechSynthesizer.delegate = delegate
            
            // Set up completion callback with MainActor isolation
            delegate.onUtteranceCompleted = { [weak self] speechString in
                Task { @MainActor [weak self] in
                    self?.handleSpeechCompletion(speechString: speechString)
                }
            }
        }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func startAudioEngine() {
        guard !isEngineStarted else { return }
        
        do {
            try audioEngine.start()
            isEngineStarted = true
            print("Audio engine started successfully")
        } catch {
            print("Failed to start audio engine: \(error)")
            isEngineStarted = false
        }
    }
    
    private func ensureEngineIsRunning() {
        guard !audioEngine.isRunning || !isEngineStarted else { return }
        
        print("Engine not running, restarting...")
        startAudioEngine()
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
              activeNodes.count < maxConcurrentSpeech else {
            return
        }
        
        // Ensure engine is running before processing
        ensureEngineIsRunning()
        guard audioEngine.isRunning else {
            print("Engine not running, cannot process queue")
            return
        }
        
        isProcessing = true
        let item = speechQueue.removeFirst()
        queueCount = speechQueue.count
        
        // Mark as spoken
        spokenTexts.insert(item.text)
        currentItem = item
        isPlaying = true
        
        synthesizeSpatialSpeech(item)
    }
    
    private func synthesizeSpatialSpeech(_ item: SpatialSpeechItem) {
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        // For spatial audio, we'll use the traditional speech synthesizer
        // and apply spatial positioning through the mixer
        speechSynthesizer.speak(utterance)
        
        // Set the spatial position for the current utterance
        updateSpatialPosition(item.position)
    }
    
    private func updateSpatialPosition(_ position: SpatialPosition) {
        // Update the mixer's source position to simulate spatial speech
        spatialMixer.listenerPosition = AVAudio3DPoint(
            x: -position.x * spatialDistance, // Invert for listener perspective
            y: -position.y * spatialDistance,
            z: -position.z * spatialDistance
        )
    }
    
    private func handleSpeechCompletion(speechString: String) {
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

// MARK: - Speech Delegate

private class SpatialSpeechDelegate: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    var onUtteranceCompleted: (@Sendable (String) -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onUtteranceCompleted?(utterance.speechString)
    }
}

// MARK: - Convenience Extensions

extension SpatialSpeechController: @unchecked Sendable {
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

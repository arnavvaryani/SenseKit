//
//  MockAudioEngine.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Foundation
import AVFoundation
import CoreHaptics
@testable import SenseKit

// MARK: - Audio Mocks

final class MockAudioEngine: AudioEngineProtocol {
    let mainMixerNode = AVAudioMixerNode()
    private(set) var attachedNodes: [AVAudioNode] = []
    private(set) var connections: [(source: AVAudioNode, dest: AVAudioNode, format: AVAudioFormat?)] = []
    private(set) var isStarted = false
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    
    var shouldThrowOnStart = false
    var startError: Error = NSError(domain: "MockError", code: 1)
    
    func attach(_ node: AVAudioNode) {
        attachedNodes.append(node)
    }
    
    func connect(_ node: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat?) {
        connections.append((node, destination, format))
    }
    
    func start() throws {
        startCallCount += 1
        if shouldThrowOnStart {
            throw startError
        }
        isStarted = true
    }
    
    func stop() {
        stopCallCount += 1
        isStarted = false
    }
    
    func disconnectNodeOutput(_ node: AVAudioNode) {
        connections.removeAll { $0.source === node }
    }
    
    func detach(_ node: AVAudioNode) {
        attachedNodes.removeAll { $0 === node }
    }
}

final class MockAudioPlayerNode: AudioPlayerNodeProtocol {
    let avAudioNode = AVAudioNode()
    private(set) var scheduledBuffers: [AVAudioPCMBuffer] = []
    private(set) var playCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var isPlaying = false
    
    var lastScheduledOptions: AVAudioPlayerNodeBufferOptions?
    var lastScheduledTime: AVAudioTime?
    
    func scheduleBuffer(_ buffer: AVAudioPCMBuffer,
                        at when: AVAudioTime?,
                        options: AVAudioPlayerNodeBufferOptions,
                        completionHandler: (() -> Void)?) {
        scheduledBuffers.append(buffer)
        lastScheduledTime = when
        lastScheduledOptions = options
        completionHandler?()
    }
    
    func play() {
        playCallCount += 1
        isPlaying = true
    }
    
    func stop() {
        stopCallCount += 1
        isPlaying = false
        scheduledBuffers.removeAll()
    }
}

// MARK: - Haptic Mocks

final class MockHapticEngine: HapticEngineProtocol {
    private(set) var isStarted = false
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var createdPlayers: [MockHapticPlayer] = []
    
    var shouldThrowOnStart = false
    var shouldThrowOnMakePlayer = false
    var makePlayerError: Error = HapticError.patternCreationFailed(NSError(domain: "Mock", code: 1))
    
    func start() throws {
        startCallCount += 1
        if shouldThrowOnStart {
            throw HapticError.engineUnavailable
        }
        isStarted = true
    }
    
    func stop(completionHandler: CHHapticEngine.CompletionHandler?) {
        stopCallCount += 1
        isStarted = false
        createdPlayers.forEach { $0.forceStop() }
        completionHandler?(nil)
    }
    
    func makePlayer(with pattern: CHHapticPattern) throws -> HapticPatternPlayerProtocol {
        if shouldThrowOnMakePlayer {
            throw makePlayerError
        }
        let player = MockHapticPlayer()
        createdPlayers.append(player)
        return player
    }
}

final class MockHapticPlayer: HapticPatternPlayerProtocol {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastStartTime: TimeInterval?
    private(set) var lastStopTime: TimeInterval?
    private(set) var isPlaying = false
    
    func start(atTime time: TimeInterval) throws {
        startCallCount += 1
        lastStartTime = time
        isPlaying = true
    }
    
    func stop(atTime time: TimeInterval) throws {
        stopCallCount += 1
        lastStopTime = time
        isPlaying = false
    }
    
    // Helper for testing
    func forceStop() {
        isPlaying = false
    }
}

// MARK: - Speech Mocks

//final class MockSpeechSynthesizer: SpeechSynthesizerProtocol {
//    weak var delegate: AVSpeechSynthesizerDelegate?
//    private(set) var spokenUtterances: [AVSpeechUtterance] = []
//    private(set) var stopCallCount = 0
//    private(set) var pauseCallCount = 0
//    private(set) var continueCallCount = 0
//    
//    var simulateCompletionDelay: TimeInterval = 0.1
//    var shouldSimulateCompletion = true
//    
//    func speak(_ utterance: AVSpeechUtterance) {
//        spokenUtterances.append(utterance)
//        
//        // Simulate completion if enabled
//        if shouldSimulateCompletion {
//            DispatchQueue.global().asyncAfter(deadline: .now() + simulateCompletionDelay) { [weak self] in
//                guard let self = self, let delegate = self.delegate else { return }
//                // AVSpeechSynthesizerDelegate callbacks can come from any thread
//                delegate.speechSynthesizer?(AVSpeechSynthesizer(), didFinish: utterance)
//            }
//        }
//    }
//    
//    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
//        stopCallCount += 1
//        return true
//    }
//    
//    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
//        pauseCallCount += 1
//        return true
//    }
//    
//    func continueSpeaking() -> Bool {
//        continueCallCount += 1
//        return true
//    }
//}

// Mock coordinator for testing
//final class MockSpeechCoordinator: SpeechCoordinatorProtocol {
//    var onUtteranceCompleted: (@MainActor @Sendable (String) -> Void)?
//    
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        guard let callback = onUtteranceCompleted else { return }
//        let speechString = utterance.speechString
//        
//        Task { @MainActor in
//            callback(speechString)
//        }
//    }
//}

//final class MockAudioSession: AudioSessionProtocol {
//    private(set) var setCategories: [(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)] = []
//    private(set) var setActiveCallCount = 0
//    private(set) var isActive = false
//    
//    var shouldThrowOnSetCategory = false
//    var shouldThrowOnSetActive = false
//    var categoryError = NSError(domain: "MockAudioSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to set category"])
//    var activeError = NSError(domain: "MockAudioSession", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to set active"])
//    
//    func setCategory(_ category: AVAudioSession.Category,
//                     mode: AVAudioSession.Mode,
//                     options: AVAudioSession.CategoryOptions) throws {
//        if shouldThrowOnSetCategory {
//            throw categoryError
//        }
//        setCategories.append((category, mode, options))
//    }
//    
//    func setActive(_ active: Bool) throws {
//        if shouldThrowOnSetActive {
//            throw activeError
//        }
//        setActiveCallCount += 1
//        isActive = active
//    }
//    
//    // Helper for testing
//    var lastSetCategory: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)? {
//        setCategories.last
//    }
//}

// MARK: - Test Helpers

extension MockAudioEngine {
    func reset() {
        attachedNodes.removeAll()
        connections.removeAll()
        isStarted = false
        startCallCount = 0
        stopCallCount = 0
    }
}

//extension MockSpeechSynthesizer {
//    func reset() {
//        spokenUtterances.removeAll()
//        stopCallCount = 0
//        pauseCallCount = 0
//        continueCallCount = 0
//    }
//    
//    var lastSpokenText: String? {
//        spokenUtterances.last?.speechString
//    }
//}

extension MockHapticEngine {
    func reset() {
        isStarted = false
        startCallCount = 0
        stopCallCount = 0
        createdPlayers.removeAll()
    }
}

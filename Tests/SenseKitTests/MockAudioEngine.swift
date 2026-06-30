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
                        completionHandler: (@Sendable () -> Void)?) {
        scheduledBuffers.append(buffer)
        lastScheduledTime = when
        lastScheduledOptions = options
        completionHandler?()
    }

    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        return AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )!
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

    func reset() {
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

    func stop(completionHandler: (@Sendable (Error?) -> Void)?) {
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

/// Records calls made by `SpeechController`. Completion can be simulated
/// deterministically via `finishSpeaking(_:)` instead of relying on timers.
final class MockSpeechSynthesizer: SpeechSynthesizerProtocol, @unchecked Sendable {
    weak var delegate: AVSpeechSynthesizerDelegate?
    private(set) var spokenUtterances: [AVSpeechUtterance] = []
    private(set) var stopCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var continueCallCount = 0

    func speak(_ utterance: AVSpeechUtterance) {
        spokenUtterances.append(utterance)
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopCallCount += 1
        return true
    }

    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        pauseCallCount += 1
        return true
    }

    func continueSpeaking() -> Bool {
        continueCallCount += 1
        return true
    }

    /// Deterministically drive the delegate's completion callback for testing.
    func finishSpeaking(_ text: String) {
        delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didFinish: AVSpeechUtterance(string: text))
    }
}

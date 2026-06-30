//
//  PulsatingSinWaveGenerator 2.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import Foundation
import AVFoundation
import CoreHaptics

public class PulsatingSinWaveGenerator: WaveGeneratorProtocol {
    private let audioEngine: AudioEngineProtocol
    private let player: AudioPlayerNodeProtocol
    private let hapticEngine: HapticEngineProtocol
    private let buffer: AVAudioPCMBuffer
    private let hapticPlayer: HapticPatternPlayerProtocol
    private let pulseInterval: TimeInterval
    private let pulseDuration: TimeInterval

    private var isRunning = false

    public init(
        frequency: Double = 400,
        sampleRate: Double = 44_100,
        amplitude: Float = 1.0,
        pulseInterval: TimeInterval = 0.2,
        pulseDuration: TimeInterval = 0.1,
        audioEngine: AudioEngineProtocol = AVAudioEngine(),
        player: AudioPlayerNodeProtocol = AVAudioPlayerNode(),
        hapticEngine: HapticEngineProtocol? = nil
    ) throws {
        self.pulseInterval = pulseInterval
        self.pulseDuration = pulseDuration
        self.audioEngine = audioEngine
        self.player = player

        // Use the injected haptic engine, or build a real one (which throws
        // HapticError.engineUnavailable on hardware without haptics support).
        if let hapticEngine {
            self.hapticEngine = hapticEngine
        } else {
            self.hapticEngine = try CHHapticEngineWrapper()
        }

        // Create audio buffer (same as before)
        let frameCount = AVAudioFrameCount(sampleRate * pulseDuration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        // Fill buffer with sine wave
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: 1)
        let thetaIncrement = 2.0 * .pi * frequency / sampleRate
        var theta: Double = 0
        
        for frame in 0..<Int(frameCount) {
            let sample = amplitude * sin(Float(theta))
            channels[0][frame] = sample
            theta += thetaIncrement
        }
        
        // Setup audio engine
        audioEngine.attach(player.avAudioNode)
        audioEngine.connect(player.avAudioNode, to: audioEngine.mainMixerNode, format: format)
        
        // Prepare haptic pattern
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0,
            duration: pulseDuration
        )
        let pattern = try CHHapticPattern(events: [event], parameters: [])
        self.hapticPlayer = try self.hapticEngine.makePlayer(with: pattern)
    }
    
    deinit {
        stop()
    }
    
    public func start() throws {
        try audioEngine.start()
        try hapticEngine.start()
        
        isRunning = true
        scheduleNextPulse()
    }
    
    public func stop() {
        isRunning = false
        player.stop()
        audioEngine.stop()
        hapticEngine.stop(completionHandler: nil)
    }
    
    private func scheduleNextPulse() {
        guard isRunning else { return }
        
        // Start pulse
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
        try? hapticPlayer.start(atTime: CHHapticTimeImmediate)
        
        // Schedule stop
        Timer.scheduledTimer(withTimeInterval: pulseDuration, repeats: false) { _ in
            self.player.stop()
            try? self.hapticPlayer.stop(atTime: CHHapticTimeImmediate)
        }
        
        // Schedule next pulse
        Timer.scheduledTimer(withTimeInterval: pulseInterval, repeats: false) { _ in
            self.scheduleNextPulse()
        }
    }
}

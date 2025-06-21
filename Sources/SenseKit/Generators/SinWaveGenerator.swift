//
//  SinWaveGenerator.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import AVFoundation

public class SinWaveGenerator: WaveGeneratorProtocol {
    private let audioEngine = AVAudioEngine()
    private let sampleRate: Double
    private let frequency: Double
    private var sourceNode: AVAudioSourceNode?
    private var phase: Double = 0.0
    
    public init(frequency: Double, sampleRate: Double = 44_100.0) {
        self.frequency = frequency
        self.sampleRate = sampleRate
        setupAudioEngine()
    }
    
    deinit {
        stop()
        if let node = sourceNode {
            audioEngine.disconnectNodeOutput(node)
            audioEngine.detach(node)
        }
    }
    
    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = 2.0 * .pi * self.frequency / self.sampleRate
            
            for frame in 0..<Int(frameCount) {
                let sample = sin(self.phase)
                self.phase += phaseIncrement
                if self.phase >= 2.0 * .pi {
                    self.phase -= 2.0 * .pi
                }
                
                for buffer in bufferList {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = Float(sample)
                }
            }
            return noErr
        }
        
        guard let node = sourceNode else { return }
        audioEngine.attach(node)
        audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)
    }
    
    public func start() throws {
        try audioEngine.start()
    }
    
    public func stop() {
        audioEngine.stop()
    }
}

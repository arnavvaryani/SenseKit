//
//  SpeechTask.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/23/25.
//

import AVFoundation

/// Represents a speech task that can be controlled
public final class SpeechTask {
    private weak var synthesizer: SpeechSynthesizerProtocol?
    private let speechString: String
    
    init(synthesizer: SpeechSynthesizerProtocol, speechString: String) {
        self.synthesizer = synthesizer
        self.speechString = speechString
    }
    
    public func cancel() {
        _ = synthesizer?.stopSpeaking(at: .immediate)
    }
    
    public func pause() {
        _ = synthesizer?.pauseSpeaking(at: .word)
    }
    
    public func resume() {
        _ = synthesizer?.continueSpeaking()
    }
}

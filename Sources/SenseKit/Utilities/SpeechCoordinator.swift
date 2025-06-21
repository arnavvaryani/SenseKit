//
//  SpeechCoordinator.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Foundation
import AVFoundation

public final class SpeechCoordinator: NSObject, AVSpeechSynthesizerDelegate, SpeechCoordinatorProtocol, @unchecked Sendable {
    public var onUtteranceCompleted: (@MainActor @Sendable (String) -> Void)?

    public override init() {
        super.init()
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        guard let callback = onUtteranceCompleted else { return }
        
        // Capture only the string to avoid sending the utterance
        let speechString = utterance.speechString
        
        Task { @MainActor in
            callback(speechString)
        }
    }
}

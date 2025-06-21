//
//  SpeechCoordinatorProtocol.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import AVFoundation

public protocol SpeechCoordinatorProtocol: AVSpeechSynthesizerDelegate, AnyObject {
    var onUtteranceCompleted: (@MainActor @Sendable (String) -> Void)? { get set }
}

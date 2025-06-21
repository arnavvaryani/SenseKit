//
//  SpeechSynthesizerProtocol.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import AVFoundation

public protocol SpeechSynthesizerProtocol: AnyObject, Sendable {
    var delegate: AVSpeechSynthesizerDelegate? { get set }
    func speak(_ utterance: AVSpeechUtterance)
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool
    func continueSpeaking() -> Bool
}

extension AVSpeechSynthesizer: @unchecked Sendable {}
extension AVSpeechSynthesizer: SpeechSynthesizerProtocol {}

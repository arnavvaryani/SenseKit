//
//  AudioSessionProtocol.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//

import AVFoundation

public protocol AudioSessionProtocol: Sendable {
    func setCategory(_ category: AVAudioSession.Category,
                     mode: AVAudioSession.Mode,
                     options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool) throws
}

extension AVAudioSession: @retroactive @unchecked Sendable {}

// AVAudioSession already provides setCategory(_:mode:options:) and setActive(_:),
// so it satisfies AudioSessionProtocol directly.
extension AVAudioSession: AudioSessionProtocol {}


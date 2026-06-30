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

// AVAudioSession provides setCategory(_:mode:options:) directly; setActive(_:)
// without options is unavailable, so forward to the options-based overload.
extension AVAudioSession: AudioSessionProtocol {
    public func setActive(_ active: Bool) throws {
        try setActive(active, options: [])
    }
}


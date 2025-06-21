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

extension AVAudioSession: @unchecked Sendable {}


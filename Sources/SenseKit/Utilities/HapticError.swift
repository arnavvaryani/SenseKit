//
//  HapticError 2.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/13/25.
//


import Foundation

/// Errors thrown by the HapticsLibrary
public enum HapticError: LocalizedError {
    case engineUnavailable
    case patternCreationFailed(Error)
    case playbackFailed(Error)
    case engineNotPrepared
    
    public var errorDescription: String? {
        switch self {
        case .engineUnavailable:
            return "Haptic engine is not available on this device"
        case .patternCreationFailed(let error):
            return "Failed to create haptic pattern: \(error.localizedDescription)"
        case .playbackFailed(let error):
            return "Failed to play haptic: \(error.localizedDescription)"
        case .engineNotPrepared:
            return "Haptic engine must be prepared before use"
        }
    }
}
//
//  SpeechController.swift
//  SenseKit
//
//  Created by Arnav Varyani on 6/23/25.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public class SpeechController {
    // Dependencies
    private let synthesizer: SpeechSynthesizerProtocol
    private let coordinator: SpeechCoordinator  
    private let audioSession: AVAudioSession
    
    // Configuration
    private var config: SpeechConfiguration
    
    // Public state (needs @MainActor for UI updates)
    public private(set) var isSpeaking = false
    public private(set) var currentText: String?
    
    // Internal
    private var spokenTexts = Set<String>()
    private var currentTask: SpeechTask?
    
    public init(
        synthesizer: SpeechSynthesizerProtocol = AVSpeechSynthesizer(),
        audioSession: AVAudioSession = AVAudioSession.sharedInstance(),  // Remove force cast
        config: SpeechConfiguration = SpeechConfiguration()
    ) {
        self.synthesizer = synthesizer
        self.coordinator = SpeechCoordinator()
        self.audioSession = audioSession
        self.config = config
        
        // Set up default trigger if needed
        if config.triggers.isEmpty {
            self.config.triggers = [
                SpeechConfiguration.Trigger(text: "loading") { [weak self] in
                    self?.handleLoadingTrigger()
                }
            ]
        }
        
        setupCoordinator()
        prepareAudioSession()
    }
    
    deinit {
        // Direct access is fine - no concurrency issues here
        coordinator.onUtteranceCompleted = nil
        synthesizer.delegate = nil
    }
    
    // MARK: - Public API
    
    @discardableResult
    public func speak(_ text: String, allowRepeat: Bool = false) -> SpeechTask? {
        if !allowRepeat && spokenTexts.contains(text) {
            return nil
        }
        
        spokenTexts.insert(text)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: config.voice)
        utterance.volume = config.volume
        utterance.rate = config.rate
        
        currentText = text
        isSpeaking = true
        
        synthesizer.speak(utterance)
        
        let task = SpeechTask(synthesizer: synthesizer, speechString: text)
        currentTask = task
        
        checkTriggers(for: text)
        
        return task
    }
    
    public func stopSpeaking() {
        currentTask?.cancel()
        currentTask = nil
        isSpeaking = false
        currentText = nil
    }
    
    public func clearSpokenCache() {
        spokenTexts.removeAll()
    }
    
    public func updateConfiguration(_ config: SpeechConfiguration) {
        self.config = config
    }
    
    public func addTrigger(_ trigger: SpeechConfiguration.Trigger) {
        config.triggers.append(trigger)
    }
    
    // MARK: - Private
    
    private func setupCoordinator() {
        synthesizer.delegate = coordinator
        
        // This needs to handle potential background thread callbacks
        coordinator.onUtteranceCompleted = { [weak self] speechString in
            // Already dispatched to @MainActor by coordinator
            self?.handleCompletion(of: speechString)
        }
    }
    
    private func handleCompletion(of speechString: String) {
        isSpeaking = false
        currentText = nil
        currentTask = nil
    }
    
    private func checkTriggers(for text: String) {
        for trigger in config.triggers {
            let matches = trigger.caseSensitive
                ? text.contains(trigger.text)
                : text.lowercased().contains(trigger.text.lowercased())
            
            if matches {
                trigger.action()
            }
        }
    }
    
    private func handleLoadingTrigger() {
        // Default loading behavior
    }
    
    private func prepareAudioSession() {
        // No need for async - these are synchronous operations
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}

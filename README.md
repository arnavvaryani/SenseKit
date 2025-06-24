# SenseKit

A comprehensive Swift package for creating immersive sensory experiences through haptic feedback, spatial audio, and speech synthesis. SenseKit provides unified APIs for building accessible and engaging iOS applications with rich multi-sensory interactions.

## Features

### 🎯 Haptic Feedback System
- **Advanced Haptic Controller**: Complete haptic feedback management with task-based control
- **Multiple Haptic Patterns**: Support for continuous haptics, pulse patterns, and custom sequences
- **Task Management**: Cancellable haptic tasks with proper resource cleanup
- **System Integration**: Respects user's system haptic preferences
- **Engine Management**: Automatic haptic engine lifecycle management

### 🔊 Audio Generation
- **Sine Wave Generator**: Pure sine wave audio generation for tones and signals
- **Pulsating Wave Generator**: Combined audio and haptic pulsing patterns
- **Real-time Audio**: Low-latency audio generation using AVAudioEngine
- **Configurable Parameters**: Adjustable frequency, amplitude, sample rate, and timing

### 🎙️ Speech Synthesis
- **Basic Speech Coordinator**: Simple text-to-speech with completion callbacks
- **Spatial Speech System**: Advanced 3D positioned speech synthesis
- **Queue Management**: Priority-based speech queue with repeat prevention
- **Multi-voice Support**: Concurrent spatial speech from multiple sources
- **Listener Positioning**: Dynamic 3D audio positioning and orientation

### 🌐 Spatial Audio
- **3D Positioning**: Full spatial audio with X, Y, Z coordinate system
- **Distance Attenuation**: Realistic audio falloff based on distance
- **Environmental Audio**: Reverb and environmental effects for realism
- **Multiple Audio Sources**: Support for concurrent positioned audio streams
- **Listener Control**: Dynamic listener position and orientation updates

### 🏗️ Architecture & Design
- **Protocol-Oriented**: Highly testable with dependency injection support
- **Resource Management**: Automatic cleanup and proper resource lifecycle
- **Error Handling**: Comprehensive error types with descriptive messages
- **Configuration**: Flexible configuration options for all components
- **Thread Safety**: Proper concurrency handling with MainActor isolation

## Installation

### Swift Package Manager

Add SenseKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/SenseKit.git", from: "1.0.0")
]
```

## Quick Start

### Basic Haptic Feedback

```swift
import SenseKit

// Initialize haptic controller
let hapticController = try HapticController()
try hapticController.prepare()

// Play continuous haptic
let task = try hapticController.playContinuous()

// Stop when done
task.cancel()
```

### Spatial Speech

```swift
import SenseKit

// Initialize spatial speech controller
let speechController = SpatialSpeechController()

// Speak text from different positions
speechController.speak("Welcome!", at: .center)
speechController.speak("Left channel", at: .left, priority: 1)
speechController.speak("Right channel", at: .right, priority: 1)

// Update listener position
speechController.updateListenerPosition(
    position: SpatialPosition(x: 0, y: 0, z: 1)
)
```

### Audio Wave Generation

```swift
import SenseKit

// Generate sine wave
let generator = SinWaveGenerator(frequency: 440) // A4 note
try generator.start()

// Or create pulsating waves with haptics
let pulseGenerator = try PulsatingSinWaveGenerator(
    frequency: 400,
    pulseInterval: 0.2,
    pulseDuration: 0.1
)
try pulseGenerator.start()
```

## API Reference

### HapticController

The main class for managing haptic feedback:

```swift
public class HapticController {
    public init(engine: HapticEngineProtocol? = nil, config: HapticConfiguration = .init()) throws
    public func prepare() throws
    public func playContinuous() throws -> HapticTask
    public func playPulse() throws -> HapticTask
    public func stop()
    public func stopActiveHaptics()
}
```

### SpatialSpeechController

Advanced spatial audio speech synthesis:

```swift
@MainActor
@Observable
public class SpatialSpeechController {
    public func speak(_ text: String, at position: SpatialPosition, priority: Int, allowRepeat: Bool)
    public func enqueue(_ item: SpatialSpeechItem)
    public func updateListenerPosition(position: SpatialPosition, orientation: simd_float3)
    public func stop()
    public func clearQueue()
}
```

### SpatialPosition

3D coordinate system for positioning audio sources:

```swift
public struct SpatialPosition: Sendable {
    public let x: Float  // Left(-) to Right(+)
    public let y: Float  // Down(-) to Up(+)
    public let z: Float  // Behind(-) to Front(+)
    
    // Convenience positions
    public static let center, left, right, front, back, above, below
}
```

## Configuration

### Haptic Configuration

```swift
let config = HapticConfiguration(
    defaultIntensity: 0.8,
    defaultSharpness: 0.6,
    continuousDuration: 5.0,
    respectSystemSettings: true
)
```

### Speech Configuration

```swift
let speechConfig = SpeechConfiguration(
    voice: "en-US",
    volume: 1.0,
    rate: AVSpeechUtteranceDefaultSpeechRate
)
```

## Error Handling

SenseKit provides comprehensive error handling:

```swift
public enum HapticError: LocalizedError {
    case engineUnavailable
    case patternCreationFailed(Error)
    case playbackFailed(Error)
    case engineNotPrepared
}
```

Always wrap SenseKit calls in try-catch blocks:

```swift
do {
    let controller = try HapticController()
    try controller.prepare()
    try controller.playContinuous()
} catch HapticError.engineUnavailable {
    print("Haptics not supported on this device")
} catch {
    print("Haptic error: \(error.localizedDescription)")
}
```

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+

### Device Capabilities

- **Haptics**: Requires device with Taptic Engine (iPhone 7+, select iPads)
- **Spatial Audio**: Works on all iOS devices, enhanced on devices with spatial audio support
- **Speech Synthesis**: Available on all iOS devices

## Best Practices

### Resource Management

Always properly clean up resources:

```swift
class MyViewController: UIViewController {
    private var hapticController: HapticController?
    private var speechController: SpatialSpeechController?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hapticController?.stop()
        speechController?.stop()
    }
}
```

### Performance Considerations

- Prepare haptic engines early in your app lifecycle
- Reuse controllers when possible
- Use priority queues for speech to manage important messages
- Monitor device thermal state for intensive audio/haptic usage

### Accessibility

SenseKit is designed with accessibility in mind:

- Respects system haptic preferences
- Provides clear audio positioning for navigation
- Supports VoiceOver integration
- Offers configurable intensity and timing

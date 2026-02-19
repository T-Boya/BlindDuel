import CoreHaptics

/// Predefined haptic patterns for combat feedback.
/// Each pattern is a factory method returning a CHHapticPattern.
enum HapticPatterns {
    
    /// Sharp, intense impact — player takes damage.
    /// Single hard transient: max intensity, max sharpness.
    static func playerDamage() throws -> CHHapticPattern {
        let impact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [impact], parameters: [])
    }
    
    /// Medium thud — player successfully blocks.
    static func playerBlock() throws -> CHHapticPattern {
        let thud = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [thud], parameters: [])
    }
    
    /// Heartbeat pattern — two quick taps, repeating.
    /// Used at 1 HP for constant tension.
    static func heartbeat() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Create 10 seconds of heartbeat (will loop via continuous playback)
        let beatInterval: TimeInterval = 0.8
        let doubleBeatGap: TimeInterval = 0.15
        
        for i in 0..<12 {
            let baseTime = Double(i) * beatInterval
            
            // First beat
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: baseTime
            ))
            
            // Second beat (slightly softer)
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: baseTime + doubleBeatGap
            ))
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    /// Proximity rumble — continuous vibration at a given intensity.
    /// Intensity should map to closeness (0 = far, 1 = very close).
    static func proximityRumble(intensity: Float) throws -> CHHapticPattern {
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: 5.0
        )
        return try CHHapticPattern(events: [rumble], parameters: [])
    }
    
    /// Round win — ascending double pulse.
    static func roundWin() throws -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.15
            )
        ]
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    /// Round lose — descending buzz.
    static func roundLose() throws -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.1,
                duration: 0.4
            )
        ]
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    /// Generic impact at a specified level.
    static func impact(_ intensity: HapticIntensity) throws -> CHHapticPattern {
        let (intensityValue, sharpnessValue): (Float, Float) = {
            switch intensity {
            case .light: return (0.3, 0.3)
            case .medium: return (0.6, 0.5)
            case .heavy: return (1.0, 0.8)
            }
        }()
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityValue),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessValue)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }
}

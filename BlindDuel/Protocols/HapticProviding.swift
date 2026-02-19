import Foundation

/// Haptic intensity levels for generic impact feedback.
enum HapticIntensity: Equatable {
    case light
    case medium
    case heavy
}

/// Abstraction for the haptic feedback system.
/// The combat engine depends on this protocol — never on CHHapticEngine directly.
protocol HapticProviding: AnyObject {
    
    // MARK: - Lifecycle
    
    /// Prepare the haptic engine for playback.
    func start() throws
    
    /// Stop the haptic engine.
    func stop()
    
    /// Whether the current hardware supports haptics.
    var supportsHaptics: Bool { get }
    
    // MARK: - Combat Feedback (Player Only)
    
    /// Sharp impact when the player takes damage.
    func playPlayerDamage()
    
    /// Medium thud when the player successfully blocks.
    func playPlayerBlock()
    
    /// Generic impact at a given intensity.
    func playImpact(intensity: HapticIntensity)
    
    // MARK: - Continuous Patterns
    
    /// Start the heartbeat haptic pattern (at 1 HP).
    func startHeartbeat()
    
    /// Stop the heartbeat haptic pattern.
    func stopHeartbeat()
    
    /// Start a proximity rumble that increases with closeness.
    /// - Parameter intensity: 0.0 (far) to 1.0 (very close).
    func startProximityRumble(intensity: Float)
    
    /// Stop the proximity rumble.
    func stopProximityRumble()
    
    // MARK: - Round Results
    
    /// Play a haptic pattern for round result.
    /// - Parameter won: Whether the player won.
    func playRoundResult(won: Bool)
}

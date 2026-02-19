import CoreHaptics
import UIKit

/// Concrete haptic manager using Core Haptics (CHHapticEngine).
/// Conforms to HapticProviding — the combat engine depends only on the protocol.
///
/// Ownership rule: Only fire haptics for PLAYER events.
/// Enemy damage = no vibration. This keeps self/enemy distinct.
final class HapticManager: HapticProviding {
    
    // MARK: - Engine
    
    private var engine: CHHapticEngine?
    
    // MARK: - Active Players (for continuous patterns)
    
    private var heartbeatPlayer: CHHapticAdvancedPatternPlayer?
    private var proximityPlayer: CHHapticAdvancedPatternPlayer?
    
    // MARK: - HapticProviding
    
    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    func start() throws {
        guard supportsHaptics else { return }
        
        engine = try CHHapticEngine()
        
        // Handle engine stopped (e.g., app backgrounded)
        engine?.stoppedHandler = { [weak self] reason in
            print("[HapticManager] Engine stopped: \(reason)")
            self?.engine = nil
        }
        
        // Handle engine reset (e.g., audio interruption)
        engine?.resetHandler = { [weak self] in
            do {
                try self?.engine?.start()
            } catch {
                print("[HapticManager] Failed to restart engine: \(error)")
            }
        }
        
        try engine?.start()
    }
    
    func stop() {
        try? heartbeatPlayer?.stop(atTime: CHHapticTimeImmediate)
        try? proximityPlayer?.stop(atTime: CHHapticTimeImmediate)
        heartbeatPlayer = nil
        proximityPlayer = nil
        engine?.stop()
        engine = nil
    }
    
    // MARK: - Combat Feedback
    
    func playPlayerDamage() {
        playPattern { try HapticPatterns.playerDamage() }
    }
    
    func playPlayerBlock() {
        playPattern { try HapticPatterns.playerBlock() }
    }
    
    func playImpact(intensity: HapticIntensity) {
        playPattern { try HapticPatterns.impact(intensity) }
    }
    
    // MARK: - Continuous Patterns
    
    func startHeartbeat() {
        guard let engine = engine else { return }
        
        do {
            let pattern = try HapticPatterns.heartbeat()
            heartbeatPlayer = try engine.makeAdvancedPlayer(with: pattern)
            heartbeatPlayer?.loopEnabled = true
            try heartbeatPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticManager] Heartbeat error: \(error)")
        }
    }
    
    func stopHeartbeat() {
        try? heartbeatPlayer?.stop(atTime: CHHapticTimeImmediate)
        heartbeatPlayer = nil
    }
    
    func startProximityRumble(intensity: Float) {
        guard let engine = engine else { return }
        
        // Stop existing rumble before starting new one
        try? proximityPlayer?.stop(atTime: CHHapticTimeImmediate)
        
        do {
            let clamped = max(0, min(1, intensity))
            let pattern = try HapticPatterns.proximityRumble(intensity: clamped)
            proximityPlayer = try engine.makeAdvancedPlayer(with: pattern)
            proximityPlayer?.loopEnabled = true
            try proximityPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticManager] Proximity rumble error: \(error)")
        }
    }
    
    func stopProximityRumble() {
        try? proximityPlayer?.stop(atTime: CHHapticTimeImmediate)
        proximityPlayer = nil
    }
    
    // MARK: - Round Results
    
    func playRoundResult(won: Bool) {
        playPattern {
            won ? try HapticPatterns.roundWin() : try HapticPatterns.roundLose()
        }
    }
    
    // MARK: - Private
    
    /// Play a one-shot haptic pattern.
    private func playPattern(_ patternFactory: () throws -> CHHapticPattern) {
        guard let engine = engine else { return }
        
        do {
            let pattern = try patternFactory()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticManager] Playback error: \(error)")
        }
    }
}

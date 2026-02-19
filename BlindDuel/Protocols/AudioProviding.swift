import Foundation

/// Abstraction for the spatial audio system.
/// The combat engine depends on this protocol — never on AVAudioEngine directly.
protocol AudioProviding: AnyObject {
    
    // MARK: - Lifecycle
    
    /// Start the audio engine and prepare all buffers.
    func start() throws
    
    /// Stop the audio engine and release resources.
    func stop()
    
    // MARK: - Enemy Sounds (positional, reverberant)
    
    /// Play the enemy's attack tell (inhale/scrape) from a direction.
    /// - Parameter direction: Stereo pan position in range [-1, 1] (left to right).
    func playEnemyTell(from direction: Float)
    
    /// Play the enemy's strike sound (whoosh) from a direction.
    func playEnemyStrike(from direction: Float)
    
    /// Play the enemy's damage grunt from a direction.
    func playEnemyHit(from direction: Float)
    
    /// Update the enemy's spatial position based on range and direction.
    /// Position interpolation should be handled internally.
    func updateEnemyPosition(range: RangeState, direction: Float)
    
    /// Update the enemy's breathing audio state.
    /// - Parameter hp: The enemy's current health points.
    /// - Parameter destabilized: Whether the breathing should sound destabilized (just hit).
    func updateEnemyBreathing(hp: Int, destabilized: Bool)
    
    // MARK: - Player Sounds (centered, dry)
    
    /// Play the centered player damage impact sound.
    func playPlayerHit()
    
    /// Play the centered player block sound.
    func playPlayerBlock()
    
    /// Update the player's breathing audio layer.
    /// Breathing degrades as HP drops; heartbeat added at 1 HP.
    func updatePlayerBreathing(hp: Int)
    
    // MARK: - Enemy Footsteps
    
    /// Start the heel-click footstep loop for the enemy.
    /// Clicks pan left-right unpredictably and speed up as the enemy nears.
    func startEnemyFootsteps()
    
    /// Stop the footstep loop.
    func stopEnemyFootsteps()
    
    /// Update footstep tempo, volume, and spatial position using continuous distance.
    /// - Parameters:
    ///   - distance: Continuous distance 0.0 (melee) to 1.0 (far away).
    ///   - direction: Enemy's lateral position in [-1, 1].
    ///   - isApproaching: True when the enemy is actively moving closer (run).
    func updateEnemyFootsteps(distance: Float, direction: Float, isApproaching: Bool)
    
    // MARK: - Ambience & Round Flow
    
    /// Start the ambient room tone for tension.
    func startAmbience()
    
    /// Stop the ambient room tone.
    func stopAmbience()
    
    /// Play the round start sound/tone.
    func playRoundStart()
    
    /// Play the round end sound.
    /// - Parameter won: Whether the player won.
    func playRoundEnd(won: Bool)
}

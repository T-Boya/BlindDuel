import Foundation

/// Delegate that the CombatEngine uses to report events outward.
/// The CombatViewController (or any coordinator) conforms to this
/// and bridges events to audio/haptics/UI as needed.
///
/// The engine itself never calls audio or haptics directly —
/// it only reports what happened. The delegate decides how to present it.
protocol CombatEngineDelegate: AnyObject {
    
    /// The player took damage.
    /// - Parameter remainingHP: Player's HP after the damage.
    func combatEngine(_ engine: CombatEngine, playerDidTakeDamage remainingHP: Int)
    
    /// The enemy took damage.
    /// - Parameter remainingHP: Enemy's HP after the damage.
    func combatEngine(_ engine: CombatEngine, enemyDidTakeDamage remainingHP: Int)
    
    /// The range between fighters changed.
    /// - Parameter newRange: The new range state.
    func combatEngine(_ engine: CombatEngine, rangeDidChange newRange: RangeState)
    
    /// The enemy performed a tell (telegraph before attack).
    /// - Parameters:
    ///   - type: The type of tell (inhale, scrape, fake).
    ///   - direction: Stereo direction [-1, 1].
    func combatEngine(_ engine: CombatEngine, enemyDidTell type: TellType, from direction: Float)
    
    /// The enemy is striking.
    /// - Parameter direction: Stereo direction [-1, 1].
    func combatEngine(_ engine: CombatEngine, enemyDidStrike direction: Float)
    
    /// The player successfully blocked an attack.
    func combatEnginePlayerDidBlock(_ engine: CombatEngine)
    
    /// The combat round has ended.
    /// - Parameter result: The outcome of the round.
    func combatEngine(_ engine: CombatEngine, roundDidEnd result: RoundResult)
    
    /// The enemy's range/position updated (for continuous audio positioning).
    /// - Parameters:
    ///   - range: Current range state.
    ///   - direction: Current stereo direction [-1, 1].
    func combatEngine(_ engine: CombatEngine, enemyPositionUpdated range: RangeState, direction: Float)
    
    /// The round phase changed (tension → active → resolved).
    func combatEngine(_ engine: CombatEngine, phaseDidChange phase: RoundPhase)
}

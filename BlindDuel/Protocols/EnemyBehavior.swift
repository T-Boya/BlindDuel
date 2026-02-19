import Foundation

/// Strategy protocol for enemy AI behavior.
/// Each difficulty level is a separate conforming type (Open/Closed Principle).
/// Adding a new difficulty means writing one new class — no modifications to existing code.
protocol EnemyBehavior: AnyObject {
    
    /// Decide the enemy's next action given the current combat state.
    /// - Parameter state: The current state of combat (positions, HP, phase, etc.).
    /// - Returns: The action the enemy will take.
    func nextAction(given state: CombatState) -> EnemyAction
    
    /// The delay before the enemy executes a chosen action (e.g., time between tell and strike).
    /// - Parameter action: The action about to be executed.
    /// - Returns: Delay in seconds.
    func reactionDelay(for action: EnemyAction) -> TimeInterval
    
    /// How aggressively the AI pushes forward (0.0 = passive, 1.0 = relentless).
    var aggressionLevel: Float { get }
    
    /// Probability of a fake tell (0.0 = never, 1.0 = always).
    var fakeTellProbability: Float { get }
    
    /// Human-readable name of this behavior/difficulty ("Easy", "Normal", etc.).
    var displayName: String { get }
}

import Foundation

/// The current behavioral state of a fighter (player or enemy).
enum FighterState: Equatable {
    /// Idle / ready to act.
    case idle
    /// Currently performing an attack.
    case attacking
    /// Currently holding guard.
    case guarding
    /// Recovering after an attack (vulnerable window).
    case recovering
    /// Performing a sidestep dodge.
    case sidestepping
    /// Performing the pre-attack tell (enemy only).
    case telling
}

/// Represents a combatant — either the player or the enemy.
struct Fighter {
    /// Current hit points. Starts at `maxHP`.
    var hp: Int
    
    /// Maximum hit points.
    let maxHP: Int
    
    /// Current behavioral state.
    var state: FighterState
    
    /// Time remaining in the current state (for timed states like recovering).
    var stateTimer: TimeInterval
    
    /// Whether this fighter is still alive.
    var isAlive: Bool { hp > 0 }
    
    /// Create a fighter with default combat values.
    /// - Parameter maxHP: Maximum (and starting) health. Default is 3.
    init(maxHP: Int = 3) {
        self.hp = maxHP
        self.maxHP = maxHP
        self.state = .idle
        self.stateTimer = 0
    }
    
    /// Apply one point of damage.
    mutating func takeDamage() {
        hp = max(0, hp - 1)
    }
    
    /// Reset to full health and idle state for a new round.
    mutating func reset() {
        hp = maxHP
        state = .idle
        stateTimer = 0
    }
    
    /// Transition to a new state with an optional duration.
    /// - Parameters:
    ///   - newState: The state to enter.
    ///   - duration: How long to remain in this state (0 for indefinite).
    mutating func enter(state newState: FighterState, duration: TimeInterval = 0) {
        state = newState
        stateTimer = duration
    }
}

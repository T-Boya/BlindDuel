import Foundation

/// Game difficulty levels.
/// Each difficulty maps to a concrete `EnemyBehavior` implementation.
enum Difficulty: String, CaseIterable, Codable {
    case easy
    case normal
    case hard
    
    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
    
    /// Duration of the enemy's pre-attack tell (seconds).
    var tellDuration: TimeInterval {
        switch self {
        case .easy: return 0.6
        case .normal: return 0.4
        case .hard: return 0.25
        }
    }
    
    /// Player's reaction window to respond to a strike (seconds).
    var reactionWindow: TimeInterval {
        switch self {
        case .easy: return 0.4
        case .normal: return 0.3
        case .hard: return 0.25
        }
    }
    
    /// Enemy recovery time after a missed or blocked attack (seconds).
    var recoveryDuration: TimeInterval {
        switch self {
        case .easy: return 0.5
        case .normal: return 0.35
        case .hard: return 0.25
        }
    }
    
    /// Create the corresponding AI behavior for this difficulty.
    func makeBehavior() -> EnemyBehavior {
        switch self {
        case .easy: return EasyAI()
        case .normal: return NormalAI()
        case .hard: return HardAI()
        }
    }
}

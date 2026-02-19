import Foundation

/// Easy difficulty AI behavior.
/// Long tells, slow recovery, predictable movement, no fake tells.
/// Designed so a new player can win within 3 rounds.
final class EasyAI: EnemyBehavior {
    
    let displayName = "Easy"
    let aggressionLevel: Float = 0.3
    let fakeTellProbability: Float = 0.0
    
    /// Tracks the current phase of the AI's attack cycle.
    private enum Phase {
        case idle
        case approaching
        case readyToTell
        case told
        case struck
        case recovering
    }
    
    private var phase: Phase = .idle
    private var idleTimer: TimeInterval = 0
    private let idleDuration: TimeInterval = 1.5 // Wait before acting
    
    func nextAction(given state: CombatState) -> EnemyAction {
        switch state.range {
        case .far:
            // Always approach when far, but sometimes reposition first
            if Float.random(in: 0...1) < 0.25 {
                return .reposition
            }
            return .approach
            
        case .mid:
            let roll = Float.random(in: 0...1)
            if roll < aggressionLevel {
                return .approach
            } else if roll < 0.5 {
                return .reposition
            }
            return .wait
            
        case .close:
            // At close range, go through the attack sequence
            if state.enemy.state == .idle {
                let tellType: TellType = Bool.random() ? .inhale : .scrape
                return .tell(tellType)
            }
            return .wait
        }
    }
    
    func reactionDelay(for action: EnemyAction) -> TimeInterval {
        switch action {
        case .approach:
            return 1.2 // Slow approach
        case .tell:
            return 0.6 // Long, readable tell
        case .strike:
            return 0.4 // Slow strike
        case .wait:
            return Double.random(in: 1.0...2.0)
        case .reposition:
            return 1.5
        }
    }
}

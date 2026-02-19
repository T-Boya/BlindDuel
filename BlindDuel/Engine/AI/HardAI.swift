import Foundation

/// Hard difficulty AI behavior.
/// Short tells, occasional fake tells, faster repositioning.
final class HardAI: EnemyBehavior {
    
    let displayName = "Hard"
    let aggressionLevel: Float = 0.7
    let fakeTellProbability: Float = 0.15
    
    func nextAction(given state: CombatState) -> EnemyAction {
        switch state.range {
        case .far:
            return .approach
            
        case .mid:
            let roll = Float.random(in: 0...1)
            if roll < aggressionLevel {
                return .approach
            } else if roll < 0.85 {
                return .reposition
            }
            return .wait
            
        case .close:
            if state.enemy.state == .idle {
                // Occasional fake tell
                if Float.random(in: 0...1) < fakeTellProbability {
                    return .tell(.fake)
                }
                let tellType: TellType = Float.random(in: 0...1) < 0.5 ? .inhale : .scrape
                return .tell(tellType)
            }
            return .wait
        }
    }
    
    func reactionDelay(for action: EnemyAction) -> TimeInterval {
        switch action {
        case .approach:
            return Double.random(in: 0.3...0.6)
        case .tell:
            return 0.25
        case .strike:
            return Double.random(in: 0.2...0.3)
        case .wait:
            return Double.random(in: 0.3...0.8)
        case .reposition:
            return Double.random(in: 0.4...0.7)
        }
    }
}

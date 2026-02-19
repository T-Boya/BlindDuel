import Foundation

/// Normal difficulty AI behavior.
/// Medium tells, variable delays, no fake tells.
final class NormalAI: EnemyBehavior {
    
    let displayName = "Normal"
    let aggressionLevel: Float = 0.5
    let fakeTellProbability: Float = 0.0
    
    func nextAction(given state: CombatState) -> EnemyAction {
        switch state.range {
        case .far:
            return .approach
            
        case .mid:
            let roll = Float.random(in: 0...1)
            if roll < aggressionLevel {
                return .approach
            } else if roll < 0.7 {
                return .reposition
            }
            return .wait
            
        case .close:
            if state.enemy.state == .idle {
                // Vary the tell type
                let tellType: TellType = Float.random(in: 0...1) < 0.6 ? .inhale : .scrape
                return .tell(tellType)
            }
            return .wait
        }
    }
    
    func reactionDelay(for action: EnemyAction) -> TimeInterval {
        switch action {
        case .approach:
            return Double.random(in: 0.6...1.0)
        case .tell:
            return 0.4
        case .strike:
            return Double.random(in: 0.25...0.35)
        case .wait:
            return Double.random(in: 0.5...1.5)
        case .reposition:
            return Double.random(in: 0.8...1.2)
        }
    }
}

import Foundation

/// Phases of a combat round.
enum RoundPhase: Equatable {
    /// Silent tension at the start (1 second).
    case tensionStart
    /// Active combat — input is accepted, AI is running.
    case active
    /// Round has ended — transitioning to result.
    case resolved
}

/// The outcome of a round.
enum RoundResult: Equatable {
    case playerWon
    case playerLost
}

/// Type of pre-attack telegraph the enemy performs.
enum TellType: Equatable {
    /// A sharp directional inhale.
    case inhale
    /// A scraping/movement sound.
    case scrape
    /// A fake tell — no strike follows.
    case fake
}

/// Actions the enemy AI can choose.
enum EnemyAction: Equatable {
    /// Move one step closer to the player.
    case approach
    /// Perform a tell (telegraph) before striking.
    case tell(TellType)
    /// Execute a strike (must be at close range).
    case strike
    /// Wait and hold position.
    case wait
    /// Reposition (change direction).
    case reposition
}

/// The full state of a combat encounter.
/// All combat logic reads and writes through this struct.
struct CombatState {
    /// The player's fighter state.
    var player: Fighter
    
    /// The enemy's fighter state.
    var enemy: Fighter
    
    /// Current range between fighters (discrete, for combat logic).
    var range: RangeState
    
    /// Continuous distance 0.0 (melee) to 1.0 (far). Used for audio smoothing.
    var enemyDistance: Float
    
    /// The enemy's stereo direction (-1.0 = left, 1.0 = right).
    var enemyDirection: Float
    
    /// Current phase of the round.
    var phase: RoundPhase
    
    /// Total elapsed time since the round started.
    var elapsedTime: TimeInterval
    
    /// Time elapsed in the current phase.
    var phaseTime: TimeInterval
    
    /// Create initial combat state for a new round.
    init() {
        self.player = Fighter()
        self.enemy = Fighter()
        self.range = .far
        self.enemyDistance = 1.0
        self.enemyDirection = Float.random(in: -1...1)
        self.phase = .tensionStart
        self.elapsedTime = 0
        self.phaseTime = 0
    }
    
    /// Reset the state for a new round.
    mutating func reset() {
        player.reset()
        enemy.reset()
        range = .far
        enemyDistance = 1.0
        enemyDirection = Float.random(in: -1...1)
        phase = .tensionStart
        elapsedTime = 0
        phaseTime = 0
    }
}

import Foundation

/// The core combat engine.
/// Owns all game rules and state transitions. Depends ONLY on protocol abstractions
/// injected at init — never on AVAudioEngine, CHHapticEngine, or UIKit directly.
///
/// Design principles:
/// - Single Responsibility: Only combat rules. No audio/haptic/rendering logic.
/// - Dependency Inversion: Depends on AudioProviding, HapticProviding (protocols).
/// - Open/Closed: New AI behaviors or input modes don't modify this class.
///
/// The engine reports events via CombatEngineDelegate. The delegate (typically
/// CombatViewController) bridges events to audio and haptics.
final class CombatEngine {
    
    // MARK: - Dependencies (all protocols)
    
    private let enemyBehavior: EnemyBehavior
    weak var delegate: CombatEngineDelegate?
    
    // MARK: - State
    
    private(set) var state: CombatState
    
    /// The difficulty settings (timing values).
    private let difficulty: Difficulty
    
    // MARK: - AI Scheduling
    
    /// Time remaining until the enemy's next scheduled action.
    private var enemyActionTimer: TimeInterval = 0
    
    /// The next action the enemy will perform when the timer expires.
    private var pendingEnemyAction: EnemyAction?
    
    /// Whether the enemy is in the strike window (player can block).
    private var enemyStrikeActive = false
    
    /// Time remaining in the enemy's strike window.
    private var strikeWindowTimer: TimeInterval = 0
    
    /// Time remaining in the enemy's recovery window.
    private var recoveryWindowTimer: TimeInterval = 0
    
    /// Whether the enemy is currently in a recovery window (player can counter).
    private var enemyInRecovery = false
    
    // MARK: - Player State Tracking
    
    /// Whether the player is currently holding guard.
    private var playerGuarding = false
    
    /// Cooldown to prevent spam attacks.
    private var playerAttackCooldown: TimeInterval = 0
    private let attackCooldownDuration: TimeInterval = 0.3
    
    /// Duration for the tension start phase.
    private let tensionDuration: TimeInterval = 1.0
    
    // MARK: - Init
    
    /// Create a combat engine with injected dependencies.
    /// - Parameters:
    ///   - difficulty: The difficulty level (provides timing values).
    ///   - enemyBehavior: The AI strategy for the enemy.
    init(difficulty: Difficulty, enemyBehavior: EnemyBehavior) {
        self.difficulty = difficulty
        self.enemyBehavior = enemyBehavior
        self.state = CombatState()
    }
    
    // MARK: - Round Lifecycle
    
    /// Start a new round. Resets all state.
    func startRound() {
        state.reset()
        enemyActionTimer = 0
        pendingEnemyAction = nil
        enemyStrikeActive = false
        strikeWindowTimer = 0
        recoveryWindowTimer = 0
        enemyInRecovery = false
        playerGuarding = false
        playerAttackCooldown = 0
        
        delegate?.combatEngine(self, phaseDidChange: .tensionStart)
    }
    
    // MARK: - Game Loop Update
    
    /// Called every frame by the game loop.
    /// - Parameter deltaTime: Seconds since last frame.
    func update(deltaTime: TimeInterval) {
        guard state.phase != .resolved else { return }
        
        state.elapsedTime += deltaTime
        state.phaseTime += deltaTime
        
        // Update player attack cooldown
        if playerAttackCooldown > 0 {
            playerAttackCooldown -= deltaTime
        }
        
        // Update fighter state timers
        updateFighterTimers(deltaTime: deltaTime)
        
        switch state.phase {
        case .tensionStart:
            updateTensionPhase()
            
        case .active:
            updateActivePhase(deltaTime: deltaTime)
            
        case .resolved:
            break
        }
    }
    
    // MARK: - Player Actions (from InputDelegate)
    
    /// Handle a player combat action.
    /// - Parameter action: The action the player performed.
    func handlePlayerAction(_ action: CombatAction) {
        guard state.phase == .active else { return }
        
        switch action {
        case .attack:
            handlePlayerAttack()
            
        case .guardStart:
            playerGuarding = true
            state.player.enter(state: .guarding)
            
        case .guardEnd:
            playerGuarding = false
            if state.player.state == .guarding {
                state.player.enter(state: .idle)
            }
            
        case .sidestep:
            handlePlayerSidestep()
        }
    }
    
    // MARK: - Private: Phase Updates
    
    private func updateTensionPhase() {
        if state.phaseTime >= tensionDuration {
            state.phase = .active
            state.phaseTime = 0
            delegate?.combatEngine(self, phaseDidChange: .active)
            
            // Schedule the enemy's first action
            scheduleNextEnemyAction()
        }
    }
    
    private func updateActivePhase(deltaTime: TimeInterval) {
        // Update enemy action timer
        updateEnemyAI(deltaTime: deltaTime)
        
        // Update strike window
        if enemyStrikeActive {
            strikeWindowTimer -= deltaTime
            if strikeWindowTimer <= 0 {
                // Strike window ended — player didn't block or dodge, they get hit
                enemyStrikeActive = false
                resolveEnemyHit()
                if state.phase != .resolved {
                    enterEnemyRecovery()
                }
            }
        }
        
        // Update recovery window
        if enemyInRecovery {
            recoveryWindowTimer -= deltaTime
            if recoveryWindowTimer <= 0 {
                enemyInRecovery = false
                state.enemy.enter(state: .idle)
                // After an attack, retreat before starting next approach
                retreatAfterVolley()
                scheduleNextEnemyAction()
            }
        }
        
        // Update continuous enemy distance (smoothly interpolates toward range target)
        let targetDistance = Self.targetDistance(for: state.range)
        let lerpSpeed: Float = 0.7 // units per second — slow enough to hear the gradient
        let maxStep = Float(deltaTime) * lerpSpeed
        if state.enemyDistance < targetDistance {
            state.enemyDistance = min(state.enemyDistance + maxStep, targetDistance)
        } else if state.enemyDistance > targetDistance {
            state.enemyDistance = max(state.enemyDistance - maxStep, targetDistance)
        }
        
        // Update continuous delegate feedback (enemy position)
        delegate?.combatEngine(self, enemyPositionUpdated: state.range, direction: state.enemyDirection)
    }
    
    // MARK: - Private: Enemy AI
    
    private func updateEnemyAI(deltaTime: TimeInterval) {
        guard !enemyStrikeActive && !enemyInRecovery else { return }
        guard pendingEnemyAction != nil else { return }
        
        enemyActionTimer -= deltaTime
        
        if enemyActionTimer <= 0 {
            executeEnemyAction()
        }
    }
    
    private func scheduleNextEnemyAction() {
        let action = enemyBehavior.nextAction(given: state)
        let delay = enemyBehavior.reactionDelay(for: action)
        
        pendingEnemyAction = action
        enemyActionTimer = delay
    }
    
    private func executeEnemyAction() {
        guard let action = pendingEnemyAction else { return }
        pendingEnemyAction = nil
        
        switch action {
        case .approach:
            // Close range by one step
            let newRange = state.range.closer
            if newRange != state.range {
                // If player is sidestepping, negate the approach
                if state.player.state == .sidestepping {
                    // Range doesn't change
                } else {
                    state.range = newRange
                    delegate?.combatEngine(self, rangeDidChange: newRange)
                }
            }
            scheduleNextEnemyAction()
            
        case .tell(let type):
            state.enemy.enter(state: .telling, duration: difficulty.tellDuration)
            delegate?.combatEngine(self, enemyDidTell: type, from: state.enemyDirection)
            
            if type == .fake {
                // Fake tell — no strike follows, go back to idle after tell duration
                enemyActionTimer = difficulty.tellDuration
                pendingEnemyAction = .wait
            } else {
                // Schedule the actual strike after tell duration
                enemyActionTimer = difficulty.tellDuration
                pendingEnemyAction = .strike
            }
            
        case .strike:
            executeEnemyStrike()
            
        case .wait:
            state.enemy.enter(state: .idle)
            scheduleNextEnemyAction()
            
        case .reposition:
            // Shift the enemy's stereo direction
            state.enemyDirection = Float.random(in: -1...1)
            delegate?.combatEngine(self, enemyPositionUpdated: state.range, direction: state.enemyDirection)
            scheduleNextEnemyAction()
        }
    }
    
    private func executeEnemyStrike() {
        guard state.range == .close else {
            // Can't strike if not at close range (they moved away somehow)
            state.enemy.enter(state: .idle)
            scheduleNextEnemyAction()
            return
        }
        
        state.enemy.enter(state: .attacking)
        delegate?.combatEngine(self, enemyDidStrike: state.enemyDirection)
        
        // Open the strike window — player can block during this
        enemyStrikeActive = true
        strikeWindowTimer = difficulty.reactionWindow
        
        // Check if player is already guarding
        if playerGuarding {
            resolveBlock()
        }
    }
    
    // MARK: - Private: Player Actions
    
    private func handlePlayerAttack() {
        guard playerAttackCooldown <= 0 else { return }
        guard state.player.state == .idle || state.player.state == .guarding else { return }
        
        playerAttackCooldown = attackCooldownDuration
        state.player.enter(state: .attacking, duration: 0.2)
        
        if state.range != .close {
            // Attack whiffs — not close enough
            return
        }
        
        if enemyStrikeActive {
            // Both attacking simultaneously — trade damage
            resolveTrade()
        } else if enemyInRecovery {
            // Enemy is recovering — guaranteed hit
            resolvePlayerHit()
        } else if state.enemy.state == .telling {
            // Interrupt during tell — risky but possible, treat as a hit
            resolvePlayerHit()
        } else {
            // Enemy is idle at close range — standard attack attempt
            // Enemy can potentially block, but for MVP, idle enemy gets hit
            resolvePlayerHit()
        }
    }
    
    private func handlePlayerSidestep() {
        guard state.player.state == .idle || state.player.state == .guarding else { return }
        
        playerGuarding = false
        state.player.enter(state: .sidestepping, duration: 0.4)
        
        // If enemy is about to strike, sidestep dodges it
        if enemyStrikeActive {
            enemyStrikeActive = false
            enterEnemyRecovery()
        }
    }
    
    // MARK: - Private: Damage Resolution
    
    private func resolvePlayerHit() {
        state.enemy.takeDamage()
        delegate?.combatEngine(self, enemyDidTakeDamage: state.enemy.hp)
        
        checkRoundEnd()
    }
    
    private func resolveEnemyHit() {
        state.player.takeDamage()
        delegate?.combatEngine(self, playerDidTakeDamage: state.player.hp)
        
        checkRoundEnd()
    }
    
    private func resolveTrade() {
        // Both hit each other
        state.player.takeDamage()
        state.enemy.takeDamage()
        
        delegate?.combatEngine(self, playerDidTakeDamage: state.player.hp)
        delegate?.combatEngine(self, enemyDidTakeDamage: state.enemy.hp)
        
        enemyStrikeActive = false
        
        checkRoundEnd()
    }
    
    private func resolveBlock() {
        // Player successfully blocked the strike
        enemyStrikeActive = false
        delegate?.combatEnginePlayerDidBlock(self)
        enterEnemyRecovery()
    }
    
    private func enterEnemyRecovery() {
        enemyInRecovery = true
        recoveryWindowTimer = difficulty.recoveryDuration
        state.enemy.enter(state: .recovering, duration: difficulty.recoveryDuration)
    }
    
    /// After an attack volley, the enemy retreats 1-2 steps.
    private func retreatAfterVolley() {
        let newRange = state.range.farther
        if newRange != state.range {
            state.range = newRange
            delegate?.combatEngine(self, rangeDidChange: newRange)
            // Sometimes retreat two steps
            if Float.random(in: 0...1) < 0.3 {
                let furtherRange = state.range.farther
                if furtherRange != state.range {
                    state.range = furtherRange
                    delegate?.combatEngine(self, rangeDidChange: furtherRange)
                }
            }
        }
    }
    
    // MARK: - Private: Fighter Timers
    
    private func updateFighterTimers(deltaTime: TimeInterval) {
        // Player state timer
        if state.player.stateTimer > 0 {
            state.player.stateTimer -= deltaTime
            if state.player.stateTimer <= 0 {
                state.player.stateTimer = 0
                if state.player.state != .guarding { // Guard is manually released
                    state.player.enter(state: .idle)
                }
            }
        }
        
        // Enemy state timer
        if state.enemy.stateTimer > 0 {
            state.enemy.stateTimer -= deltaTime
            if state.enemy.stateTimer <= 0 {
                state.enemy.stateTimer = 0
                // Don't auto-reset enemy — handled by AI scheduling
            }
        }
    }
    
    // MARK: - Private: Round End
    
    private func checkRoundEnd() {
        if !state.player.isAlive {
            endRound(result: .playerLost)
        } else if !state.enemy.isAlive {
            endRound(result: .playerWon)
        }
    }
    
    private func endRound(result: RoundResult) {
        state.phase = .resolved
        delegate?.combatEngine(self, phaseDidChange: .resolved)
        delegate?.combatEngine(self, roundDidEnd: result)
    }
    
    // MARK: - Distance Mapping
    
    /// Target continuous distance for a given range state.
    /// 0.0 = melee, 1.0 = far away.
    static func targetDistance(for range: RangeState) -> Float {
        switch range {
        case .far:   return 1.0
        case .mid:   return 0.5
        case .close: return 0.1
        }
    }
}

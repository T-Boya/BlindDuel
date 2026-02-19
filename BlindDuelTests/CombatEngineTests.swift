import XCTest
@testable import BlindDuel

/// Tests for the CombatEngine — the core game logic.
/// Uses mock dependencies for fully deterministic, isolated tests.
final class CombatEngineTests: XCTestCase {
    
    private var engine: CombatEngine!
    private var gameLoop: MockGameLoop!
    private var delegate: TestCombatDelegate!
    
    override func setUp() {
        super.setUp()
        engine = CombatEngine(difficulty: .easy, enemyBehavior: EasyAI())
        gameLoop = MockGameLoop()
        delegate = TestCombatDelegate()
        engine.delegate = delegate
        
        gameLoop.updateHandler = { [weak self] dt in
            self?.engine.update(deltaTime: dt)
        }
        gameLoop.start()
    }
    
    override func tearDown() {
        engine = nil
        gameLoop = nil
        delegate = nil
        super.tearDown()
    }
    
    // MARK: - Round Lifecycle
    
    func testStartRoundInitializesState() {
        engine.startRound()
        
        XCTAssertEqual(engine.state.player.hp, 3)
        XCTAssertEqual(engine.state.enemy.hp, 3)
        XCTAssertEqual(engine.state.range, .far)
        XCTAssertEqual(engine.state.phase, .tensionStart)
    }
    
    func testTensionPhaseTransitionsToActive() {
        engine.startRound()
        
        // Advance past the 1-second tension phase
        gameLoop.tickFrames(70) // > 1 second at 60fps
        
        XCTAssertTrue(delegate.phaseChanges.contains(.active))
    }
    
    // MARK: - Player Actions
    
    func testAttackWhiffsAtFarRange() {
        engine.startRound()
        gameLoop.tickFrames(70) // Enter active phase
        
        let initialEnemyHP = engine.state.enemy.hp
        engine.handlePlayerAction(.attack)
        
        XCTAssertEqual(engine.state.enemy.hp, initialEnemyHP, "Attack should not land at far range")
    }
    
    func testGuardChangesPlayerState() {
        engine.startRound()
        gameLoop.tickFrames(70)
        
        engine.handlePlayerAction(.guardStart)
        XCTAssertEqual(engine.state.player.state, .guarding)
        
        engine.handlePlayerAction(.guardEnd)
        XCTAssertEqual(engine.state.player.state, .idle)
    }
    
    func testSidestepChangesPlayerState() {
        engine.startRound()
        gameLoop.tickFrames(70)
        
        engine.handlePlayerAction(.sidestep)
        XCTAssertEqual(engine.state.player.state, .sidestepping)
    }
    
    // MARK: - Damage Resolution
    
    func testPlayerHPDecreasesOnDamage() {
        var fighter = Fighter(maxHP: 3)
        XCTAssertEqual(fighter.hp, 3)
        
        fighter.takeDamage()
        XCTAssertEqual(fighter.hp, 2)
        
        fighter.takeDamage()
        XCTAssertEqual(fighter.hp, 1)
        
        fighter.takeDamage()
        XCTAssertEqual(fighter.hp, 0)
        XCTAssertFalse(fighter.isAlive)
    }
    
    func testFighterDoesNotGoBelowZeroHP() {
        var fighter = Fighter(maxHP: 1)
        fighter.takeDamage()
        fighter.takeDamage() // Extra damage
        
        XCTAssertEqual(fighter.hp, 0)
    }
    
    // MARK: - Range System
    
    func testRangeCloserAndFarther() {
        XCTAssertEqual(RangeState.far.closer, .mid)
        XCTAssertEqual(RangeState.mid.closer, .close)
        XCTAssertEqual(RangeState.close.closer, .close) // Can't get closer
        
        XCTAssertEqual(RangeState.close.farther, .mid)
        XCTAssertEqual(RangeState.mid.farther, .far)
        XCTAssertEqual(RangeState.far.farther, .far) // Can't get farther
    }
    
    // MARK: - Phase Restrictions
    
    func testActionsIgnoredDuringTensionPhase() {
        engine.startRound()
        // Don't advance past tension
        
        let initialState = engine.state.player.state
        engine.handlePlayerAction(.attack)
        
        XCTAssertEqual(engine.state.player.state, initialState, "Actions should be ignored during tension phase")
    }
}

// MARK: - Test Delegate

/// Records all delegate calls for assertion in tests.
private final class TestCombatDelegate: CombatEngineDelegate {
    var phaseChanges: [RoundPhase] = []
    var playerDamageEvents: [Int] = []
    var enemyDamageEvents: [Int] = []
    var rangeChanges: [RangeState] = []
    var roundResults: [RoundResult] = []
    var blockCount = 0
    
    func combatEngine(_ engine: CombatEngine, phaseDidChange phase: RoundPhase) {
        phaseChanges.append(phase)
    }
    
    func combatEngine(_ engine: CombatEngine, playerDidTakeDamage remainingHP: Int) {
        playerDamageEvents.append(remainingHP)
    }
    
    func combatEngine(_ engine: CombatEngine, enemyDidTakeDamage remainingHP: Int) {
        enemyDamageEvents.append(remainingHP)
    }
    
    func combatEngine(_ engine: CombatEngine, rangeDidChange newRange: RangeState) {
        rangeChanges.append(newRange)
    }
    
    func combatEngine(_ engine: CombatEngine, enemyDidTell type: TellType, from direction: Float) {}
    
    func combatEngine(_ engine: CombatEngine, enemyDidStrike direction: Float) {}
    
    func combatEnginePlayerDidBlock(_ engine: CombatEngine) {
        blockCount += 1
    }
    
    func combatEngine(_ engine: CombatEngine, roundDidEnd result: RoundResult) {
        roundResults.append(result)
    }
    
    func combatEngine(_ engine: CombatEngine, enemyPositionUpdated range: RangeState, direction: Float) {}
}

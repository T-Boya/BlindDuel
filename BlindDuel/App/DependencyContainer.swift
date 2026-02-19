import UIKit

/// Composition root — the single place that knows about concrete types.
/// Builds and wires all dependencies. Nothing else in the app imports concrete
/// managers directly; everything works through protocols.
final class DependencyContainer {
    
    // MARK: - Singleton Instances (owned by container)
    
    let audioManager: AudioProviding
    let hapticManager: HapticProviding
    let inputManager: InputManager
    
    // MARK: - Init
    
    init() {
        // Create concrete implementations
        let audio = AudioManager()
        let haptics = HapticManager()
        let input = InputManager()
        
        // Register input providers
        input.register(TouchInputProvider())
        input.register(HeadGestureInputProvider())
        
        // Store as protocol types
        self.audioManager = audio
        self.hapticManager = haptics
        self.inputManager = input
    }
    
    // MARK: - Factory Methods
    
    /// Create a new game loop (one per combat session).
    func makeGameLoop() -> GameLoopProviding {
        DisplayLinkGameLoop()
    }
    
    /// Create a combat engine for the given difficulty.
    func makeCombatEngine(difficulty: Difficulty) -> CombatEngine {
        let behavior = difficulty.makeBehavior()
        return CombatEngine(difficulty: difficulty, enemyBehavior: behavior)
    }
    
    /// Create the combat view controller, fully wired.
    func makeCombatViewController(difficulty: Difficulty) -> CombatViewController {
        let gameLoop = makeGameLoop()
        let engine = makeCombatEngine(difficulty: difficulty)
        
        return CombatViewController(
            audio: audioManager,
            haptics: hapticManager,
            inputManager: inputManager,
            gameLoop: gameLoop,
            engine: engine
        )
    }
    
    /// Create the menu view controller.
    func makeMenuViewController() -> MenuViewController {
        let savedDifficulty = UserDefaults.standard.string(forKey: "BlindDuel.difficulty")
            .flatMap { Difficulty(rawValue: $0) } ?? .easy
        
        return MenuViewController(inputManager: inputManager, difficulty: savedDifficulty)
    }
    
    /// Create the onboarding view controller.
    func makeOnboardingViewController() -> OnboardingViewController {
        OnboardingViewController()
    }
    
    /// Create the calibration view controller.
    func makeCalibrationViewController() -> CalibrationViewController {
        CalibrationViewController()
    }
    
    /// Create the result view controller.
    func makeResultViewController(result: RoundResult) -> ResultViewController {
        ResultViewController(result: result)
    }
}

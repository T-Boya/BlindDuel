import UIKit
import AVFoundation

/// The combat screen — completely black. No UI at all.
/// Hosts gesture input, drives the combat engine, and bridges engine events
/// to audio and haptics.
///
/// This is the "coordinator" between all subsystems during a round.
final class CombatViewController: UIViewController, CombatEngineDelegate, InputDelegate {
    
    // MARK: - Dependencies (injected)
    
    private let audio: AudioProviding
    private let haptics: HapticProviding
    private let inputManager: InputManager
    private let gameLoop: GameLoopProviding
    private let engine: CombatEngine
    
    // MARK: - Callbacks
    
    var onRoundEnd: ((RoundResult) -> Void)?
    
    // MARK: - Headphone Monitoring
    
    private var headphonePauseOverlay: UIView?
    private var isPausedForHeadphones = false
    
    // MARK: - Footstep Approach Tracking
    
    /// True when the enemy just advanced closer (triggers running tempo).
    private var isEnemyApproaching = false
    
    /// Tracks the previous range so we can detect approaches.
    private var previousRange: RangeState = .far
    
    // MARK: - Init
    
    init(
        audio: AudioProviding,
        haptics: HapticProviding,
        inputManager: InputManager,
        gameLoop: GameLoopProviding,
        engine: CombatEngine
    ) {
        self.audio = audio
        self.haptics = haptics
        self.inputManager = inputManager
        self.gameLoop = gameLoop
        self.engine = engine
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Wire up delegates
        engine.delegate = self
        inputManager.delegate = self
        
        // Game loop drives the engine
        gameLoop.updateHandler = { [weak self] dt in
            self?.engine.update(deltaTime: dt)
        }
        
        // Headphone monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // App lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCombat()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCombat()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Combat Lifecycle
    
    private func startCombat() {
        // Start subsystems
        do {
            try audio.start()
            try haptics.start()
        } catch {
            print("[Combat] Failed to start audio/haptics: \(error)")
        }
        
        // Activate input
        inputManager.activatePreferred(in: view)
        
        // Start the round
        engine.startRound()
        gameLoop.start()
    }
    
    private func stopCombat() {
        gameLoop.stop()
        inputManager.deactivateAll()
        audio.stop()
        haptics.stop()
    }
    
    // MARK: - InputDelegate
    
    func inputProvider(_ provider: InputProviding, didPerform action: CombatAction) {
        guard !isPausedForHeadphones else { return }
        engine.handlePlayerAction(action)
    }
    
    // MARK: - CombatEngineDelegate
    
    func combatEngine(_ engine: CombatEngine, playerDidTakeDamage remainingHP: Int) {
        // Audio: centered hit impact
        audio.playPlayerHit()
        audio.updatePlayerBreathing(hp: remainingHP)
        
        // Haptics: sharp pulse (player only)
        haptics.playPlayerDamage()
        
        // Start heartbeat at 1 HP
        if remainingHP == 1 {
            haptics.startHeartbeat()
        }
    }
    
    func combatEngine(_ engine: CombatEngine, enemyDidTakeDamage remainingHP: Int) {
        // Audio: hit from enemy direction (reverberant)
        audio.playEnemyHit(from: engine.state.enemyDirection)
        audio.updateEnemyBreathing(hp: remainingHP, destabilized: true)
        
        // NO haptics for enemy damage — ownership rule
    }
    
    func combatEngine(_ engine: CombatEngine, rangeDidChange newRange: RangeState) {
        audio.updateEnemyPosition(range: newRange, direction: engine.state.enemyDirection)
        
        // Detect approach (enemy moved closer) → trigger running footstep tempo
        if newRange > previousRange {
            isEnemyApproaching = true
            // Clear approach flag after 1.5s (run resolves into walking)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.isEnemyApproaching = false
            }
        }
        previousRange = newRange
        
        // Update footstep parameters with continuous distance
        audio.updateEnemyFootsteps(distance: engine.state.enemyDistance, direction: engine.state.enemyDirection, isApproaching: isEnemyApproaching)
        
        // Update proximity rumble
        switch newRange {
        case .far:
            haptics.stopProximityRumble()
        case .mid:
            haptics.startProximityRumble(intensity: 0.3)
        case .close:
            haptics.startProximityRumble(intensity: 0.7)
        }
    }
    
    func combatEngine(_ engine: CombatEngine, enemyDidTell type: TellType, from direction: Float) {
        audio.playEnemyTell(from: direction)
    }
    
    func combatEngine(_ engine: CombatEngine, enemyDidStrike direction: Float) {
        audio.playEnemyStrike(from: direction)
    }
    
    func combatEnginePlayerDidBlock(_ engine: CombatEngine) {
        audio.playPlayerBlock()
        haptics.playPlayerBlock()
    }
    
    func combatEngine(_ engine: CombatEngine, roundDidEnd result: RoundResult) {
        gameLoop.stop()
        
        // Stop continuous haptics
        haptics.stopHeartbeat()
        haptics.stopProximityRumble()
        
        // Stop footsteps
        audio.stopEnemyFootsteps()
        
        // Play result feedback
        audio.playRoundEnd(won: result == .playerWon)
        haptics.playRoundResult(won: result == .playerWon)
        
        // Update streak
        updateStreak(won: result == .playerWon)
        
        // Delay before showing result to let audio/haptics play out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.stopCombat()
            self?.onRoundEnd?(result)
        }
    }
    
    func combatEngine(_ engine: CombatEngine, enemyPositionUpdated range: RangeState, direction: Float) {
        audio.updateEnemyPosition(range: range, direction: direction)
        audio.updateEnemyFootsteps(distance: engine.state.enemyDistance, direction: direction, isApproaching: isEnemyApproaching)
    }
    
    func combatEngine(_ engine: CombatEngine, phaseDidChange phase: RoundPhase) {
        switch phase {
        case .tensionStart:
            audio.startAmbience()
        case .active:
            audio.playRoundStart()
            audio.updatePlayerBreathing(hp: engine.state.player.hp)
            audio.updateEnemyBreathing(hp: engine.state.enemy.hp, destabilized: false)
            // Start heel-click footsteps — the primary proximity cue
            audio.startEnemyFootsteps()
            audio.updateEnemyFootsteps(distance: engine.state.enemyDistance, direction: engine.state.enemyDirection, isApproaching: false)
        case .resolved:
            audio.stopAmbience()
            audio.stopEnemyFootsteps()
        }
    }
    
    // MARK: - Headphone Monitoring
    
    @objc private func audioRouteChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.isHeadphonesConnected() {
                self.pauseForHeadphones()
            } else if self.isPausedForHeadphones {
                self.resumeFromHeadphones()
            }
        }
    }
    
    private func isHeadphonesConnected() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        return route.outputs.contains { output in
            output.portType == .headphones ||
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothLE ||
            output.portType == .bluetoothHFP
        }
    }
    
    private func pauseForHeadphones() {
        isPausedForHeadphones = true
        gameLoop.pause()
        
        // Show a minimal "plug in headphones" overlay
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .black
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let label = UILabel()
        label.text = "Plug in headphones to continue"
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        ])
        
        view.addSubview(overlay)
        headphonePauseOverlay = overlay
    }
    
    private func resumeFromHeadphones() {
        isPausedForHeadphones = false
        headphonePauseOverlay?.removeFromSuperview()
        headphonePauseOverlay = nil
        gameLoop.resume()
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appDidEnterBackground() {
        gameLoop.pause()
    }
    
    @objc private func appWillEnterForeground() {
        if !isPausedForHeadphones {
            gameLoop.resume()
        }
    }
    
    // MARK: - Stats
    
    private func updateStreak(won: Bool) {
        let key = "BlindDuel.winStreak"
        if won {
            let current = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(current + 1, forKey: key)
        } else {
            UserDefaults.standard.set(0, forKey: key)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

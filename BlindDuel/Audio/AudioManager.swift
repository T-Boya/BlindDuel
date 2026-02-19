import AVFoundation

/// Concrete spatial audio manager using AVAudioEngine + AVAudioEnvironmentNode.
/// Conforms to AudioProviding — the combat engine depends only on the protocol.
///
/// Audio identity rules:
/// - Player sounds: centered (0,0,0), dry (no reverb), mono — feels internal
/// - Enemy sounds: positioned in stereo, reverberant — feels external in the room
final class AudioManager: AudioProviding {
    
    // MARK: - Core Audio Graph
    
    private let engine = AVAudioEngine()
    private let environmentNode = AVAudioEnvironmentNode()
    
    // MARK: - Spatial Sources
    
    // Player sources (centered, dry)
    private let playerBreathSource = SpatialSource()
    private let playerHeartbeatSource = SpatialSource()
    private let playerHitSource = SpatialSource()
    private let playerBlockSource = SpatialSource()
    
    // Enemy sources (positional, reverberant)
    private let enemyBreathSource = SpatialSource()
    private let enemyTellSource = SpatialSource()
    private let enemyStrikeSource = SpatialSource()
    private let enemyHitSource = SpatialSource()
    
    // Enemy footstep sources (heel clicks, alternated for natural variation)
    private let footstepSourceA = SpatialSource()
    private let footstepSourceB = SpatialSource()
    
    // Ambience
    private let ambienceSource = SpatialSource()
    private let roundStartSource = SpatialSource()
    private let roundEndSource = SpatialSource()
    
    // MARK: - State
    
    private var isRunning = false
    private var currentPlayerHP = 3
    
    // MARK: - Footstep Scheduling State
    
    /// Timer that fires each footstep click.
    private var footstepTimer: Timer?
    
    /// Alternates between the two click samples.
    private var footstepUseAlt = false
    
    /// Current target x-position the footstep wanders toward.
    private var footstepTargetX: Float = 0
    
    /// Current actual x-position (smoothed toward target).
    private var footstepCurrentX: Float = 0
    
    /// Continuous enemy distance 0.0 (melee) to 1.0 (far). Drives volume/tempo/z-depth.
    private var footstepDistance: Float = 1.0
    
    /// Whether the enemy is actively approaching (running tempo).
    private var footstepIsApproaching = false
    
    /// Whether footsteps are active.
    private var footstepsActive = false
    
    // MARK: - Position Mapping
    
    /// Map range state to a z-distance for the enemy audio source.
    private func zPosition(for range: RangeState) -> Float {
        switch range {
        case .far: return -5.0
        case .mid: return -2.5
        case .close: return -0.8
        }
    }
    
    /// Map range state to a reverb blend for the enemy.
    private func reverbBlend(for range: RangeState) -> Float {
        switch range {
        case .far: return 0.5
        case .mid: return 0.35
        case .close: return 0.2
        }
    }
    
    // MARK: - AudioProviding
    
    func start() throws {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        
        // Configure environment node (reverb)
        environmentNode.reverbParameters.enable = true
        environmentNode.reverbParameters.loadFactoryReverbPreset(.mediumRoom)
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
        
        // Attach environment node to engine
        engine.attach(environmentNode)
        engine.connect(environmentNode, to: engine.mainMixerNode, format: nil)
        
        // Configure and attach all sources
        configureSources()
        
        // Start the engine
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        engine.stop()
        isRunning = false
    }
    
    // MARK: - Enemy Sounds
    
    func playEnemyTell(from direction: Float) {
        updateSourcePosition(enemyTellSource, direction: direction)
        enemyTellSource.playOnce()
    }
    
    func playEnemyStrike(from direction: Float) {
        updateSourcePosition(enemyStrikeSource, direction: direction)
        enemyStrikeSource.playOnce()
    }
    
    func playEnemyHit(from direction: Float) {
        updateSourcePosition(enemyHitSource, direction: direction)
        enemyHitSource.playOnce()
    }
    
    func updateEnemyPosition(range: RangeState, direction: Float) {
        let z = zPosition(for: range)
        let x = direction * 2.5 // Scale direction to spatial width
        let position = AVAudio3DPoint(x: x, y: 0, z: z)
        let reverb = reverbBlend(for: range)
        
        // Update all enemy sources
        let enemySources = [enemyBreathSource, enemyTellSource, enemyStrikeSource, enemyHitSource]
        for source in enemySources {
            source.position = position
            source.reverbBlend = reverb
        }
    }
    
    func updateEnemyBreathing(hp: Int, destabilized: Bool) {
        if hp > 0 && !enemyBreathSource.isPlaying {
            enemyBreathSource.playLooping()
        }
        
        // Adjust volume based on health
        enemyBreathSource.volume = destabilized ? 0.4 : (hp <= 1 ? 0.9 : 0.7)
        
        if hp <= 0 {
            enemyBreathSource.stop()
        }
    }
    
    // MARK: - Player Sounds
    
    func playPlayerHit() {
        playerHitSource.playOnce()
    }
    
    func playPlayerBlock() {
        playerBlockSource.playOnce()
    }
    
    func updatePlayerBreathing(hp: Int) {
        currentPlayerHP = hp
        
        switch hp {
        case 3:
            if !playerBreathSource.isPlaying {
                playerBreathSource.loadBuffer(named: AudioAssets.playerBreathHealthy)
                playerBreathSource.playLooping()
            }
            playerHeartbeatSource.stop()
            
        case 2:
            playerBreathSource.stop()
            playerBreathSource.loadBuffer(named: AudioAssets.playerBreathHurt)
            playerBreathSource.playLooping()
            playerHeartbeatSource.stop()
            
        case 1:
            playerBreathSource.stop()
            playerBreathSource.loadBuffer(named: AudioAssets.playerBreathHurt)
            playerBreathSource.volume = 1.0
            playerBreathSource.playLooping()
            // Add heartbeat layer
            playerHeartbeatSource.playLooping()
            
        default:
            playerBreathSource.stop()
            playerHeartbeatSource.stop()
        }
    }
    
    // MARK: - Enemy Footsteps
    
    func startEnemyFootsteps() {
        guard !footstepsActive else { return }
        footstepsActive = true
        footstepCurrentX = 0
        footstepTargetX = Float.random(in: -1.0...1.0)
        scheduleNextFootstep()
    }
    
    func stopEnemyFootsteps() {
        footstepsActive = false
        footstepTimer?.invalidate()
        footstepTimer = nil
        footstepSourceA.stop()
        footstepSourceB.stop()
    }
    
    func updateEnemyFootsteps(distance: Float, direction: Float, isApproaching: Bool) {
        footstepDistance = distance
        footstepIsApproaching = isApproaching
        // Nudge target toward the enemy's actual direction but add randomness
        footstepTargetX = direction + Float.random(in: -0.3...0.3)
        footstepTargetX = max(-1.0, min(1.0, footstepTargetX))
        
        // If very close (melee), stop footsteps — they're standing in front of you
        if distance < 0.12 && footstepsActive {
            footstepTimer?.invalidate()
            footstepTimer = nil
        } else if distance >= 0.12 && footstepsActive && footstepTimer == nil {
            scheduleNextFootstep()
        }
    }
    
    // MARK: - Private Footstep Scheduling
    
    /// Interval between heel clicks — smooth gradient from distance.
    /// Far (1.0) = slow walk, close (0.15) = quick steps, approach = running.
    private func footstepInterval() -> TimeInterval {
        // Linear interpolation: distance 1.0 → 1.1s, distance 0.15 → 0.35s
        let t = max(0.0, min(1.0, footstepDistance))
        let base = Double(0.35 + t * 0.75) // 0.35s at closest, 1.1s at farthest
        // Running: 60% of normal interval
        return footstepIsApproaching ? base * 0.6 : base
    }
    
    /// Volume for footstep — smooth gradient from distance.
    /// Far = quiet, close = loud.
    private func footstepVolume() -> Float {
        let t = max(0.0, min(1.0, footstepDistance))
        // distance 0.0 → volume 0.95,  distance 1.0 → volume 0.15
        return 0.95 - t * 0.80
    }
    
    /// Z-depth for footstep — smooth gradient from distance.
    private func footstepZ() -> Float {
        let t = max(0.0, min(1.0, footstepDistance))
        // distance 0.0 → z = -0.5, distance 1.0 → z = -6.0
        return -0.5 - t * 5.5
    }
    
    /// Reverb blend — smooth gradient from distance.
    private func footstepReverb() -> Float {
        let t = max(0.0, min(1.0, footstepDistance))
        // distance 0.0 → 0.15 (dry/present), distance 1.0 → 0.55 (reverberant/far)
        return 0.15 + t * 0.40
    }
    
    /// Schedule the next footstep click.
    private func scheduleNextFootstep() {
        let interval = footstepInterval()
        footstepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.fireFootstep()
        }
    }
    
    /// Play one heel click and schedule the next.
    private func fireFootstep() {
        guard footstepsActive else { return }
        
        // Smoothly drift position toward the wandering target (small steps)
        let drift: Float = 0.06
        if footstepCurrentX < footstepTargetX {
            footstepCurrentX = min(footstepCurrentX + drift, footstepTargetX)
        } else {
            footstepCurrentX = max(footstepCurrentX - drift, footstepTargetX)
        }
        
        // Occasionally pick a new random target (simulating unpredictable movement)
        if Float.random(in: 0...1) < 0.30 {
            footstepTargetX = Float.random(in: -1.0...1.0)
        }
        
        let z = footstepZ()
        let x = footstepCurrentX * 2.5 // Scale to spatial width
        let position = AVAudio3DPoint(x: x, y: 0, z: z)
        let reverb = footstepReverb()
        let vol = footstepVolume()
        
        // Pick the source and alternate
        let source = footstepUseAlt ? footstepSourceB : footstepSourceA
        footstepUseAlt.toggle()
        
        source.position = position
        source.reverbBlend = reverb
        source.volume = vol
        source.playOnce()
        
        // Schedule the next click
        scheduleNextFootstep()
    }
    
    // MARK: - Ambience & Round
    
    func startAmbience() {
        ambienceSource.playLooping()
    }
    
    func stopAmbience() {
        ambienceSource.stop()
    }
    
    func playRoundStart() {
        roundStartSource.playOnce()
    }
    
    func playRoundEnd(won: Bool) {
        // Stop all combat audio
        playerBreathSource.stop()
        playerHeartbeatSource.stop()
        enemyBreathSource.stop()
        stopEnemyFootsteps()
        
        if won {
            roundEndSource.loadBuffer(named: AudioAssets.roundWin)
        } else {
            roundEndSource.loadBuffer(named: AudioAssets.roundLose)
        }
        roundEndSource.playOnce()
    }
    
    // MARK: - Private Setup
    
    private func configureSources() {
        // Player sources: centered, dry
        let playerSources = [playerBreathSource, playerHeartbeatSource, playerHitSource, playerBlockSource]
        for source in playerSources {
            source.position = AVAudio3DPoint(x: 0, y: 0, z: 0)
            source.reverbBlend = 0.0 // Dry — feels internal
            source.renderingAlgorithm = .equalPowerPanning
            attachSource(source)
        }
        
        // Enemy sources: positional, reverberant
        let enemySources = [enemyBreathSource, enemyTellSource, enemyStrikeSource, enemyHitSource]
        for source in enemySources {
            source.position = AVAudio3DPoint(x: 0, y: 0, z: -5.0) // Start far
            source.reverbBlend = 0.5
            source.renderingAlgorithm = .HRTFHQ // Full 3D spatialization for headphones
            attachSource(source)
        }
        
        // Footstep sources: positional, reverberant, HRTFHQ (wandering heel clicks)
        let footstepSources = [footstepSourceA, footstepSourceB]
        for source in footstepSources {
            source.position = AVAudio3DPoint(x: 0, y: 0, z: -5.0)
            source.reverbBlend = 0.5
            source.renderingAlgorithm = .HRTFHQ
            attachSource(source)
        }
        
        // Ambience/UI sources: centered, slight reverb
        let uiSources = [ambienceSource, roundStartSource, roundEndSource]
        for source in uiSources {
            source.position = AVAudio3DPoint(x: 0, y: 0, z: 0)
            source.reverbBlend = 0.1
            source.renderingAlgorithm = .equalPowerPanning
            attachSource(source)
        }
        
        // Load default buffers
        playerBreathSource.loadBuffer(named: AudioAssets.playerBreathHealthy)
        playerHeartbeatSource.loadBuffer(named: AudioAssets.playerHeartbeat)
        playerHitSource.loadBuffer(named: AudioAssets.playerHitGrunt)
        playerBlockSource.loadBuffer(named: AudioAssets.playerBlock)
        
        enemyBreathSource.loadBuffer(named: AudioAssets.enemyBreath)
        enemyTellSource.loadBuffer(named: AudioAssets.enemyTellInhale)
        enemyStrikeSource.loadBuffer(named: AudioAssets.enemyStrikeWhoosh)
        enemyHitSource.loadBuffer(named: AudioAssets.enemyHitGrunt)
        
        footstepSourceA.loadBuffer(named: AudioAssets.enemyFootstep)
        footstepSourceB.loadBuffer(named: AudioAssets.enemyFootstepAlt)
        
        ambienceSource.loadBuffer(named: AudioAssets.ambientRoomTone)
        roundStartSource.loadBuffer(named: AudioAssets.roundStartTone)
        roundEndSource.loadBuffer(named: AudioAssets.roundWin)
    }
    
    /// Mono format used for all spatial source connections.
    /// AVAudioEnvironmentNode requires mono input for 3D spatialization.
    private lazy var monoFormat: AVAudioFormat = {
        AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    }()
    
    /// Attach a spatial source's player node to the environment node.
    private func attachSource(_ source: SpatialSource) {
        engine.attach(source.playerNode)
        // Connect with explicit mono format — environment node requires mono for spatialization
        engine.connect(source.playerNode, to: environmentNode, format: monoFormat)
    }
    
    /// Update a source's position to match the current enemy direction/range.
    private func updateSourcePosition(_ source: SpatialSource, direction: Float) {
        // Use the current position's z but update x for direction
        var pos = source.position
        pos.x = direction * 2.0
        source.position = pos
    }
}

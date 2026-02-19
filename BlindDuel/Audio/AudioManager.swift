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
    
    // Ambience
    private let ambienceSource = SpatialSource()
    private let roundStartSource = SpatialSource()
    private let roundEndSource = SpatialSource()
    
    // MARK: - State
    
    private var isRunning = false
    private var currentPlayerHP = 3
    
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
        let x = direction * 2.0 // Scale direction to spatial width
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

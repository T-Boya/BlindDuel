import Foundation

/// Constants for audio asset file names.
/// All sound files are expected in the app bundle under Resources/Sounds/.
enum AudioAssets {
    // MARK: - Player Sounds (centered, dry)
    static let playerBreathHealthy = "player_breath_healthy"
    static let playerBreathHurt = "player_breath_hurt"
    static let playerHeartbeat = "player_heartbeat"
    static let playerHitGrunt = "player_hit_grunt"
    static let playerBlock = "player_block"
    
    // MARK: - Enemy Sounds (positional, reverberant)
    static let enemyBreath = "enemy_breath"
    static let enemyTellInhale = "enemy_tell_inhale"
    static let enemyTellScrape = "enemy_tell_scrape"
    static let enemyStrikeWhoosh = "enemy_strike_whoosh"
    static let enemyHitGrunt = "enemy_hit_grunt"
    static let enemyFootstep = "enemy_footstep"
    static let enemyFootstepAlt = "enemy_footstep_alt"
    
    // MARK: - Impact Sounds
    static let impactHit = "impact_hit"
    static let impactBlock = "impact_block"
    
    // MARK: - Ambience & UI
    static let ambientRoomTone = "ambient_room_tone"
    static let roundStartTone = "round_start_tone"
    static let roundWin = "round_win"
    static let roundLose = "round_lose"
    
    // MARK: - Calibration
    static let calibrationLeft = "calibration_left"
    static let calibrationRight = "calibration_right"
    
    /// The file extension for all audio assets.
    static let fileExtension = "caf"
}

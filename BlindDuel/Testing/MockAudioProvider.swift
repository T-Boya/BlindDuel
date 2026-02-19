import Foundation

/// Mock audio provider for unit testing.
/// Records all calls so tests can assert which sounds were triggered.
final class MockAudioProvider: AudioProviding {
    
    // MARK: - Call Recording
    
    enum Call: Equatable {
        case start
        case stop
        case playEnemyTell(direction: Float)
        case playEnemyStrike(direction: Float)
        case playEnemyHit(direction: Float)
        case updateEnemyPosition(range: RangeState, direction: Float)
        case updateEnemyBreathing(hp: Int, destabilized: Bool)
        case playPlayerHit
        case playPlayerBlock
        case updatePlayerBreathing(hp: Int)
        case startEnemyFootsteps
        case stopEnemyFootsteps
        case updateEnemyFootsteps(range: RangeState, direction: Float, isApproaching: Bool)
        case startAmbience
        case stopAmbience
        case playRoundStart
        case playRoundEnd(won: Bool)
    }
    
    private(set) var calls: [Call] = []
    
    /// The most recent call.
    var lastCall: Call? { calls.last }
    
    /// Reset all recorded calls.
    func reset() { calls = [] }
    
    // MARK: - AudioProviding
    
    func start() throws { calls.append(.start) }
    func stop() { calls.append(.stop) }
    
    func playEnemyTell(from direction: Float) { calls.append(.playEnemyTell(direction: direction)) }
    func playEnemyStrike(from direction: Float) { calls.append(.playEnemyStrike(direction: direction)) }
    func playEnemyHit(from direction: Float) { calls.append(.playEnemyHit(direction: direction)) }
    func updateEnemyPosition(range: RangeState, direction: Float) { calls.append(.updateEnemyPosition(range: range, direction: direction)) }
    func updateEnemyBreathing(hp: Int, destabilized: Bool) { calls.append(.updateEnemyBreathing(hp: hp, destabilized: destabilized)) }
    
    func playPlayerHit() { calls.append(.playPlayerHit) }
    func playPlayerBlock() { calls.append(.playPlayerBlock) }
    func updatePlayerBreathing(hp: Int) { calls.append(.updatePlayerBreathing(hp: hp)) }
    
    func startAmbience() { calls.append(.startAmbience) }
    func stopAmbience() { calls.append(.stopAmbience) }
    func playRoundStart() { calls.append(.playRoundStart) }
    func playRoundEnd(won: Bool) { calls.append(.playRoundEnd(won: won)) }
    
    func startEnemyFootsteps() { calls.append(.startEnemyFootsteps) }
    func stopEnemyFootsteps() { calls.append(.stopEnemyFootsteps) }
    func updateEnemyFootsteps(range: RangeState, direction: Float, isApproaching: Bool) {
        calls.append(.updateEnemyFootsteps(range: range, direction: direction, isApproaching: isApproaching))
    }
}

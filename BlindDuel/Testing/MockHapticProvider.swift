import Foundation

/// Mock haptic provider for unit testing.
/// Records all calls so tests can assert which haptic events were triggered.
final class MockHapticProvider: HapticProviding {
    
    // MARK: - Call Recording
    
    enum Call: Equatable {
        case start
        case stop
        case playPlayerDamage
        case playPlayerBlock
        case playImpact(intensity: HapticIntensity)
        case startHeartbeat
        case stopHeartbeat
        case startProximityRumble(intensity: Float)
        case stopProximityRumble
        case playRoundResult(won: Bool)
    }
    
    private(set) var calls: [Call] = []
    var lastCall: Call? { calls.last }
    func reset() { calls = [] }
    
    // MARK: - HapticProviding
    
    var supportsHaptics: Bool = true
    
    func start() throws { calls.append(.start) }
    func stop() { calls.append(.stop) }
    
    func playPlayerDamage() { calls.append(.playPlayerDamage) }
    func playPlayerBlock() { calls.append(.playPlayerBlock) }
    func playImpact(intensity: HapticIntensity) { calls.append(.playImpact(intensity: intensity)) }
    
    func startHeartbeat() { calls.append(.startHeartbeat) }
    func stopHeartbeat() { calls.append(.stopHeartbeat) }
    func startProximityRumble(intensity: Float) { calls.append(.startProximityRumble(intensity: intensity)) }
    func stopProximityRumble() { calls.append(.stopProximityRumble) }
    
    func playRoundResult(won: Bool) { calls.append(.playRoundResult(won: won)) }
}

import Foundation

/// Mock game loop for deterministic unit testing.
/// Instead of a real timer, tests call `tick(deltaTime:)` manually.
final class MockGameLoop: GameLoopProviding {
    
    var updateHandler: ((TimeInterval) -> Void)?
    private(set) var isRunning = false
    
    func start() { isRunning = true }
    func pause() { isRunning = false }
    func resume() { isRunning = true }
    func stop() { isRunning = false }
    
    /// Manually advance the game loop by a given time interval.
    /// This makes tests fully deterministic — no real timers involved.
    func tick(deltaTime: TimeInterval) {
        guard isRunning else { return }
        updateHandler?(deltaTime)
    }
    
    /// Advance by multiple frames at a given fps.
    func tickFrames(_ count: Int, fps: Double = 60) {
        let dt = 1.0 / fps
        for _ in 0..<count {
            tick(deltaTime: dt)
        }
    }
}

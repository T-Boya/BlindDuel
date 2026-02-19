import Foundation

/// Abstraction for the game loop timer.
/// Concrete: CADisplayLink-based. Mock: manually tickable for deterministic tests.
protocol GameLoopProviding: AnyObject {
    
    /// Called every frame with the elapsed time since the last frame (in seconds).
    var updateHandler: ((TimeInterval) -> Void)? { get set }
    
    /// Start the loop.
    func start()
    
    /// Pause the loop (preserves state).
    func pause()
    
    /// Resume after a pause.
    func resume()
    
    /// Stop the loop entirely.
    func stop()
    
    /// Whether the loop is currently running.
    var isRunning: Bool { get }
}

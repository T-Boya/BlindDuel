import QuartzCore

/// Game loop backed by CADisplayLink.
/// Fires at the display refresh rate (typically 60fps).
/// Conforms to GameLoopProviding — can be replaced with a manual mock for testing.
final class DisplayLinkGameLoop: GameLoopProviding {
    
    // MARK: - GameLoopProviding
    
    var updateHandler: ((TimeInterval) -> Void)?
    
    private(set) var isRunning = false
    
    // MARK: - Private
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    
    /// Maximum delta time to prevent spiral-of-death after long pauses.
    private let maxDeltaTime: TimeInterval = 1.0 / 15.0 // Cap at ~66ms
    
    // MARK: - Lifecycle
    
    func start() {
        guard !isRunning else { return }
        
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        
        displayLink = link
        lastTimestamp = 0
        isRunning = true
    }
    
    func pause() {
        displayLink?.isPaused = true
    }
    
    func resume() {
        lastTimestamp = 0 // Reset to avoid huge delta after pause
        displayLink?.isPaused = false
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        lastTimestamp = 0
    }
    
    // MARK: - Tick
    
    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        
        var deltaTime = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        
        // Clamp to prevent physics explosion after a long pause
        deltaTime = min(deltaTime, maxDeltaTime)
        
        updateHandler?(deltaTime)
    }
    
    deinit {
        stop()
    }
}

import UIKit

/// Touch-based input provider (MVP default).
/// Maps full-screen gestures to combat actions:
/// - Tap → attack
/// - Long Press → guard (start/end)
/// - Swipe Left/Right → sidestep
final class TouchInputProvider: InputProviding {
    
    // MARK: - InputProviding
    
    weak var delegate: InputDelegate?
    
    let displayName = "Touch"
    
    var isAvailable: Bool { true }
    
    var requiresPermission: Bool { false }
    
    // MARK: - Private
    
    private weak var view: UIView?
    private var tapRecognizer: UITapGestureRecognizer?
    private var longPressRecognizer: UILongPressGestureRecognizer?
    private var swipeLeftRecognizer: UISwipeGestureRecognizer?
    private var swipeRightRecognizer: UISwipeGestureRecognizer?
    
    // MARK: - Lifecycle
    
    func activate(in view: UIView) {
        self.view = view
        
        // Tap → Attack
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        tapRecognizer = tap
        
        // Long Press → Guard
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.15 // Quick entry into guard
        view.addGestureRecognizer(longPress)
        longPressRecognizer = longPress
        
        // Tap should fail if long press is recognized
        tap.require(toFail: longPress)
        
        // Swipe Left → Sidestep
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        swipeLeftRecognizer = swipeLeft
        
        // Swipe Right → Sidestep
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        swipeRightRecognizer = swipeRight
    }
    
    func deactivate() {
        // Remove all recognizers cleanly
        if let tap = tapRecognizer { view?.removeGestureRecognizer(tap) }
        if let longPress = longPressRecognizer { view?.removeGestureRecognizer(longPress) }
        if let swipeLeft = swipeLeftRecognizer { view?.removeGestureRecognizer(swipeLeft) }
        if let swipeRight = swipeRightRecognizer { view?.removeGestureRecognizer(swipeRight) }
        
        tapRecognizer = nil
        longPressRecognizer = nil
        swipeLeftRecognizer = nil
        swipeRightRecognizer = nil
        view = nil
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        delegate?.inputProvider(self, didPerform: .attack)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.inputProvider(self, didPerform: .guardStart)
        case .ended, .cancelled:
            delegate?.inputProvider(self, didPerform: .guardEnd)
        default:
            break
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else { return }
        delegate?.inputProvider(self, didPerform: .sidestep)
    }
}

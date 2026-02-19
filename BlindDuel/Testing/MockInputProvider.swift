import UIKit

/// Mock input provider for unit testing.
/// Can programmatically fire actions to test combat engine responses.
final class MockInputProvider: InputProviding {
    
    weak var delegate: InputDelegate?
    
    let displayName = "Mock"
    var isAvailable: Bool = true
    var requiresPermission: Bool = false
    
    private(set) var isActivated = false
    
    func activate(in view: UIView) {
        isActivated = true
    }
    
    func deactivate() {
        isActivated = false
    }
    
    /// Simulate a player action (for testing).
    func simulateAction(_ action: CombatAction) {
        delegate?.inputProvider(self, didPerform: action)
    }
}

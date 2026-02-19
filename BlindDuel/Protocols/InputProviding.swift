import UIKit

/// Actions that any input provider can produce.
/// This is the shared vocabulary between input and combat.
/// The combat engine only knows about these — never about gesture types or sensors.
enum CombatAction: Equatable {
    case attack
    case guardStart
    case guardEnd
    case sidestep
}

/// Delegate that receives combat actions from an input provider.
protocol InputDelegate: AnyObject {
    func inputProvider(_ provider: InputProviding, didPerform action: CombatAction)
}

/// Abstraction for a control mode.
/// Each control mode (touch, head gestures, tilt, etc.) conforms to this protocol.
/// Adding a new input mode means writing one new conforming type — 
/// zero changes to the combat engine or existing providers.
protocol InputProviding: AnyObject {
    
    /// Delegate to receive combat actions.
    var delegate: InputDelegate? { get set }
    
    /// Human-readable name for display in settings ("Touch", "Head Gestures", etc.).
    var displayName: String { get }
    
    /// Whether this input mode is available on the current hardware.
    /// e.g., head gestures require TrueDepth camera.
    var isAvailable: Bool { get }
    
    /// Whether this input mode requires a system permission (camera, motion, etc.).
    var requiresPermission: Bool { get }
    
    /// Request the required permission. Calls completion with success/failure.
    /// Default implementation calls completion(true) for providers that don't need permission.
    func requestPermission(completion: @escaping (Bool) -> Void)
    
    /// Attach this provider to the given view and begin listening for input.
    /// - Parameter view: The view to attach gesture recognizers or overlays to.
    func activate(in view: UIView)
    
    /// Detach from the view and stop listening. Clean up all recognizers/sensors.
    func deactivate()
}

// MARK: - Default implementations

extension InputProviding {
    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

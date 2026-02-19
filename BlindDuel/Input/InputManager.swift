import UIKit

/// Manages input providers and routes combat actions to the engine.
/// This is the bridge between the extensible input layer and the combat system.
///
/// Responsibilities:
/// - Holds a registry of all available input providers
/// - Manages the active provider lifecycle (activate/deactivate)
/// - Forwards actions from the active provider to a single delegate
/// - Persists the user's preferred input mode
final class InputManager: InputDelegate {
    
    // MARK: - Properties
    
    /// All registered input providers (including unavailable ones).
    private(set) var registeredProviders: [InputProviding] = []
    
    /// Providers available on the current hardware.
    var availableProviders: [InputProviding] {
        registeredProviders.filter { $0.isAvailable }
    }
    
    /// The currently active input provider.
    private(set) var activeProvider: InputProviding?
    
    /// The view that input providers attach to.
    private weak var activeView: UIView?
    
    /// Delegate that receives forwarded combat actions (typically the CombatEngine coordinator).
    weak var delegate: InputDelegate?
    
    /// UserDefaults key for persisting the preferred provider.
    private let preferenceKey = "BlindDuel.preferredInputProvider"
    
    // MARK: - Registration
    
    /// Register an input provider. Call this during app setup.
    /// - Parameter provider: The provider to register.
    func register(_ provider: InputProviding) {
        registeredProviders.append(provider)
    }
    
    /// Register multiple providers at once.
    func register(_ providers: [InputProviding]) {
        registeredProviders.append(contentsOf: providers)
    }
    
    // MARK: - Provider Switching
    
    /// Switch to a specific provider by display name.
    /// Deactivates the current provider and activates the new one.
    /// - Parameters:
    ///   - provider: The provider to activate.
    ///   - view: The view to attach to.
    ///   - completion: Called with true if activation succeeded.
    func switchTo(_ provider: InputProviding, in view: UIView, completion: ((Bool) -> Void)? = nil) {
        // Deactivate current
        activeProvider?.deactivate()
        activeProvider?.delegate = nil
        
        // Check availability
        guard provider.isAvailable else {
            completion?(false)
            return
        }
        
        // Request permission if needed
        if provider.requiresPermission {
            provider.requestPermission { [weak self] granted in
                guard granted else {
                    completion?(false)
                    return
                }
                self?.activateProvider(provider, in: view)
                completion?(true)
            }
        } else {
            activateProvider(provider, in: view)
            completion?(true)
        }
    }
    
    /// Activate the preferred (or default) provider for the given view.
    /// Falls back to the first available provider if no preference is saved.
    func activatePreferred(in view: UIView) {
        activeView = view
        
        // Try to restore saved preference
        if let savedName = UserDefaults.standard.string(forKey: preferenceKey),
           let preferred = availableProviders.first(where: { $0.displayName == savedName }) {
            switchTo(preferred, in: view)
            return
        }
        
        // Fall back to first available
        if let first = availableProviders.first {
            switchTo(first, in: view)
        }
    }
    
    /// Deactivate the current provider (e.g., when leaving combat).
    func deactivateAll() {
        activeProvider?.deactivate()
        activeProvider?.delegate = nil
        activeProvider = nil
        activeView = nil
    }
    
    // MARK: - InputDelegate (forwarding)
    
    func inputProvider(_ provider: InputProviding, didPerform action: CombatAction) {
        delegate?.inputProvider(provider, didPerform: action)
    }
    
    // MARK: - Private
    
    private func activateProvider(_ provider: InputProviding, in view: UIView) {
        provider.delegate = self
        provider.activate(in: view)
        activeProvider = provider
        activeView = view
        
        // Persist preference
        UserDefaults.standard.set(provider.displayName, forKey: preferenceKey)
    }
}

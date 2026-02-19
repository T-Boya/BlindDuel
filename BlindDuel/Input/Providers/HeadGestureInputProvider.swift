import UIKit
import ARKit
import AVFoundation

/// Head gesture input provider for hands-free play.
/// Uses ARKit face tracking to detect head movements:
/// - Nod forward (pitch down) → attack
/// - Head tilt back and hold → guard (start/end)
/// - Head turn left/right (yaw) → sidestep
///
/// Requires TrueDepth camera (iPhone X and later).
/// Does NOT display any camera preview — the screen stays black.
final class HeadGestureInputProvider: NSObject, InputProviding, ARSessionDelegate {
    
    // MARK: - InputProviding
    
    weak var delegate: InputDelegate?
    
    let displayName = "Head Gestures"
    
    var isAvailable: Bool {
        ARFaceTrackingConfiguration.isSupported
    }
    
    var requiresPermission: Bool { true }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Private
    
    private let session = ARSession()
    private var isActive = false
    
    // Thresholds (radians)
    private let nodThreshold: Float = 0.25       // ~14° pitch down for attack
    private let tiltBackThreshold: Float = -0.20  // ~12° pitch up for guard
    private let yawThreshold: Float = 0.30        // ~17° turn for sidestep
    
    // State tracking to prevent repeated triggers
    private var isGuarding = false
    private var lastNodTime: TimeInterval = 0
    private var lastSidestepTime: TimeInterval = 0
    private let cooldown: TimeInterval = 0.4 // Minimum time between same actions
    
    // Baseline head orientation (captured at activation)
    private var baselinePitch: Float = 0
    private var baselineYaw: Float = 0
    private var hasBaseline = false
    private var baselineSamples: [simd_float3] = []
    private let baselineSampleCount = 30 // ~0.5s at 60fps
    
    // MARK: - Lifecycle
    
    func activate(in view: UIView) {
        guard isAvailable else { return }
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false // Save power — we don't need lighting
        
        session.delegate = self
        session.run(config)
        isActive = true
        hasBaseline = false
        baselineSamples = []
        isGuarding = false
    }
    
    func deactivate() {
        session.pause()
        isActive = false
        hasBaseline = false
        baselineSamples = []
        
        // Release guard if active
        if isGuarding {
            isGuarding = false
            delegate?.inputProvider(self, didPerform: .guardEnd)
        }
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isActive,
              let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            return
        }
        
        let transform = faceAnchor.transform
        let euler = eulerAngles(from: transform)
        let pitch = euler.x
        let yaw = euler.y
        
        // Collect baseline samples
        if !hasBaseline {
            baselineSamples.append(euler)
            if baselineSamples.count >= baselineSampleCount {
                baselinePitch = baselineSamples.map(\.x).reduce(0, +) / Float(baselineSamples.count)
                baselineYaw = baselineSamples.map(\.y).reduce(0, +) / Float(baselineSamples.count)
                hasBaseline = true
            }
            return
        }
        
        let relativePitch = pitch - baselinePitch
        let relativeYaw = yaw - baselineYaw
        let now = CACurrentMediaTime()
        
        // Guard: pitch up (head tilted back)
        if relativePitch < tiltBackThreshold {
            if !isGuarding {
                isGuarding = true
                delegate?.inputProvider(self, didPerform: .guardStart)
            }
        } else if isGuarding {
            isGuarding = false
            delegate?.inputProvider(self, didPerform: .guardEnd)
        }
        
        // Attack: pitch down (nod forward), only when not guarding
        if !isGuarding && relativePitch > nodThreshold && (now - lastNodTime) > cooldown {
            lastNodTime = now
            delegate?.inputProvider(self, didPerform: .attack)
        }
        
        // Sidestep: yaw turn, only when not guarding
        if !isGuarding && abs(relativeYaw) > yawThreshold && (now - lastSidestepTime) > cooldown {
            lastSidestepTime = now
            delegate?.inputProvider(self, didPerform: .sidestep)
        }
    }
    
    // MARK: - Math Helpers
    
    /// Extract Euler angles (pitch, yaw, roll) from a 4x4 transform matrix.
    private func eulerAngles(from transform: simd_float4x4) -> simd_float3 {
        let pitch = asin(-transform.columns.2.x)
        let yaw = atan2(transform.columns.2.y, transform.columns.2.z)
        let roll = atan2(transform.columns.1.x, transform.columns.0.x)
        return simd_float3(pitch, yaw, roll)
    }
}

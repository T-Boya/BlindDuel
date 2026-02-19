import Foundation

/// The distance between fighters.
/// Attacks only land at `.close`.
enum RangeState: Int, Comparable, CaseIterable {
    case far = 0
    case mid = 1
    case close = 2
    
    static func < (lhs: RangeState, rhs: RangeState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// Move one step closer.
    var closer: RangeState {
        switch self {
        case .far: return .mid
        case .mid: return .close
        case .close: return .close
        }
    }
    
    /// Move one step farther.
    var farther: RangeState {
        switch self {
        case .far: return .far
        case .mid: return .far
        case .close: return .mid
        }
    }
}

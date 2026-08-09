import SwiftUI

// MARK: - Haptics
// Thin wrapper over iOS 17 `.sensoryFeedback`. Views attach feedback that fires
// when a trigger value changes, so haptics stay declarative and tied to state
// rather than imperative generator calls scattered through view code.

enum Haptic {
    case impactLight
    case impactMedium
    case selection
    case success
    case warning

    var feedback: SensoryFeedback {
        switch self {
        case .impactLight: return .impact(weight: .light)
        case .impactMedium: return .impact(weight: .medium)
        case .selection: return .selection
        case .success: return .success
        case .warning: return .warning
        }
    }
}

extension View {
    /// Haptic feedback is disabled app-wide — this is now a no-op so existing
    /// `.haptic(...)` call sites keep compiling without emitting any feedback.
    func haptic<T: Equatable>(_ haptic: Haptic, trigger: T) -> some View {
        self
    }
}

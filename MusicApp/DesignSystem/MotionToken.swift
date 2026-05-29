import SwiftUI

// MARK: - MotionToken
// Named SwiftUI.Animation presets so motion is consistent and tunable in one
// place. Use `.resolved(reduceMotion:)` when an animation should collapse for
// users who enabled Reduce Motion.

enum MotionToken {

    /// Standard spring for most UI state changes (expand/collapse, layout).
    static let springStandard = Animation.spring(response: 0.45, dampingFraction: 0.85)
    /// Bouncier spring for playful, attention-drawing transitions.
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.65)
    /// Snappy spring for small immediate feedback (taps, toggles).
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    /// Plain ease for opacity/cross-fades.
    static let fade = Animation.easeInOut(duration: DesignToken.Animation.standard)
    /// Slow cross-fade used when the per-song color theme changes.
    static let colorShift = Animation.easeInOut(duration: 0.6)

    /// Collapse an animation to a quick fade (or none) under Reduce Motion.
    /// Movement/scale-based animations should route through this.
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeInOut(duration: DesignToken.Animation.fast) : animation
    }
}

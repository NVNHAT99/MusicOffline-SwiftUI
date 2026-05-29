import SwiftUI

// MARK: - AppColorTheme Environment
// Carries the active theme down the view tree. Defaults to `.default` so any
// screen that hasn't opted into dynamic color renders the existing look.
// Override on a subtree with `.appColorTheme(theme)`.

private struct AppColorThemeKey: EnvironmentKey {
    static let defaultValue: AppColorTheme = .default
}

extension EnvironmentValues {
    var appColorTheme: AppColorTheme {
        get { self[AppColorThemeKey.self] }
        set { self[AppColorThemeKey.self] = newValue }
    }
}

extension View {
    /// Inject a color theme for this subtree. Animates color transitions so a
    /// song change cross-fades rather than snapping.
    func appColorTheme(_ theme: AppColorTheme) -> some View {
        environment(\.appColorTheme, theme)
            .animation(MotionToken.colorShift, value: theme)
    }
}

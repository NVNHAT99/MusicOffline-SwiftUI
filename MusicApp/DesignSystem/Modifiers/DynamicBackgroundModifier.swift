import SwiftUI

// MARK: - DynamicBackground
// Renders the active `appColorTheme` as a full-bleed background: a vertical
// gradient from the theme's stops, plus a bottom-to-top dark scrim that keeps
// white text/controls legible over bright extracted colors. Falls back to a
// flat `surface` fill when the theme has fewer than 2 gradient stops (e.g. the
// `.default` theme), so unthemed screens look exactly as before.

struct DynamicBackgroundModifier: ViewModifier {
    @Environment(\.appColorTheme) private var theme

    func body(content: Content) -> some View {
        content.background(backgroundLayer.ignoresSafeArea())
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if theme.gradientStops.count >= 2 {
            ZStack {
                LinearGradient(
                    colors: theme.gradientStops,
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Scrim: darkens the lower half so foreground text keeps contrast
                // regardless of how bright the extracted artwork color is.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        } else {
            theme.surface
        }
    }
}

extension View {
    /// Paint the active color theme behind this view (gradient + legibility scrim).
    func dynamicBackground() -> some View {
        modifier(DynamicBackgroundModifier())
    }
}

#Preview("Dynamic") {
    let theme = AppColorTheme(
        surface: Color(hexString: "#3A2A6E"),
        accent: Color(hexString: "#FF6B6B"),
        gradientStops: [Color(hexString: "#6E4AC9"), Color(hexString: "#1C1C1E")]
    )
    return VStack {
        Text("Now Playing").font(.largeTitle.bold())
        Text("Artist Name").foregroundStyle(.white.opacity(0.7))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundStyle(.white)
    .dynamicBackground()
    .appColorTheme(theme)
}

#Preview("Default fallback") {
    Text("Default look")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white)
        .dynamicBackground()
}

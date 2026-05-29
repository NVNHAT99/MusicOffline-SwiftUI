import SwiftUI

// MARK: - PressScale
// A ButtonStyle that scales the label down while pressed and fires a light
// haptic on press. Honors Reduce Motion by skipping the scale (haptic stays).
// Use via `.buttonStyle(.pressScale)`.

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? scale : 1.0))
            .animation(MotionToken.springSnappy, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in
                pressed
            }
    }
}

extension ButtonStyle where Self == PressScaleButtonStyle {
    static var pressScale: PressScaleButtonStyle { PressScaleButtonStyle() }
    static func pressScale(scale: CGFloat) -> PressScaleButtonStyle {
        PressScaleButtonStyle(scale: scale)
    }
}

#Preview {
    VStack(spacing: 24) {
        Button("Press me") {}
            .padding()
            .background(Color.accentPrimary, in: Capsule())
            .buttonStyle(.pressScale)

        Button {
        } label: {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 54))
        }
        .buttonStyle(.pressScale(scale: 0.9))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundColor)
    .foregroundStyle(.white)
}

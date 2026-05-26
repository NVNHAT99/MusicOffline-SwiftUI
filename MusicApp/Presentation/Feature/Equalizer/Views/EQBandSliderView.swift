import SwiftUI

/// A single vertical EQ band: gain readout on top, vertical slider, frequency label below.
/// Slider is rotated -90° so the natural horizontal Slider becomes a vertical fader.
struct EQBandSliderView: View {

    let gain: Float
    let label: String
    let bypassed: Bool
    let onChange: (Float) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(gainText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(bypassed ? 0.3 : 0.7))
                .frame(width: 44)
                .monospacedDigit()

            Slider(value: binding, in: -12...12, step: 0.5)
                .rotationEffect(.degrees(-90))
                .frame(width: 180, height: 28)
                .frame(width: 28, height: 180)
                .tint(bypassed ? .gray : .cyan)
                .disabled(bypassed)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(bypassed ? 0.4 : 1.0))
                .frame(width: 44)
        }
    }

    private var binding: Binding<Double> {
        Binding(
            get: { Double(gain) },
            set: { onChange(Float($0)) }
        )
    }

    private var gainText: String {
        let g = gain
        if abs(g) < 0.1 { return "0 dB" }
        return String(format: "%+.0f dB", g)
    }
}

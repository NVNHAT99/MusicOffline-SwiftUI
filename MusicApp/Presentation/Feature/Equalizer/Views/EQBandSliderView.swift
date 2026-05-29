import SwiftUI

/// A single vertical EQ band: gain readout on top, vertical slider, frequency label below.
/// Slider is rotated -90° so the natural horizontal Slider becomes a vertical fader.
/// A selection haptic fires once when the gain crosses the 0 dB center detent.
struct EQBandSliderView: View {

    let gain: Float
    let label: String
    let bypassed: Bool
    let onChange: (Float) -> Void

    /// Tracks whether the previous value was above/below zero so we only fire
    /// the haptic on the crossing edge, not on every continuous tick.
    @State private var wasAboveZero: Bool? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(gainText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(bypassed ? .mutedText : .secondaryText)
                .frame(width: 44)
                .monospacedDigit()

            Slider(value: binding, in: -12...12, step: 0.5)
                .rotationEffect(.degrees(-90))
                .frame(width: 180, height: 28)
                .frame(width: 28, height: 180)
                .tint(bypassed ? Color.mutedText : Color.accentPrimary)
                .disabled(bypassed)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(bypassed ? .mutedText : .primaryText)
                .frame(width: 44)
        }
        // Fire haptic only when crossing the 0 dB detent, not on every tick.
        .sensoryFeedback(.selection, trigger: detentCrossing)
    }

    private var binding: Binding<Double> {
        Binding(
            get: { Double(gain) },
            set: { newVal in
                let crossedZero = (wasAboveZero != nil) && ((wasAboveZero! && newVal <= 0) || (!wasAboveZero! && newVal >= 0))
                if crossedZero {
                    // Update wasAboveZero so repeated identical drags don't re-fire.
                    wasAboveZero = newVal > 0
                }
                if wasAboveZero == nil { wasAboveZero = newVal > 0 }
                onChange(Float(newVal))
            }
        )
    }

    /// Changes value only at the zero-crossing edge — used as `.sensoryFeedback` trigger.
    private var detentCrossing: Bool {
        guard let above = wasAboveZero else { return false }
        return (above && gain <= 0) || (!above && gain >= 0)
    }

    private var gainText: String {
        let g = gain
        if abs(g) < 0.1 { return "0 dB" }
        return String(format: "%+.0f dB", g)
    }
}

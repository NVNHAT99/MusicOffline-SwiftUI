import SwiftUI

/// Speed / Pitch / Reverb controls. Rendered when `state.tab == .effects`.
/// All sliders write through the view model so persistence happens in
/// `AudioEffectsService` (one source of truth).
struct EffectsSectionView: View {

    @ObservedObject var viewModel: EqualizerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                speedRow
                pitchRow
                reverbBlock
                resetButton
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Speed

    private var speedRow: some View {
        EffectControlRow(
            icon: "speedometer",
            title: "Speed",
            value: String(format: "%.2fx", viewModel.state.speed)
        ) {
            Slider(value: speedBinding, in: 0.5...2.0, step: 0.05)
                .tint(Color.accentPrimary)
            HStack {
                Text("0.5x").foregroundColor(.mutedText)
                Spacer()
                Button("Reset") { viewModel.send(.setSpeed(1.0)) }
                    .font(.caption2)
                    .foregroundColor(.accentPrimary)
                Spacer()
                Text("2.0x").foregroundColor(.mutedText)
            }
            .font(.caption)
        }
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.state.speed) },
            set: { viewModel.send(.setSpeed(Float($0))) }
        )
    }

    // MARK: - Pitch

    private var pitchRow: some View {
        EffectControlRow(
            icon: "tuningfork",
            title: "Pitch",
            value: String(format: "%+.1f st", viewModel.state.pitchSemitones)
        ) {
            Slider(value: pitchBinding, in: -12...12, step: 0.5)
                .tint(Color.accentPrimary)
            HStack {
                Text("-12 st").foregroundColor(.mutedText)
                Spacer()
                Button("Reset") { viewModel.send(.setPitch(0)) }
                    .font(.caption2)
                    .foregroundColor(.accentPrimary)
                Spacer()
                Text("+12 st").foregroundColor(.mutedText)
            }
            .font(.caption)
        }
    }

    private var pitchBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.state.pitchSemitones) },
            set: { viewModel.send(.setPitch(Float($0))) }
        )
    }

    // MARK: - Reverb

    private var reverbBlock: some View {
        EffectControlRow(
            icon: "waveform.path.ecg",
            title: "Reverb",
            value: viewModel.state.reverbBypassed
                ? "Off"
                : "\(Int(viewModel.state.reverbWetDryMix))%"
        ) {
            Slider(value: reverbMixBinding, in: 0...100, step: 1)
                .tint(Color.accentPrimary)
            Menu {
                ForEach(ReverbPreset.allCases, id: \.self) { p in
                    Button { viewModel.send(.selectReverbPreset(p)) } label: {
                        if p == viewModel.state.reverbPreset {
                            Label(p.displayName, systemImage: "checkmark")
                        } else {
                            Text(p.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.state.reverbPreset.displayName)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.15)))
            }
        }
    }

    private var reverbMixBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.state.reverbWetDryMix) },
            set: { viewModel.send(.setReverbWetDryMix(Float($0))) }
        )
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            viewModel.send(.resetEffects)
        } label: {
            Label("Reset All Effects", systemImage: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.15)))
        }
        .buttonStyle(.pressScale)
    }
}

/// Generic labelled control row: icon + title on the left, value on the right,
/// content (slider + helpers) underneath.
private struct EffectControlRow<Content: View>: View {

    let icon: String
    let title: String
    let value: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.accentPrimary)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primaryText)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentPrimary)
                    .monospacedDigit()
            }
            content()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }
}

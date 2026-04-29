import SwiftUI

struct EqualizerView: View {

    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                VStack(spacing: 32) {
                    presetRow
                    slidersSection
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Preset chips

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EQPreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                    presetChip(preset)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func presetChip(_ preset: EQPreset) -> some View {
        let selected = viewModel.state.preset == preset
        return Button {
            viewModel.send(.selectPreset(preset))
        } label: {
            Text(preset.displayName)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.black : Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? Color.cyan : Color.white.opacity(0.15))
                )
        }
    }

    // MARK: - Sliders

    private var slidersSection: some View {
        HStack(alignment: .bottom, spacing: 32) {
            ForEach(0..<3) { index in
                bandSlider(index: index)
            }
        }
        .frame(height: 260)
    }

    private func bandSlider(index: Int) -> some View {
        let gain = Binding<Double>(
            get: { Double(viewModel.state.gains[index]) },
            set: { viewModel.send(.setBandGain(index: index, dB: Float($0))) }
        )
        return VStack(spacing: 12) {
            Text("\(Int(viewModel.state.gains[index])) dB")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 50)

            Slider(value: gain, in: -12...12, step: 0.5)
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 44)
                .frame(width: 44, height: 200)
                .tint(.cyan)

            Text(EqualizerState.bandNames[index])
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

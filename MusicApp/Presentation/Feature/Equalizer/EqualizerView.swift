import SwiftUI

struct EqualizerView: View {

    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                VStack(spacing: 16) {
                    tabPicker
                    if viewModel.state.tab == .eq {
                        VStack(spacing: 20) {
                            presetRow
                            slidersSection
                            actionRow
                        }
                    } else {
                        EffectsSectionView(viewModel: viewModel)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { viewModel.send(.toggleBypass) } label: {
                        Image(systemName: viewModel.state.isBypassed ? "power" : "power.circle.fill")
                            .foregroundStyle(viewModel.state.isBypassed ? .gray : .cyan)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: saveSheetBinding) {
            SavePresetSheetView(
                onSave: { viewModel.send(.saveCurrentAsPreset(name: $0)) },
                onCancel: { viewModel.send(.presentSaveSheet(false)) }
            )
        }
        .overlay(alignment: .bottom) {
            if let msg = viewModel.state.errorMessage {
                Text(msg)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .onTapGesture { viewModel.send(.dismissError) }
            }
        }
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        Picker("", selection: tabBinding) {
            ForEach(EqualizerTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var tabBinding: Binding<EqualizerTab> {
        Binding(
            get: { viewModel.state.tab },
            set: { viewModel.send(.selectTab($0)) }
        )
    }

    // MARK: - Preset chips (built-in + user)

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EQPreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                    presetChip(
                        title: preset.displayName,
                        selected: viewModel.state.preset == preset && !isUserPresetActive,
                        action: { viewModel.send(.selectPreset(preset)) }
                    )
                }
                ForEach(viewModel.state.userPresets) { p in
                    userPresetChip(p)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func presetChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.black : Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? Color.cyan : Color.white.opacity(0.15))
                )
        }
    }

    private func userPresetChip(_ preset: UserEQPreset) -> some View {
        Menu {
            Button {
                viewModel.send(.selectUserPreset(preset))
            } label: {
                Label("Apply", systemImage: "checkmark.circle")
            }
            Button(role: .destructive) {
                viewModel.send(.deleteUserPreset(id: preset.id))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                Text(preset.name)
                    .font(.system(size: 13))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.purple.opacity(0.6)))
        }
    }

    /// A user preset is "active" if state.gains match it AND preset == .custom.
    /// We don't track which user preset is active; selecting one flips preset to .custom.
    private var isUserPresetActive: Bool { viewModel.state.preset == .custom }

    // MARK: - 10-band sliders (horizontal scroll)

    private var slidersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0..<EQPreset.bandCount, id: \.self) { index in
                    EQBandSliderView(
                        gain: viewModel.state.gains[index],
                        label: EqualizerState.bandLabels[index],
                        bypassed: viewModel.state.isBypassed,
                        onChange: { viewModel.send(.setBandGain(index: index, dB: $0)) }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 270)
    }

    // MARK: - Reset / Save row

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.send(.resetGains)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
            }
            Button {
                viewModel.send(.presentSaveSheet(true))
            } label: {
                Label("Save…", systemImage: "square.and.arrow.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cyan))
            }
            Spacer()
        }
    }

    // MARK: - Bindings

    private var saveSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showSavePresetSheet },
            set: { if !$0 { viewModel.send(.presentSaveSheet(false)) } }
        )
    }
}

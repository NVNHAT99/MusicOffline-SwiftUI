import SwiftUI

struct AudioEditorView: View {

    @StateObject var viewModel: AudioEditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AudioEditorViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        waveformBlock
                        trimReadout
                        fadeBlock
                        normalizeBlock
                        formatNote
                        exportButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primaryText)
                }
            }
            .onAppear { viewModel.send(.onAppear) }
            .onChange(of: viewModel.state.exportedURL) { _, url in
                guard url != nil else { return }
                dismiss()
            }
            .overlay(alignment: .bottom) {
                if let msg = viewModel.state.errorMessage {
                    Text(msg)
                        .font(AppFont.callout())
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .onTapGesture { viewModel.send(.dismissError) }
                }
            }
        }
    }

    // MARK: - Waveform + trim

    private var waveformBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
            if viewModel.state.isLoadingWaveform {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.accentPrimary)
            } else {
                WaveformView(samples: viewModel.state.waveform, barColor: Color.accentPrimary)
                    .padding(.horizontal, 6)
                TrimHandlesView(
                    trimStart: viewModel.state.trimStart,
                    trimEnd: viewModel.state.trimEnd,
                    duration: viewModel.state.duration,
                    onStartChange: { viewModel.send(.setTrimStart($0)) },
                    onEndChange:   { viewModel.send(.setTrimEnd($0)) }
                )
                .padding(.horizontal, 6)
            }
        }
        .frame(height: 120)
    }

    private var trimReadout: some View {
        HStack {
            Text("Start: \(timeString(viewModel.state.trimStart))")
            Spacer()
            Text("Length: \(timeString(max(0, viewModel.state.trimEnd - viewModel.state.trimStart)))")
            Spacer()
            Text("End: \(timeString(viewModel.state.trimEnd))")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.secondaryText)
        .monospacedDigit()
    }

    // MARK: - Fade

    private var fadeBlock: some View {
        VStack(spacing: 12) {
            fadeRow(title: "Fade In",  value: viewModel.state.fadeIn,  onChange: { viewModel.send(.setFadeIn($0)) })
            fadeRow(title: "Fade Out", value: viewModel.state.fadeOut, onChange: { viewModel.send(.setFadeOut($0)) })
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private func fadeRow(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                Spacer()
                Text(String(format: "%.1fs", value))
                    .font(.system(size: 13))
                    .foregroundColor(.accentPrimary)
                    .monospacedDigit()
            }
            Slider(value: Binding(get: { value }, set: { onChange($0) }), in: 0...10, step: 0.1)
                .tint(Color.accentPrimary)
        }
    }

    // MARK: - Normalize

    private var normalizeBlock: some View {
        Toggle(isOn: Binding(
            get: { viewModel.state.normalize },
            set: { viewModel.send(.setNormalize($0)) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Normalize Loudness")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                Text("Peak-normalize so quiet tracks reach -0.4 dB headroom.")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
        }
        .tint(Color.accentPrimary)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private var formatNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundColor(.accentPrimary)
            Text("Exports as M4A (AAC) into your library. Source file stays unchanged.")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }

    // MARK: - Export button

    private var exportButton: some View {
        Button {
            viewModel.send(.startExport)
        } label: {
            HStack(spacing: 10) {
                if viewModel.state.isExporting {
                    ProgressView().progressViewStyle(.circular).tint(.black)
                    Text("Exporting \(Int(viewModel.state.exportProgress * 100))%")
                } else {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save as New Track")
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(viewModel.state.isExporting ? Color.mutedText : Color.accentPrimary))
        }
        .disabled(viewModel.state.isExporting || viewModel.state.isLoadingWaveform)
        .buttonStyle(.pressScale)
    }

    private func timeString(_ t: Double) -> String {
        let total = max(0, t)
        let mins = Int(total) / 60
        let secs = total - Double(mins * 60)
        return String(format: "%d:%05.2f", mins, secs)
    }
}

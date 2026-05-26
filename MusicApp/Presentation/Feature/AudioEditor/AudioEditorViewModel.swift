import AVFoundation
import SwiftUI

@MainActor
final class AudioEditorViewModel: ObservableObject {

    @Published var state: AudioEditorState

    private let reducer = AudioEditorStateReducer()
    private let scanWaveform: ScanWaveformUseCaseProtocol
    private let computeGain:  ComputeNormalizationGainUseCaseProtocol
    private let exportUseCase: ExportEditedAudioUseCaseProtocol
    private let addSong: AddSongUseCaseProtocol

    init(
        sourceURL: URL,
        originalTitle: String,
        scanWaveform: ScanWaveformUseCaseProtocol = ScanWaveformUseCase(),
        computeGain: ComputeNormalizationGainUseCaseProtocol = ComputeNormalizationGainUseCase(),
        exportUseCase: ExportEditedAudioUseCaseProtocol = ExportEditedAudioUseCase(),
        addSong: AddSongUseCaseProtocol = AddSongUseCase()
    ) {
        self.scanWaveform = scanWaveform
        self.computeGain = computeGain
        self.exportUseCase = exportUseCase
        self.addSong = addSong
        self.state = AudioEditorState(sourceURL: sourceURL, originalTitle: originalTitle)
    }

    func send(_ intent: AudioEditorIntent) {
        switch intent {
        case .onAppear:
            loadDurationAndWaveform()
        case .setTrimStart(let v): state = reducer.reduce(state, with: .setTrimStart(v))
        case .setTrimEnd(let v):   state = reducer.reduce(state, with: .setTrimEnd(v))
        case .setFadeIn(let v):    state = reducer.reduce(state, with: .setFadeIn(v))
        case .setFadeOut(let v):   state = reducer.reduce(state, with: .setFadeOut(v))
        case .setNormalize(let v):
            state = reducer.reduce(state, with: .setNormalize(v))
            if v && state.normalizeGain == 1.0 { computeNormalizationGain() }
        case .startExport:
            export()
        case .dismissError:
            state = reducer.reduce(state, with: .setErrorMessage(nil))
        }
    }

    // MARK: - Loading

    private func loadDurationAndWaveform() {
        let url = state.sourceURL
        // Quick duration via AVAudioFile (cheap — just header read).
        if let file = try? AVAudioFile(forReading: url) {
            let duration = Double(file.length) / file.processingFormat.sampleRate
            state = reducer.reduce(state, with: .setDuration(duration))
        }
        Task {
            do {
                let buckets = 240
                let wf = try await scanWaveform.execute(url: url, buckets: buckets)
                state = reducer.reduce(state, with: .setWaveform(wf))
                state = reducer.reduce(state, with: .setWaveformLoading(false))
            } catch {
                Logger.error("Waveform scan failed: \(error)")
                state = reducer.reduce(state, with: .setWaveformLoading(false))
            }
        }
    }

    private func computeNormalizationGain() {
        let url = state.sourceURL
        Task {
            if let g = try? await computeGain.execute(url: url) {
                state = reducer.reduce(state, with: .setNormalizeGain(g))
            }
        }
    }

    // MARK: - Export

    private func export() {
        guard !state.isExporting else { return }
        let config = AudioEditConfig(
            sourceURL: state.sourceURL,
            trimStart: state.trimStart,
            trimEnd: state.trimEnd,
            fadeIn: state.fadeIn,
            fadeOut: state.fadeOut,
            normalize: state.normalize,
            outputTitle: "\(state.originalTitle) (Edit)"
        )
        let gain = state.normalizeGain
        state = reducer.reduce(state, with: .setExporting(true))
        state = reducer.reduce(state, with: .setExportProgress(0))

        Task {
            do {
                let url = try await exportUseCase.execute(
                    config: config,
                    normalizeGain: gain,
                    onProgress: { [weak self] p in
                        guard let self else { return }
                        self.state = self.reducer.reduce(self.state, with: .setExportProgress(p))
                    }
                )
                try await addSong.execute(from: url.path)
                state = reducer.reduce(state, with: .setExportedURL(url))
                state = reducer.reduce(state, with: .setExporting(false))
            } catch {
                Logger.error("Export failed: \(error)")
                state = reducer.reduce(state, with: .setExporting(false))
                state = reducer.reduce(state, with: .setErrorMessage(error.localizedDescription))
            }
        }
    }
}

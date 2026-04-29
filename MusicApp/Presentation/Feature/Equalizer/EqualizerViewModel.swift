import Foundation

@MainActor
final class EqualizerViewModel: ObservableObject {

    @Published var state: EqualizerState

    private let reducer = EqualizerStateReducer()
    private let eqService: EQServiceProtocol

    init(eqService: EQServiceProtocol = EQService.shared) {
        self.eqService = eqService
        state = EqualizerState(
            preset: eqService.currentPreset,
            gains: eqService.currentGains
        )
    }

    func send(_ intent: EqualizerIntent) {
        switch intent {
        case .selectPreset(let preset):
            eqService.applyPreset(preset)
            state = reducer.reduce(state, with: .setPreset(preset))
            state = reducer.reduce(state, with: .setGains(eqService.currentGains))

        case .setBandGain(let index, let dB):
            eqService.setBandGain(index: index, dB: dB)
            state = reducer.reduce(state, with: .setBandGain(index: index, dB: dB))
        }
    }
}

import Foundation

@MainActor
final class EqualizerViewModel: ObservableObject {

    @Published var state: EqualizerState

    private let reducer = EqualizerStateReducer()
    private let eqService: EQServiceProtocol
    private let effectsService: AudioEffectsServiceProtocol
    private let saveUseCase: SaveUserEQPresetUseCaseProtocol
    private let loadUseCase: LoadUserEQPresetsUseCaseProtocol
    private let deleteUseCase: DeleteUserEQPresetUseCaseProtocol

    init(
        eqService: EQServiceProtocol = EQService.shared,
        effectsService: AudioEffectsServiceProtocol = AudioEffectsService.shared,
        saveUseCase: SaveUserEQPresetUseCaseProtocol = SaveUserEQPresetUseCase(),
        loadUseCase: LoadUserEQPresetsUseCaseProtocol = LoadUserEQPresetsUseCase(),
        deleteUseCase: DeleteUserEQPresetUseCaseProtocol = DeleteUserEQPresetUseCase()
    ) {
        self.eqService = eqService
        self.effectsService = effectsService
        self.saveUseCase = saveUseCase
        self.loadUseCase = loadUseCase
        self.deleteUseCase = deleteUseCase
        state = EqualizerState(
            preset: eqService.currentPreset,
            gains: eqService.currentGains,
            userPresets: loadUseCase.execute(),
            isBypassed: eqService.isBypassed,
            speed: effectsService.speed,
            pitchSemitones: effectsService.pitchSemitones,
            reverbPreset: effectsService.reverbPreset,
            reverbWetDryMix: effectsService.reverbWetDryMix,
            reverbBypassed: effectsService.reverbBypassed
        )
    }

    func send(_ intent: EqualizerIntent) {
        switch intent {
        case .selectTab(let tab):
            state = reducer.reduce(state, with: .setTab(tab))

        case .selectPreset(let preset):
            eqService.applyPreset(preset)
            state = reducer.reduce(state, with: .setPreset(preset))
            state = reducer.reduce(state, with: .setGains(eqService.currentGains))

        case .selectUserPreset(let userPreset):
            eqService.applyCustomGains(userPreset.gains)
            state = reducer.reduce(state, with: .setGains(userPreset.gains))
            state = reducer.reduce(state, with: .setPreset(.custom))

        case .setBandGain(let index, let dB):
            eqService.setBandGain(index: index, dB: dB)
            state = reducer.reduce(state, with: .setBandGain(index: index, dB: dB))

        case .resetGains:
            eqService.applyPreset(.flat)
            state = reducer.reduce(state, with: .setPreset(.flat))
            state = reducer.reduce(state, with: .setGains(EQPreset.flat.gains))

        case .toggleBypass:
            let newValue = !state.isBypassed
            eqService.setBypass(newValue)
            state = reducer.reduce(state, with: .setBypassed(newValue))

        case .presentSaveSheet(let show):
            state = reducer.reduce(state, with: .setShowSaveSheet(show))

        case .saveCurrentAsPreset(let name):
            do {
                _ = try saveUseCase.execute(name: name, gains: state.gains)
                state = reducer.reduce(state, with: .setUserPresets(loadUseCase.execute()))
                state = reducer.reduce(state, with: .setShowSaveSheet(false))
            } catch {
                state = reducer.reduce(state, with: .setErrorMessage(error.localizedDescription))
            }

        case .deleteUserPreset(let id):
            deleteUseCase.execute(id: id)
            state = reducer.reduce(state, with: .setUserPresets(loadUseCase.execute()))

        case .dismissError:
            state = reducer.reduce(state, with: .setErrorMessage(nil))

        case .setSpeed(let v):
            effectsService.setSpeed(v)
            state = reducer.reduce(state, with: .setSpeed(effectsService.speed))

        case .setPitch(let v):
            effectsService.setPitch(semitones: v)
            state = reducer.reduce(state, with: .setPitch(effectsService.pitchSemitones))

        case .selectReverbPreset(let p):
            effectsService.setReverbPreset(p)
            state = reducer.reduce(state, with: .setReverbPreset(p))

        case .setReverbWetDryMix(let m):
            effectsService.setReverbWetDryMix(m)
            state = reducer.reduce(state, with: .setReverbWetDryMix(effectsService.reverbWetDryMix))
            state = reducer.reduce(state, with: .setReverbBypassed(effectsService.reverbBypassed))

        case .resetEffects:
            effectsService.resetAll()
            state = reducer.reduce(state, with: .setSpeed(effectsService.speed))
            state = reducer.reduce(state, with: .setPitch(effectsService.pitchSemitones))
            state = reducer.reduce(state, with: .setReverbWetDryMix(effectsService.reverbWetDryMix))
            state = reducer.reduce(state, with: .setReverbBypassed(effectsService.reverbBypassed))
        }
    }
}

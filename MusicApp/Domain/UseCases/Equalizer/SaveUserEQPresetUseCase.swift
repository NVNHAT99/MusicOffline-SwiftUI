import Foundation

protocol SaveUserEQPresetUseCaseProtocol {
    @discardableResult
    func execute(name: String, gains: [Float]) throws -> UserEQPreset
}

final class SaveUserEQPresetUseCase: SaveUserEQPresetUseCaseProtocol {

    private let repository: UserEQPresetRepositoryProtocol

    init(repository: UserEQPresetRepositoryProtocol = UserEQPresetRepository()) {
        self.repository = repository
    }

    @discardableResult
    func execute(name: String, gains: [Float]) throws -> UserEQPreset {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw UserEQPresetError.emptyName
        }
        guard gains.count == EQPreset.bandCount else {
            throw UserEQPresetError.invalidGains
        }
        let preset = UserEQPreset(name: trimmed, gains: gains)
        repository.save(preset)
        return preset
    }
}

enum UserEQPresetError: LocalizedError {
    case emptyName
    case invalidGains

    var errorDescription: String? {
        switch self {
        case .emptyName:    return "Preset name cannot be empty"
        case .invalidGains: return "EQ preset must have exactly 10 bands"
        }
    }
}

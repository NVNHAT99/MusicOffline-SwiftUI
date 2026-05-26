import Foundation

protocol LoadUserEQPresetsUseCaseProtocol {
    func execute() -> [UserEQPreset]
}

final class LoadUserEQPresetsUseCase: LoadUserEQPresetsUseCaseProtocol {

    private let repository: UserEQPresetRepositoryProtocol

    init(repository: UserEQPresetRepositoryProtocol = UserEQPresetRepository()) {
        self.repository = repository
    }

    func execute() -> [UserEQPreset] {
        repository.loadAll().sorted { $0.createdAt < $1.createdAt }
    }
}

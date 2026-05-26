import Foundation

protocol DeleteUserEQPresetUseCaseProtocol {
    func execute(id: UUID)
}

final class DeleteUserEQPresetUseCase: DeleteUserEQPresetUseCaseProtocol {

    private let repository: UserEQPresetRepositoryProtocol

    init(repository: UserEQPresetRepositoryProtocol = UserEQPresetRepository()) {
        self.repository = repository
    }

    func execute(id: UUID) {
        repository.delete(id: id)
    }
}

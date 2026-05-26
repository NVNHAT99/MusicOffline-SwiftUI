import Foundation

protocol RemoveLyricsUseCaseProtocol {
    func execute(stem: String)
}

final class RemoveLyricsUseCase: RemoveLyricsUseCaseProtocol {

    private let repository: LyricsRepositoryProtocol

    init(repository: LyricsRepositoryProtocol = LyricsRepository()) {
        self.repository = repository
    }

    func execute(stem: String) {
        repository.delete(stem: stem)
    }
}

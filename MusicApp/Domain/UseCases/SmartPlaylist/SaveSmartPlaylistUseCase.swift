import Foundation

protocol SaveSmartPlaylistUseCaseProtocol {
    func execute(_ playlist: SmartPlaylist) throws
    func delete(id: UUID) throws
    func fetchAll() throws -> [SmartPlaylist]
}

final class SaveSmartPlaylistUseCase: SaveSmartPlaylistUseCaseProtocol {

    private let repository: SmartPlaylistRepositoryProtocol

    init(repository: SmartPlaylistRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ playlist: SmartPlaylist) throws {
        try repository.save(playlist)
    }

    func delete(id: UUID) throws {
        try repository.delete(id: id)
    }

    func fetchAll() throws -> [SmartPlaylist] {
        try repository.fetchAll()
    }
}

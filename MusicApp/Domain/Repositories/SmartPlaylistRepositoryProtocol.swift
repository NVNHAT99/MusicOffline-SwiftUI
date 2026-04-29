import Foundation

protocol SmartPlaylistRepositoryProtocol {
    func fetchAll() throws -> [SmartPlaylist]
    func save(_ playlist: SmartPlaylist) throws
    func delete(id: UUID) throws
}

import Foundation

protocol LyricsRepositoryProtocol {
    func save(stem: String, content: String) throws
    func load(stem: String) -> String?
    func delete(stem: String)
}

import Foundation

protocol FetchLyricsUseCaseProtocol {
    func execute(stem: String) -> [LyricsLine]
}

final class FetchLyricsUseCase: FetchLyricsUseCaseProtocol {

    private let repository: LyricsRepositoryProtocol
    private let parser: ParseLrcContentUseCase

    init(repository: LyricsRepositoryProtocol, parser: ParseLrcContentUseCase = ParseLrcContentUseCase()) {
        self.repository = repository
        self.parser = parser
    }

    func execute(stem: String) -> [LyricsLine] {
        guard let content = repository.load(stem: stem) else { return [] }
        return parser.execute(content: content)
    }
}

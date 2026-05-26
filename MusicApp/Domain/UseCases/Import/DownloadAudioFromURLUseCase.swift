import Foundation
import Combine

protocol DownloadAudioFromURLUseCaseProtocol {
    func execute(rawURL: String) -> AnyPublisher<DownloadEvent, Never>
    func cancel()
}

final class DownloadAudioFromURLUseCase: DownloadAudioFromURLUseCaseProtocol {

    private let service: BackgroundDownloadServiceProtocol
    private let addSong: AddSongUseCaseProtocol
    private var cancellable: AnyCancellable?

    init(
        service: BackgroundDownloadServiceProtocol = BackgroundDownloadService.shared,
        addSong: AddSongUseCaseProtocol = AddSongUseCase()
    ) {
        self.service = service
        self.addSong = addSong
    }

    func execute(rawURL: String) -> AnyPublisher<DownloadEvent, Never> {
        guard let url = sanitizedHTTPSURL(from: rawURL) else {
            return Just(.failed(DownloadError.invalidURL)).eraseToAnyPublisher()
        }
        let filename = inferFilename(from: url)
        let publisher = service.download(from: url, suggestedFilename: filename)
        // Tap completed → ingest into library. We forward events unchanged.
        let subject = PassthroughSubject<DownloadEvent, Never>()
        cancellable = publisher.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .completed(let url):
                Task {
                    try? await self.addSong.execute(from: url.path)
                    subject.send(.completed(url))
                }
            default:
                subject.send(event)
            }
        }
        return subject.eraseToAnyPublisher()
    }

    func cancel() {
        service.cancelCurrent()
    }

    // MARK: - Helpers

    private func sanitizedHTTPSURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",
              url.host?.isEmpty == false else { return nil }
        return url
    }

    private func inferFilename(from url: URL) -> String {
        let last = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        if last.isEmpty || last == "/" { return "download.mp3" }
        return last.contains(".") ? last : "\(last).mp3"
    }
}

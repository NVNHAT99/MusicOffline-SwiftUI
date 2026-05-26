import Combine
import SwiftUI

@MainActor
final class UrlDownloadViewModel: ObservableObject {

    @Published var state = UrlDownloadState()

    private let reducer = UrlDownloadStateReducer()
    private let useCase: DownloadAudioFromURLUseCaseProtocol
    private var cancellable: AnyCancellable?

    init(useCase: DownloadAudioFromURLUseCaseProtocol = DownloadAudioFromURLUseCase()) {
        self.useCase = useCase
    }

    func send(_ intent: UrlDownloadIntent) {
        switch intent {
        case .setURL(let v):
            state = reducer.reduce(state, with: .setURL(v))
        case .start:
            startDownload()
        case .cancel:
            useCase.cancel()
            state = reducer.reduce(state, with: .setDownloading(false))
        case .dismissError:
            state = reducer.reduce(state, with: .setError(nil))
        case .clear:
            state = reducer.reduce(state, with: .reset)
        }
    }

    private func startDownload() {
        guard state.canStart else { return }
        state = reducer.reduce(state, with: .setDownloading(true))
        state = reducer.reduce(state, with: .setProgress(0))
        state = reducer.reduce(state, with: .setError(nil))
        cancellable = useCase.execute(rawURL: state.urlText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .progress(let p):
                    self.state = self.reducer.reduce(self.state, with: .setProgress(p))
                case .completed(let url):
                    self.state = self.reducer.reduce(self.state, with: .setDownloading(false))
                    self.state = self.reducer.reduce(self.state, with: .setCompleted(url.lastPathComponent))
                case .failed(let error):
                    self.state = self.reducer.reduce(self.state, with: .setDownloading(false))
                    self.state = self.reducer.reduce(self.state, with: .setError(error.localizedDescription))
                }
            }
    }
}

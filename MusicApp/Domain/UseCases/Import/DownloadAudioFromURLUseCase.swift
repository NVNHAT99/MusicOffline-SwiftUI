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
                Task { [weak self] in
                    guard let self else { return }
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
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              !isPrivateOrReservedHost(host),
              let url = components.url else { return nil }
        return url
    }

    /// Reject loopback / private / link-local / `.local` hosts so a pasted URL
    /// cannot turn this user-initiated download into an SSRF into the LAN or
    /// device-local services. HTTPS-only is enforced separately.
    private func isPrivateOrReservedHost(_ host: String) -> Bool {
        let lower = host.lowercased()
        if lower == "localhost" || lower.hasSuffix(".local") { return true }

        // Strip IPv6 brackets if present.
        let bare = lower.hasPrefix("[") && lower.hasSuffix("]")
            ? String(lower.dropFirst().dropLast())
            : lower

        // IPv6 loopback / unique-local (fc00::/7) / link-local (fe80::/10).
        if bare.contains(":") {
            if bare == "::1" { return true }
            if bare.hasPrefix("fc") || bare.hasPrefix("fd") { return true }
            if bare.hasPrefix("fe8") || bare.hasPrefix("fe9") ||
               bare.hasPrefix("fea") || bare.hasPrefix("feb") { return true }
            return false
        }

        // IPv4 ranges: 127/8, 10/8, 172.16/12, 192.168/16, 169.254/16, 0.0.0.0.
        let parts = bare.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4, parts.allSatisfy({ (0...255).contains($0) }) else {
            return false // a normal domain name
        }
        switch (parts[0], parts[1]) {
        case (0, _), (127, _), (10, _), (169, 254): return true
        case (172, 16...31): return true
        case (192, 168): return true
        default: return false
        }
    }

    private func inferFilename(from url: URL) -> String {
        let last = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        let candidate: String
        if last.isEmpty || last == "/" {
            candidate = "download.mp3"
        } else {
            candidate = last.contains(".") ? last : "\(last).mp3"
        }
        return BackgroundDownloadService.sanitizedFilename(candidate)
    }
}

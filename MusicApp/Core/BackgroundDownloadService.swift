import Foundation
import Combine

/// Wraps a foreground `URLSession.downloadTask` with progress + completion as
/// Combine events. (Background URLSession would let downloads continue while
/// the app is suspended, but it requires app delegate callbacks — we keep this
/// foreground-only for v1 to avoid touching the app delegate adapter.)
enum DownloadEvent {
    case progress(Double)        // 0…1
    case completed(URL)          // final destination URL in Documents/Music
    case failed(Error)
}

protocol BackgroundDownloadServiceProtocol: AnyObject {
    func download(from url: URL, suggestedFilename: String) -> AnyPublisher<DownloadEvent, Never>
    func cancelCurrent()
}

final class BackgroundDownloadService: NSObject, BackgroundDownloadServiceProtocol, URLSessionDownloadDelegate {

    static let shared = BackgroundDownloadService()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var currentTask: URLSessionDownloadTask?
    private var currentSubject: PassthroughSubject<DownloadEvent, Never>?
    private var currentSuggestedName: String = "download.mp3"

    private static let maxBytes: Int64 = 200 * 1024 * 1024 // 200 MB

    func download(from url: URL, suggestedFilename: String) -> AnyPublisher<DownloadEvent, Never> {
        cancelCurrent()
        let subject = PassthroughSubject<DownloadEvent, Never>()
        currentSubject = subject
        currentSuggestedName = suggestedFilename
        let task = session.downloadTask(with: url)
        currentTask = task
        task.resume()
        return subject.eraseToAnyPublisher()
    }

    func cancelCurrent() {
        currentTask?.cancel()
        currentTask = nil
        currentSubject = nil
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > Self.maxBytes {
            downloadTask.cancel()
            currentSubject?.send(.failed(DownloadError.fileTooLarge))
            return
        }
        guard totalBytesExpectedToWrite > 0 else { return }
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        currentSubject?.send(.progress(p))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        do {
            // Validate content-type if available; otherwise rely on URL extension.
            let response = downloadTask.response as? HTTPURLResponse
            if let mime = response?.mimeType?.lowercased() {
                if !mime.hasPrefix("audio/") && !Self.acceptableExtensions.contains((currentSuggestedName as NSString).pathExtension.lowercased()) {
                    throw DownloadError.notAudio
                }
            }
            let dest = try Self.uniqueDestinationURL(for: currentSuggestedName)
            try FileManager.default.moveItem(at: location, to: dest)
            currentSubject?.send(.completed(dest))
        } catch {
            currentSubject?.send(.failed(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let e = error as NSError?, e.code != NSURLErrorCancelled {
            currentSubject?.send(.failed(e))
        }
        currentTask = nil
    }

    // MARK: - Helpers

    private static let acceptableExtensions: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]

    private static func uniqueDestinationURL(for name: String) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Music", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension.isEmpty ? "mp3" : (name as NSString).pathExtension
        var candidate = dir.appendingPathComponent("\(base).\(ext)")
        var i = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base) (\(i)).\(ext)")
            i += 1
        }
        return candidate
    }
}

enum DownloadError: LocalizedError {
    case fileTooLarge
    case notAudio
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: return "File is larger than 200 MB"
        case .notAudio:     return "URL did not return an audio file"
        case .invalidURL:   return "Invalid URL"
        }
    }
}

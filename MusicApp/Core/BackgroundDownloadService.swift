import Foundation
import Combine
import AVFoundation

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

    /// Serial queue that backs the URLSession delegate callbacks AND guards the
    /// mutable `current*` state below, so they are never touched concurrently.
    private let stateQueue = DispatchQueue(label: "com.musicapp.download.state")
    private let delegateOpQueue: OperationQueue

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: delegateOpQueue)
    }()

    // Confined to `stateQueue`.
    private var currentTask: URLSessionDownloadTask?
    private var currentSubject: PassthroughSubject<DownloadEvent, Never>?
    private var currentSuggestedName: String = "download.mp3"

    private static let maxBytes: Int64 = 200 * 1024 * 1024 // 200 MB

    private override init() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.musicapp.download.delegate"
        self.delegateOpQueue = queue
        super.init()
    }

    func download(from url: URL, suggestedFilename: String) -> AnyPublisher<DownloadEvent, Never> {
        cancelCurrent()
        let subject = PassthroughSubject<DownloadEvent, Never>()
        let task = session.downloadTask(with: url)
        stateQueue.sync {
            currentSubject = subject
            currentSuggestedName = suggestedFilename
            currentTask = task
        }
        task.resume()
        return subject.eraseToAnyPublisher()
    }

    func cancelCurrent() {
        let task: URLSessionDownloadTask? = stateQueue.sync {
            let t = currentTask
            currentTask = nil
            currentSubject = nil
            return t
        }
        task?.cancel()
    }

    // MARK: - URLSessionDownloadDelegate (runs on `delegateOpQueue`)

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let subject: PassthroughSubject<DownloadEvent, Never>? = stateQueue.sync {
            downloadTask === currentTask ? currentSubject : nil
        }
        guard let subject else { return } // late callback from a cancelled task
        if totalBytesExpectedToWrite > Self.maxBytes {
            downloadTask.cancel()
            subject.send(.failed(DownloadError.fileTooLarge))
            return
        }
        guard totalBytesExpectedToWrite > 0 else { return }
        subject.send(.progress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Snapshot state under the queue and ignore stale completions.
        let snapshot: (subject: PassthroughSubject<DownloadEvent, Never>, name: String)? = stateQueue.sync {
            guard downloadTask === currentTask, let s = currentSubject else { return nil }
            return (s, currentSuggestedName)
        }
        guard let snapshot else { return }

        do {
            // nil MIME must be sniffed; only a confirmed non-audio MIME is rejected up front.
            if let mime = (downloadTask.response as? HTTPURLResponse)?.mimeType?.lowercased(),
               !mime.hasPrefix("audio/"), !mime.hasPrefix("application/octet-stream") {
                throw DownloadError.notAudio
            }
            let dest = try Self.uniqueDestinationURL(for: snapshot.name)
            try FileManager.default.moveItem(at: location, to: dest)

            // Content sniff: a real, decodable audio file must open. Otherwise
            // delete the file we just wrote so a renamed HTML page / binary blob
            // never lands in the library.
            guard Self.isDecodableAudio(at: dest) else {
                try? FileManager.default.removeItem(at: dest)
                throw DownloadError.notAudio
            }
            snapshot.subject.send(.completed(dest))
        } catch {
            snapshot.subject.send(.failed(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let subject: PassthroughSubject<DownloadEvent, Never>? = stateQueue.sync {
            guard task === currentTask else { return nil }
            currentTask = nil
            let s = currentSubject
            return s
        }
        guard let subject else { return }
        if let e = error as NSError?, e.code != NSURLErrorCancelled {
            subject.send(.failed(e))
        }
    }

    // MARK: - Helpers

    private static func isDecodableAudio(at url: URL) -> Bool {
        // A renamed HTML page / binary blob will not open as a real audio file.
        (try? AVAudioFile(forReading: url)) != nil
    }

    /// Strip path separators / traversal, whitelist charset, clamp length.
    static func sanitizedFilename(_ raw: String) -> String {
        let lastComponent = (raw as NSString).lastPathComponent
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._- ")
        var cleaned = String(lastComponent.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
        cleaned = cleaned.replacingOccurrences(of: "..", with: "_")
        while cleaned.hasPrefix(".") { cleaned.removeFirst() }
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        if cleaned.count > 120 { cleaned = String(cleaned.prefix(120)) }
        return cleaned.isEmpty ? "download.mp3" : cleaned
    }

    private static func uniqueDestinationURL(for name: String) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Music", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = sanitizedFilename(name)
        let base = (safe as NSString).deletingPathExtension
        let rawExt = (safe as NSString).pathExtension.lowercased()
        let ext = acceptableExtensions.contains(rawExt) ? rawExt : "mp3"
        let safeBase = base.isEmpty ? "download" : base
        var candidate = dir.appendingPathComponent("\(safeBase).\(ext)")
        var i = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(safeBase) (\(i)).\(ext)")
            i += 1
        }
        return candidate
    }

    private static let acceptableExtensions: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
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

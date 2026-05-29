import Foundation

struct UrlDownloadState {
    var urlText: String = ""
    var isDownloading: Bool = false
    var progress: Double = 0
    var completedFilename: String? = nil
    var errorMessage: String? = nil

    var canStart: Bool {
        guard !isDownloading else { return false }
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty else { return false }
        return true
    }
}

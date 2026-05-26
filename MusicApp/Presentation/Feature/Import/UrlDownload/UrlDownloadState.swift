import Foundation

struct UrlDownloadState {
    var urlText: String = ""
    var isDownloading: Bool = false
    var progress: Double = 0
    var completedFilename: String? = nil
    var errorMessage: String? = nil

    var canStart: Bool {
        !isDownloading &&
        urlText.lowercased().hasPrefix("https://") &&
        urlText.count > 10
    }
}

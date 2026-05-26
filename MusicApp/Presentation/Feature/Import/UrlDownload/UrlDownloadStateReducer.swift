import Foundation

final class UrlDownloadStateReducer {
    func reduce(_ state: UrlDownloadState, with action: UrlDownloadStateAction) -> UrlDownloadState {
        var s = state
        switch action {
        case .setURL(let v):         s.urlText = v
        case .setDownloading(let v): s.isDownloading = v
        case .setProgress(let v):    s.progress = v
        case .setCompleted(let v):   s.completedFilename = v
        case .setError(let v):       s.errorMessage = v
        case .reset:
            s = UrlDownloadState()
        }
        return s
    }
}

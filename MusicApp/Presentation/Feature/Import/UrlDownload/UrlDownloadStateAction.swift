import Foundation

enum UrlDownloadStateAction {
    case setURL(String)
    case setDownloading(Bool)
    case setProgress(Double)
    case setCompleted(String?)
    case setError(String?)
    case reset
}

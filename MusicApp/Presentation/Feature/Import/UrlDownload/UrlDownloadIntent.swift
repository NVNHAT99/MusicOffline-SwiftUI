import Foundation

enum UrlDownloadIntent {
    case setURL(String)
    case start
    case cancel
    case dismissError
    case clear
}

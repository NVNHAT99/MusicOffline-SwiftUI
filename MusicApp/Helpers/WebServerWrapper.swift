//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import Foundation
import GCDWebServer
import Combine

enum WebLoaderError: Error {
    case startFailed
    case stopFailed
}

enum WebLoaderResult {
    case startSuccess(ipAddress: String)
    case stopSucesss
}
class WebServerWrapper: NSObject, ObservableObject {
    static let shared: WebServerWrapper = WebServerWrapper()
    private var webUploader: GCDWebUploader?
    let webLoaderResult = PassthroughSubject<Result<WebLoaderResult, WebLoaderError>, Never>()
    
    private override init() {
        super.init()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        webUploader = GCDWebUploader(uploadDirectory: documentsPath)
        webUploader?.delegate = self // Set the delegate
    }
    
    func startWebUploader() {
        guard let webUploader = webUploader else {
            return
        }
        if !webUploader.isRunning {
            let options: Dictionary<String, Any> = ["Port" : 8080, "AutomaticallySuspendInBackground" : false]
            do {
                try webUploader.start(options: options)
            } catch  {
                print(error)
            }
            webUploader.allowedFileExtensions = ["mp3", "aac", "m4a", "wav"]
            if let serverURL = webUploader.serverURL {
                
                let str = serverURL.absoluteString
                let start = str.index(str.startIndex, offsetBy: 7)
                let end = str.index(str.endIndex, offsetBy: -1)
                let range = start..<end
                let ipAddressStr = str[range]
                webLoaderResult.send(.success(.startSuccess(ipAddress: String(ipAddressStr))))
            } else {
                webLoaderResult.send(.failure(.startFailed))
            }
        }
    }
    
    func stopWebUploader() {
        guard let webUploader = webUploader else {
            webLoaderResult.send(.failure(.stopFailed))
            return
        }
                    
        if webUploader.isRunning {
            webUploader.stop()
            webLoaderResult.send(.success(.stopSucesss))
        }
    }
}

extension WebServerWrapper: GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        print("File uploaded at path: \(path)")
        let isMP3File = (path as NSString).pathExtension.lowercased() == "mp3"
        
        if !isMP3File {
            // Delete the uploaded file if it is not an MP3
            do {
                try FileManager.default.removeItem(atPath: path)
                print("Non-MP3 file deleted")
            } catch {
                print("Failed to delete non-MP3 file: \(error)")
            }
        }
    }
}

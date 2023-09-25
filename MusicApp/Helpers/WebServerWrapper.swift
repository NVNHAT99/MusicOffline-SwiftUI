//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import Foundation
import GCDWebServer

class WebServerWrapper: NSObject, ObservableObject {
    static let shared: WebServerWrapper = WebServerWrapper()
    @Published var ipAddress: String = ""
    private var webUploader: GCDWebUploader?
    
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
            webUploader.start()
            webUploader.allowedFileExtensions = ["mp3", "aac", "m4a", "wav"]
            if let serverURL = webUploader.serverURL {
                
                let str = serverURL.absoluteString
                let start = str.index(str.startIndex, offsetBy: 7)
                let end = str.index(str.endIndex, offsetBy: -1)
                let range = start..<end
                let mySubstring = str[range]
                ipAddress = String(mySubstring)
                print("Visit \(serverURL) in your web browser")
            } else {
                ipAddress = "No WiFi connected"
            }
        }
    }
    
    func stopWebUploader() {
        guard let webUploader = webUploader else {
            return
        }
        
        if webUploader.isRunning {
            webUploader.stop()
            ipAddress = ""
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

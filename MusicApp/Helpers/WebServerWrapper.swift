//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import Foundation
import GCDWebServer

class WebServerWrapper: NSObject {
    var ipAddress: String = ""
    private var webUploader: GCDWebUploader?
    
    override init() {
        super.init()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        webUploader = GCDWebUploader(uploadDirectory: documentsPath)
        webUploader?.delegate = self // Set the delegate
    }
    
    func startWebUploader() {
        webUploader?.start()
        webUploader?.allowedFileExtensions = ["mp3", "aac", "m4a", "wav"]
        if let serverURL = webUploader?.serverURL {
            
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
    
    func stopWebUploader() {
        webUploader?.stop()
        ipAddress = ""
    }
}

extension WebServerWrapper: GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        print("File uploaded at path: \(path)")
        
        // Perform any necessary processing with the uploaded file
        // ...
        
        // Check if the uploaded file has an MP3 extension
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
